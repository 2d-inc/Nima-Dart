import "level.dart";
import "dart:ui" as ui;
import "nima_flutter.dart";
import "nima/animation/actor_animation.dart";
import "nima/actor_node.dart";
import "dart:math";
import "dart:typed_data";
import "dart:collection";
import "dart:core";
import "nima/math/vec2d.dart";
import "nima/math/mat2d.dart";

const double LevelWidth = 2435.0;
const double HalfLevelWidth = LevelWidth/2.0;

class Level_1 extends Level
{
	LevelActor _heroAsset;
	LevelImage _floorA;
	LevelImage _floorB;
	LevelImage _treesLeftA;
	LevelImage _treesLeftB;
	LevelImage _treesRightA;
	LevelImage _treesRightB;
	LevelImage _treeShadowA;
	LevelImage _treeShadowB;

	FlutterActor _heroActor;
	ActorAnimation _heroAnimation;
	ActorAnimation _jumpAnimation;
	double _heroAnimationTime = 0.0;
	double _jumpAnimationTime = 0.0;
	ActorNode _ikTarget;

	Vec2D _screenTouch;
	double _screenPressure = 0.0;
	bool _isJumping = false;

	Level_1()
	{
		registerAsset((_heroAsset = new LevelActor("Evolution")));
		registerAsset((_floorA = new LevelImage("Level_1/Level_1_0004s_0001_Floor_A.jpg")));
		registerAsset((_floorB = new LevelImage("Level_1/Level_1_0004s_0000_Floor_B.jpg")));
		registerAsset((_treesLeftA = new LevelImage("Level_1/Level_1_0000s_0002_Trees_Left_A.png")));
		registerAsset((_treesLeftB = new LevelImage("Level_1/Level_1_0000s_0003_Trees_Left_B.png")));
		registerAsset((_treesRightA = new LevelImage("Level_1/Level_1_0000s_0000_Trees_Right_A.png")));
		registerAsset((_treesRightB = new LevelImage("Level_1/Level_1_0000s_0001_Trees_Right_B.png")));
		registerAsset((_treeShadowA = new LevelImage("Level_1/Level_1_0001s_0001_Shadow_trees_A.png")));
		registerAsset((_treeShadowB = new LevelImage("Level_1/Level_1_0001s_0000_Shadow_Trees_B.png")));
	}

	void initialize()
	{
		// Place level objects.
		_heroActor = _heroAsset.actor; // In other cases we'll want to extend the actor to be instanceable so we can have multiple copies in different states. For now, this is sufficient.
		_heroAnimation = _heroActor.getAnimation("run");
		_jumpAnimation = _heroActor.getAnimation("jump");
		_ikTarget = _heroActor.getNode("ctrl_shoot");
	}
	
	void advance(double elapsedSeconds)
	{
		double cameraZoom = 0.8;//(sin(_heroAnimationTime)+2.0)*0.5;
		//_heroActor.root.y = 700.0;
		// Harcoding animation time as updating the nima file seemed to still use the previously cached one. Or I copied the wrong file with the old 10 seconds in it :)
		// double duration = 13.0/24.0;
		//elapsedSeconds *= 0.5;
		_heroAnimationTime += elapsedSeconds;

		
		// sync motion phase with walk
		//double phase = 35.0/60.0;
		//double speedModifier = 0.6+0.4*sin(_heroAnimationTime/phase*PI*2).abs();//0.6+1.0-min((dx.abs() - 300.0)/1000.0, 1.0);
		double speedModifier = 1.0;


		double dx = _ikTarget.worldTransform[4] - _heroActor.root.x;
		_heroActor.root.x += dx * elapsedSeconds * speedModifier;
		if(_heroActor.root.x > HalfLevelWidth)
		{
			_heroActor.root.x = HalfLevelWidth;
		}
		else if(_heroActor.root.x < -HalfLevelWidth)
		{
			_heroActor.root.x = -HalfLevelWidth;
		}


		_heroActor.root.y -= elapsedSeconds*700.0*speedModifier;//*speedModifier;
	
		
		Vec2D cameraPosition = cameraTranslation;		
		Vec2D.copy(cameraPosition, _heroActor.root.translation);
		cameraPosition[1] -= viewportHeight/3.0 / cameraZoom;
		const double MaxX = 440.0;
		if(cameraPosition[0] > MaxX)
		{
			cameraPosition[0] = MaxX;
		}
		if(cameraPosition[0] < -MaxX)
		{
			cameraPosition[0] = -MaxX;
		}
		setCamera(cameraPosition, cameraZoom);

		if(_screenPressure > 2.0 && !_isJumping)
		{
			_jumpAnimationTime = 0.0;
			_isJumping = true;
		}
		if(_isJumping)
		{
			_jumpAnimation.apply(_jumpAnimationTime, _heroActor, 1.0);
			_jumpAnimationTime += elapsedSeconds;
			if(_jumpAnimationTime >= _jumpAnimation.duration)
			{
				_isJumping = false;
				_heroAnimationTime = 0.0;
			}
		}
		else
		{
			double duration = _heroAnimation.duration;
			_heroAnimation.apply(_heroAnimationTime%duration, _heroActor, 1.0);
		}

		Mat2D inverseTargetWorld = new Mat2D();
		if(_screenTouch != null && Mat2D.invert(inverseTargetWorld, _ikTarget.parent.worldTransform))
		{
			Vec2D screenCoord = new Vec2D.fromValues(_screenTouch[0], (viewportHeight - _screenTouch[1]));
			_screenTouch = null;
			//Vec2D worldTouch = new Vec2D.fromValues(_screenTouch[0] * scale + paintBounds.width / 2.0, _screenTouch[1] * -scale + paintBounds.height / 2.0);
			Vec2D worldTouch = new Vec2D.fromValues((screenCoord[0] - viewportWidth / 2.0) / cameraZoom + cameraPosition[0], (screenCoord[1] - viewportHeight / 2.0) / cameraZoom + cameraPosition[1]);
			//Vec2D worldTouch = Vec2D.transformMat2D(new Vec2D(), _screenTouch, inverseViewTransform);
			Vec2D localPos = Vec2D.transformMat2D(new Vec2D(), worldTouch, inverseTargetWorld);
			//_ikTarget.translation = localPos;
			// _ikTarget.x = localPos[0];
			// _ikTarget.y = localPos[1];
			//print(localPos[0].toString() + " " + localPos[1].toString() + " | " + worldTouch[0].toString() + " " + worldTouch[1].toString());
			//targetPosition = localPos;
			_ikTarget.x = localPos[0];//lerp(_ikTarget.x, targetPosition[0], min(1.0, elapsed*delta));
			_ikTarget.y = localPos[1];//lerp(_ikTarget.y, targetPosition[1], min(1.0, elapsed*delta));
		}
		//print("ELAPSED $elapsedSeconds");
		_heroActor.advance(elapsedSeconds);
	}
	
	void renderScene(ui.Canvas canvas)
	{
		canvas.save();

		int idx = (_heroActor.root.y / LevelWidth).ceil();
		canvas.translate(-HalfLevelWidth, (idx*LevelWidth).ceilToDouble());
		for(int i = 0; i < 4; i++)
		{
			canvas.drawRect(new ui.Rect.fromLTWH(0.0, 0.0, LevelWidth, LevelWidth), (idx+i)%2 == 0 ? _floorA.paint : _floorB.paint);
			canvas.translate(0.0, -LevelWidth+2);
		}

		canvas.restore();
		_heroActor.draw(canvas);

		// Left Shadows
		{
			canvas.save();
			const double shadowWidth = 774.0;
			canvas.translate(-HalfLevelWidth+shadowWidth-400, (idx*LevelWidth).ceilToDouble());
			canvas.scale(-1.0, 1.0);
			for(int i = 0; i < 4; i++)
			{
				ui.Paint p = (idx+i)%2 == 0 ? _treeShadowA.paint : _treeShadowB.paint;
				//p.color = new ui.Color.fromARGB(100, 255, 255, 255);
				canvas.drawRect(new ui.Rect.fromLTWH(0.0, 0.0, shadowWidth, LevelWidth), (idx+i)%2 == 0 ? _treeShadowA.paint : _treeShadowB.paint);
				canvas.translate(0.0, -LevelWidth);
			}

			canvas.restore();
		}

		// Right Shadows
		{
			canvas.save();
			const double shadowWidth = 774.0;
			canvas.translate(HalfLevelWidth-shadowWidth, (idx*LevelWidth).ceilToDouble());
			for(int i = 0; i < 4; i++)
			{
				ui.Paint p = (idx+i)%2 == 0 ? _treeShadowA.paint : _treeShadowB.paint;
				//p.color = new ui.Color.fromARGB(255, 255, 255, 255);

				canvas.drawRect(new ui.Rect.fromLTWH(0.0, 0.0, shadowWidth, LevelWidth), p);
				canvas.translate(0.0, -LevelWidth);
			}

			canvas.restore();
		}

		// Left leaves
		{
			const double LeafWidth = 334.0;
			canvas.save();
			Vec2D camT = cameraTranslation;
			const double leafScale = 1.1;
			const double LeafSize = LevelWidth/leafScale;
			idx = (_heroActor.root.y / LeafSize).ceil();
			double remainder = _heroActor.root.y % LeafSize;
			canvas.translate(-HalfLevelWidth, LevelWidth-remainder*leafScale+camT[1]);//(_heroActor.root.y % LevelWidth)*-0.2);

			for(int i = 0; i < 4; i++)
			{
				canvas.drawRect(new ui.Rect.fromLTWH(0.0, 0.0, LeafWidth, LevelWidth), (idx+i)%2 == 0 ? _treesLeftA.paint : _treesLeftB.paint);
				canvas.translate(0.0, -LevelWidth+2);
			}

			canvas.restore();
		}

		// Right leaves
		{
			const double LeafWidth = 419.0;
			canvas.save();
			Vec2D camT = cameraTranslation;
			const double leafScale = 1.1;
			const double LeafSize = LevelWidth/leafScale;
			idx = (_heroActor.root.y / LeafSize).ceil();
			double remainder = _heroActor.root.y % LeafSize;
			canvas.translate(HalfLevelWidth-LeafWidth, LevelWidth-remainder*leafScale+camT[1]);//(_heroActor.root.y % LevelWidth)*-0.2);

			for(int i = 0; i < 4; i++)
			{
				canvas.drawRect(new ui.Rect.fromLTWH(0.0, 0.0, LeafWidth, LevelWidth), (idx+i)%2 == 0 ? _treesRightA.paint : _treesRightB.paint);
				canvas.translate(0.0, -LevelWidth+2);
			}

			canvas.restore();
		}


	}

	void onPointerData(List<ui.PointerData> data)
	{
		if(data.length > 0)
		{
			_screenTouch = new Vec2D.fromValues(data[0].physicalX, data[0].physicalY);
			_screenPressure = data[0].pressure;
		}
	}
}