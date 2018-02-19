import "nima_flutter.dart";
import "nima/animation/actor_animation.dart";
import "nima/actor_node.dart";
import "dart:ui" as ui;
import "dart:typed_data";
import "dart:math";
import "nima/math/vec2d.dart";
import "nima/math/mat2d.dart";

FlutterActor actor;
ActorAnimation animation;

double lastFrameTime = 0.0;
Vec2D screenTouch = null;
void pointerData(ui.PointerDataPacket pointerDataPacket)
{
	if(pointerDataPacket.data.length > 0)
	{
		ui.PointerData data = pointerDataPacket.data[0];
		
		screenTouch = new Vec2D.fromValues(data.physicalX, data.physicalY);
	}
}
void beginFrame(Duration timeStamp) 
{
	final double t = timeStamp.inMicroseconds / Duration.MICROSECONDS_PER_MILLISECOND / 1000.0;
	double elapsed = t - lastFrameTime;
	lastFrameTime = t;
	if(lastFrameTime == 0)
	{
		// hack to circumvent not being enable to initialize lastFrameTime to a starting timeStamp (maybe it's just the date?)
		// Is the FrameCallback supposed to pass elapsed time since last frame? timeStamp seems to behave more like a date
		ui.window.scheduleFrame();
		return;
	}
	
	ActorNode ikTarget = actor.getNode("ctrl_shoot");
	/*if(ikTarget != null)
	{
		ikTarget.x = sin(t)*100.0;
	}*/
	double scale = 1.0;
	double pixelRatio = 1.0;//
	final ui.Rect paintBounds = ui.Offset.zero & (ui.window.physicalSize / pixelRatio);

	Mat2D viewTransform = new Mat2D();
	viewTransform[0] = scale;
	viewTransform[1] = 0.0;
	viewTransform[2] = 0.0;
	viewTransform[3] = scale;
	viewTransform[4] = paintBounds.width / 2.0;
	viewTransform[5] = paintBounds.height / 2.0;
	Mat2D inverseViewTransform = new Mat2D();
	if(Mat2D.invert(inverseViewTransform, viewTransform))
	{
		Mat2D inverseTargetWorld = new Mat2D();
		if(screenTouch != null && Mat2D.invert(inverseTargetWorld, ikTarget.parent.worldTransform))
		{
			Vec2D screenCoord = new Vec2D.fromValues(screenTouch[0]/pixelRatio, (ui.window.physicalSize.height - screenTouch[1])/pixelRatio);
			//Vec2D worldTouch = new Vec2D.fromValues(screenTouch[0] * scale + paintBounds.width / 2.0, screenTouch[1] * -scale + paintBounds.height / 2.0);
			Vec2D worldTouch = new Vec2D.fromValues((screenCoord[0] - paintBounds.width / 2.0) / scale, (screenCoord[1] - paintBounds.height / 2.0) / scale);
			//Vec2D worldTouch = Vec2D.transformMat2D(new Vec2D(), screenTouch, inverseViewTransform);
			Vec2D localPos = Vec2D.transformMat2D(new Vec2D(), worldTouch, inverseTargetWorld);
			//ikTarget.translation = localPos;
			ikTarget.x = localPos[0];
			ikTarget.y = localPos[1];
			//print(localPos[0].toString() + " " + localPos[1].toString() + " | " + worldTouch[0].toString() + " " + worldTouch[1].toString());
		}
	}
	
	actor.root.y = 700.0;
	actor.advance(elapsed);

	// Harcoding animation time as updating the nima file seemed to still use the previously cached one. Or I copied the wrong file with the old 10 seconds in it :)
	// double duration = 13.0/24.0;
	double duration = animation.duration;
	animation.apply(t%duration/*animation.duration*/, actor, 1.0);

	
	final ui.PictureRecorder recorder = new ui.PictureRecorder();
	final ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);

	// "clearing" the screen with a background color
	canvas.drawRect(new ui.Rect.fromLTRB(0.0, 0.0, ui.window.physicalSize.width, ui.window.physicalSize.height),
					new ui.Paint()..color = new ui.Color.fromARGB(255, 125, 152, 165));
					
	canvas.translate(paintBounds.width / 2.0, paintBounds.height / 2.0);

	// Nima coordinates are:
	//         1
	//         |
	//         |
	// -1 ------------ 1
	//         |
	//         |
	//        -1
	canvas.scale(scale, -scale);

	actor.draw(canvas);

	final ui.Picture picture = recorder.endRecording();

	// COMPOSITE

	final double devicePixelRatio = pixelRatio;
	final Float64List deviceTransform = new Float64List(16)
		..[0] = devicePixelRatio
		..[5] = devicePixelRatio
		..[10] = 1.0
		..[15] = 1.0;
		
	final ui.SceneBuilder sceneBuilder = new ui.SceneBuilder()
		..pushTransform(deviceTransform)
		..addPicture(ui.Offset.zero, picture)
		..pop();
	ui.window.render(sceneBuilder.build());

	// After rendering the current frame of the animation, we ask the engine to
	// schedule another frame. The engine will call beginFrame again when its time
	// to produce the next frame.
	ui.window.scheduleFrame();
}

void main() 
{
	actor = new FlutterActor();
	actor.loadFromBundle("assets/Evolution").then(
		(bool success)
		{
			// animation = actor.getAnimation("Run");
			animation = actor.getAnimation("shoot");
			ui.window.onBeginFrame = beginFrame;
			ui.window.scheduleFrame();
			ui.window.onPointerDataPacket = pointerData;
		}
	);
}