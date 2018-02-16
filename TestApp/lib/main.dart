import "nima_flutter.dart";
import "nima/animation/actor_animation.dart";
import "dart:ui" as ui;
import "dart:typed_data";

FlutterActor actor;
ActorAnimation animation;

double lastFrameTime = 0.0;

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
	
	actor.advance(elapsed);

	// Harcoding animation time as updating the nima file seemed to still use the previously cached one. Or I copied the wrong file with the old 10 seconds in it :)
	// double duration = 13.0/24.0;
	double duration = animation.duration;
	animation.apply(t%duration/*animation.duration*/, actor, 1.0);

	final ui.Rect paintBounds = ui.Offset.zero & (ui.window.physicalSize / ui.window.devicePixelRatio);
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
	canvas.scale(0.25, -0.25);

	actor.draw(canvas);

	final ui.Picture picture = recorder.endRecording();

	// COMPOSITE

	final double devicePixelRatio = ui.window.devicePixelRatio;
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
	actor.loadFromBundle("assets/sequence").then(
		(bool success)
		{
			// animation = actor.getAnimation("Run");
			animation = actor.getAnimation("Sequence");
			ui.window.onBeginFrame = beginFrame;
			ui.window.scheduleFrame();
		}
	);
}