import "package:flutter/services.dart" show rootBundle;
import "nima/actor.dart";
import "nima/actor_image.dart";
import "dart:async";
import "dart:typed_data";
import "dart:ui" as ui;

class FlutterActorImage extends ActorImage
{
	Float32List _vertexBuffer;
	Float32List _uvBuffer;
	ui.Paint _paint;
	ui.Vertices _canvasVertices;
	Int32List _indices;

	void init()
	{
		if(triangles == null)
		{
			return;
		}
		_vertexBuffer = makeVertexPositionBuffer();
		_uvBuffer = makeVertexUVBuffer();
		_indices = new Int32List.fromList(triangles); // nima runtime loads 16 bit indices
		// TODO: this will need to call again when image sequences are supported in the dart nima runtime.
		updateVertexUVBuffer(_uvBuffer);
		int count = vertexCount;
		int idx = 0;
		ui.Image image = (actor as FlutterActor).images[textureIndex];
		
		// SKIA requires texture coordinates in full image space, not traditional normalized uv coordinates.
		for(int i = 0; i < count; i++)
		{
			_uvBuffer[idx] = _uvBuffer[idx]*image.width;
			_uvBuffer[idx+1] = _uvBuffer[idx+1]*image.height;
			idx += 2;
		}
		final Float64List identityMatrix = new Float64List.fromList(<double>[
			1.0, 0.0, 0.0, 0.0,
			0.0, 1.0, 0.0, 0.0,
			0.0, 0.0, 1.0, 0.0,
			0.0, 0.0, 0.0, 1.0
		]);

		_paint = new ui.Paint()..shader = new ui.ImageShader((actor as FlutterActor).images[textureIndex], ui.TileMode.clamp, ui.TileMode.clamp, identityMatrix);
		_paint.isAntiAlias = true;

	}

	void updateVertices()
	{
		if(triangles == null)
		{
			return;
		}
		updateVertexPositionBuffer(_vertexBuffer, true);
		

		//Float32List test = new Float32List.fromList([64.0, 32.0, 0.0, 224.0, 128.0, 224.0]);
		//Int32List colorTest = new Int32List.fromList([const ui.Color.fromARGB(255, 0, 255, 0).value, const ui.Color.fromARGB(255, 0, 255, 0).value, const ui.Color.fromARGB(255, 0, 255, 0).value]);
		//_canvasVertices = new ui.Vertices.raw(ui.VertexMode.triangles, test, colors:colorTest /*textureCoordinates: _uvBuffer, indices: _indices*/);
		_canvasVertices = new ui.Vertices.raw(ui.VertexMode.triangles, _vertexBuffer, indices: _indices, textureCoordinates: _uvBuffer);
		
	}

	draw(ui.Canvas canvas)
	{
		if(triangles == null)
		{
			return;
		}
		canvas.drawVertices(_canvasVertices, ui.BlendMode.srcOver, _paint);
	}
}

class FlutterActor extends Actor
{
	List<ui.Image> _images;

	List<ui.Image> get images
	{
		return _images;
	}

	ActorImage makeImageNode()
	{
		return new FlutterActorImage();
	}

	Future<bool> loadFromBundle(String filename) async
	{
		print("Loading actor filename $filename");
		ByteData data = await rootBundle.load(filename + ".nima");
		super.load(data);

		List<Future<ui.Codec>> waitList = new List<Future<ui.Codec>>();
		_images = new List<ui.Image>(texturesUsed);

		for(int i = 0; i < texturesUsed; i++)
		{
			String atlasFilename;
			if(texturesUsed == 1)
			{
				atlasFilename = filename + ".png";
			}
			else
			{
				atlasFilename = filename + i.toString() + ".png";
			}
			ByteData data = await rootBundle.load(atlasFilename);
			Uint8List list = new Uint8List.view(data.buffer);
			waitList.add(ui.instantiateImageCodec(list));
		}

		List<ui.Codec> codecs = await Future.wait(waitList);
		List<ui.FrameInfo> frames = await Future.wait(codecs.map((codec) => codec.getNextFrame()));
		for(int i = 0; i < frames.length; i++)
		{
			_images[i] = frames[i].image;
		}

		for(FlutterActorImage image in imageNodes)
		{
			image.init();
		}

		return true;
	}

	void advance(double seconds)
	{
		super.advance(seconds);

		// TODO: update vertex buffers only when an image update occurred. or use GL :)
		for(FlutterActorImage image in imageNodes)
		{
			image.updateVertices();
		}
	}

	draw(ui.Canvas canvas)
	{
		// N.B. imageNodes are sorted as necessary by Actor.
		for(FlutterActorImage image in imageNodes)
		{
			image.draw(canvas);
		}
	}
}
