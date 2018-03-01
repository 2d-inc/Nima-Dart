import "nima_flutter.dart";
import "nima/animation/actor_animation.dart";
import "nima/actor_node.dart";
import "dart:ui" as ui;
import "dart:typed_data";
import "dart:math";
import "nima/math/vec2d.dart";
import "nima/math/mat2d.dart";
import "level.dart";
import "level_1.dart";

Level currentLevel;
FlutterActor actor;
ActorAnimation animation;

double lastFrameTime = 0.0;
Vec2D screenTouch = null;
Vec2D initialPosition = null;
Vec2D targetPosition = null;
ActorNode ikTarget = null;
double interpolationMu = 0.0;
double epsilon = 5.0; 
double delta = 2.5;
var interpolator = null;

double lerp(double a, double b, double mu)
{
	return (1-mu)*a + mu*b;
}
double cosine(double a, double b, double mu)
{
	// double mu2;
	// mu2 = (1-cos(mu*PI))/2;
	// double ret = a*(1-mu2) + b*mu2;
	double ret = lerp(a, b, (1-cos(mu*PI))/2);
	return ret;
}

double acceleration(double a, double b, double mu)
{
	double ret = lerp(a,b,pow(mu,2));
	return ret;
}

double deceleration(double a, double b, double mu)
{
	double ret = lerp(a, b, 1-pow(1-mu, 2));
	return ret;
}

double smoothStep(double a, double b, double mu)
{
	double ret = lerp(a,b,pow(mu, 2)*(3-2*mu));
	return ret;
}

void pointerData(ui.PointerDataPacket pointerDataPacket)
{
	if(pointerDataPacket.data.length > 0)
	{
		// ui.PointerData data = pointerDataPacket.data[0];
		// initialPosition = new Vec2D.fromValues(ikTarget.x, ikTarget.y);
		// screenTouch = new Vec2D.fromValues(data.physicalX, data.physicalY);
		currentLevel.onPointerData(pointerDataPacket.data);
	}
}
void beginFrame(Duration timeStamp) 
{
	final double t = timeStamp.inMicroseconds / Duration.MICROSECONDS_PER_MILLISECOND / 1000.0;
	double elapsed = t - lastFrameTime;
	
	if(lastFrameTime == 0)
	{
		
		// hack to circumvent not being enable to initialize lastFrameTime to a starting timeStamp (maybe it's just the date?)
		// Is the FrameCallback supposed to pass elapsed time since last frame? timeStamp seems to behave more like a date
		ui.window.scheduleFrame();
		lastFrameTime = t;
		return;
	}
	lastFrameTime = t;
	/*
	ikTarget = actor.getNode("ctrl_shoot");
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
		if(targetPosition != null && (targetPosition[0] - ikTarget.x).abs() < epsilon && (targetPosition[1] - ikTarget.y).abs() < epsilon)
		{
			targetPosition = null; // Reached the target
		}
		else if(targetPosition != null)
		{
			print("INTERPOLATING ${interpolator}");
			ikTarget.x = interpolator(ikTarget.x, targetPosition[0], min(1.0, elapsed*delta));
			ikTarget.y = interpolator(ikTarget.y, targetPosition[1], min(1.0, elapsed*delta));
		}

		if(screenTouch != null && Mat2D.invert(inverseTargetWorld, ikTarget.parent.worldTransform))
		{
			Vec2D screenCoord = new Vec2D.fromValues(screenTouch[0]/pixelRatio, (ui.window.physicalSize.height - screenTouch[1])/pixelRatio);
			screenTouch = null;
			//Vec2D worldTouch = new Vec2D.fromValues(screenTouch[0] * scale + paintBounds.width / 2.0, screenTouch[1] * -scale + paintBounds.height / 2.0);
			Vec2D worldTouch = new Vec2D.fromValues((screenCoord[0] - paintBounds.width / 2.0) / scale, (screenCoord[1] - paintBounds.height / 2.0) / scale);
			//Vec2D worldTouch = Vec2D.transformMat2D(new Vec2D(), screenTouch, inverseViewTransform);
			Vec2D localPos = Vec2D.transformMat2D(new Vec2D(), worldTouch, inverseTargetWorld);
			//ikTarget.translation = localPos;
			// ikTarget.x = localPos[0];
			// ikTarget.y = localPos[1];
			//print(localPos[0].toString() + " " + localPos[1].toString() + " | " + worldTouch[0].toString() + " " + worldTouch[1].toString());
			targetPosition = localPos;
			ikTarget.x = lerp(ikTarget.x, targetPosition[0], min(1.0, elapsed*delta));
			ikTarget.y = lerp(ikTarget.y, targetPosition[1], min(1.0, elapsed*delta));
		}
	}
	
	actor.root.y = 700.0;
	actor.advance(elapsed);

	// Harcoding animation time as updating the nima file seemed to still use the previously cached one. Or I copied the wrong file with the old 10 seconds in it :)
	// double duration = 13.0/24.0;
	double duration = animation.duration;
	animation.apply(t%duration, actor, 1.0);
	*/
	
	double pixelRatio = 1.0;
	final ui.Rect paintBounds = ui.Offset.zero & (ui.window.physicalSize / pixelRatio);
	currentLevel.setSize(paintBounds.width, paintBounds.height);
	
	final ui.PictureRecorder recorder = new ui.PictureRecorder();
	final ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);


	currentLevel.advance(elapsed);
	currentLevel.render(canvas);
/*
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

	actor.draw(canvas);*/

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
	currentLevel = new Level_1();
	print("loading...");
	currentLevel.loadFromBundle().then(
		(bool success)
		{
			if(!success)
			{
				print("Failed to load level, we die.");
				return;
			}
			print("initializing...");
			currentLevel.initialize();

			// animation = actor.getAnimation("Run");
			// animation = actor.getAnimation("shoot");
			ui.window.onBeginFrame = beginFrame;
			ui.window.scheduleFrame();
			ui.window.onPointerDataPacket = pointerData;
		}
	);
	/*
	interpolator = deceleration;
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
	);*/
}