import "dart:async";
import "dart:typed_data";
import "nima_flutter.dart";
import "dart:ui" as ui;
//import "dart:collection";
import "package:flutter/services.dart" show rootBundle;
import "nima/math/mat2d.dart";
import "nima/math/vec2d.dart";

abstract class LevelAsset
{
	String _filename;

	LevelAsset(String filename)
	{
		_filename = "assets/" + filename;
	}

	String get filename
	{
		return _filename;
	}
}

class LevelImage extends LevelAsset
{
	ui.Image image;
	ui.Paint paint;

	LevelImage(String filename) : super(filename);
}

 class LevelActor extends LevelAsset
{
	FlutterActor actor;

	LevelActor(String filename) : super(filename);
}

abstract class Level
{
	Mat2D _viewTransform = new Mat2D();
	Mat2D _inverseViewTransform = new Mat2D();
	double _viewportWidth;
	double _viewportHeight;
	Vec2D _cameraTranslation = new Vec2D();

	Float64List _viewTransform4 = new Float64List.fromList(<double>[
			1.0, 0.0, 0.0, 0.0,
			0.0, 1.0, 0.0, 0.0,
			0.0, 0.0, 1.0, 0.0,
			0.0, 0.0, 0.0, 1.0
		]);
	double _cameraZoom = 1.0;

	void setCamera(Vec2D translation, scale)
	{
		_viewTransform[0] = scale;
		_viewTransform[1] = 0.0;
		_viewTransform[2] = 0.0;
		_viewTransform[3] = -scale;
		_viewTransform[4] = -translation[0]*scale + _viewportWidth/2;
		_viewTransform[5] = -translation[1]*-scale + _viewportHeight/2;

		_viewTransform4[0] = _viewTransform[0];
		_viewTransform4[5] = _viewTransform[3];

		_viewTransform4[12] = _viewTransform[4];
		_viewTransform4[13] = _viewTransform[5];

		Vec2D.copy(_cameraTranslation, translation);
		_cameraZoom = scale;

		Mat2D.invert(_inverseViewTransform, _viewTransform);
	}

	Vec2D get cameraTranslation
	{
		return new Vec2D.clone(_cameraTranslation);
	}

	double get cameraZoom
	{
		return _cameraZoom;
	}

	setSize(double width, double height)
	{
		if(_viewportWidth != width || _viewportHeight != height)
		{
			_viewportWidth = width;
			_viewportHeight = height;
			return true;
		}
		return false;
	}

	double get viewportHeight
	{
		return _viewportHeight;
	}

	double get viewportWidth
	{
		return _viewportWidth;
	}

	// HashMap<String, LevelAsset> _assets = new HashMap<String, LevelAsset>();
	// Super bummed this doesn't work!!
	// void registerAsset<T extends LevelAsset>(String id, String filename)
	// {
	// 	_assets[id] = new T(filename);
	// }

	List<LevelAsset> _assets = new List<LevelAsset>();

	void registerAsset(LevelAsset asset)
	{
		_assets.add(asset);
	}

	Future<bool> loadFromBundle() async
	{
		List<Future<ui.Codec>> imageWaitList = new List<Future<ui.Codec>>();
		List<LevelImage> images = new List<LevelImage>();

		List<Future<bool>> actorWaitList = new List<Future<bool>>();
		List<LevelActor> actors = new List<LevelActor>();

		for(LevelAsset asset in _assets)
		{
			if(asset is LevelImage)
			{
				images.add(asset);
				ByteData data = await rootBundle.load(asset.filename);
				Uint8List list = new Uint8List.view(data.buffer);
				imageWaitList.add(ui.instantiateImageCodec(list));
			}
			else if(asset is LevelActor)
			{
				actors.add(asset);
				asset.actor = new FlutterActor();
				actorWaitList.add(asset.actor.loadFromBundle(asset.filename));
			}
		}

		// Load the images.
		List<ui.Codec> codecs = await Future.wait(imageWaitList);
		List<ui.FrameInfo> frames = await Future.wait(codecs.map((codec) => codec.getNextFrame()));

		final Float64List _identityMatrix = new Float64List.fromList(<double>[
				1.0, 0.0, 0.0, 0.0,
				0.0, 1.0, 0.0, 0.0,
				0.0, 0.0, 1.0, 0.0,
				0.0, 0.0, 0.0, 1.0
			]);

		for(int i = 0; i < frames.length; i++)
		{
			LevelImage imageAsset = images[i];
			imageAsset.image = frames[i].image;
			imageAsset.paint = new ui.Paint()..shader = new ui.ImageShader(imageAsset.image, ui.TileMode.clamp, ui.TileMode.clamp, _identityMatrix);
			//imageAsset.paint.isAntiAlias = true;
		}

		// Load the actors.
		List<bool> actorResults = await Future.wait(actorWaitList);
		if(actorResults.contains(false))
		{
			return false;
		}
		
		return true;
	}

	void initialize();
	void render(ui.Canvas canvas)
	{
		canvas.drawRect(new ui.Rect.fromLTRB(0.0, 0.0, _viewportWidth, _viewportHeight), new ui.Paint()..color = new ui.Color.fromARGB(0, 0, 0, 255));
		canvas.save();
		canvas.transform(_viewTransform4);
		renderScene(canvas);
		canvas.restore();
	}

	void renderScene(ui.Canvas canvas)
	{

	}

	void advance(double elapsedSeconds);

	void onPointerData(List<ui.PointerData> data);

}