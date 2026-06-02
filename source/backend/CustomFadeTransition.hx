package backend;

import flixel.util.FlxGradient;
import flixel.tweens.FlxTween;

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	var isTransIn:Bool = false;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;
	var baseZoom:Float = 1;
	var zoomTween:FlxTween;

	var duration:Float;
	public function new(duration:Float, isTransIn:Bool)
	{
		this.duration = duration;
		this.isTransIn = isTransIn;
		super();
	}

	override function create()
	{
		var cam = (FlxG.cameras.list.length > 0) ? FlxG.cameras.list[FlxG.cameras.list.length - 1] : FlxG.camera;
		if (cam != null)
		{
			cameras = [cam];
			baseZoom = cam.zoom;
		}
		else
		{
			super.create();
			return;
		}
		var width:Int = Std.int(FlxG.width / Math.max(camera.zoom, 0.001));
		var height:Int = Std.int(FlxG.height / Math.max(camera.zoom, 0.001));
		transGradient = FlxGradient.createGradientFlxSprite(1, height, (isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]));
		transGradient.scale.x = width;
		transGradient.updateHitbox();
		transGradient.scrollFactor.set();
		transGradient.screenCenter(X);
		add(transGradient);

		transBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		transBlack.scale.set(width, height + 400);
		transBlack.updateHitbox();
		transBlack.scrollFactor.set();
		transBlack.screenCenter(X);
		add(transBlack);

		if(isTransIn)
			transGradient.y = transBlack.y - transBlack.height;
		else
			transGradient.y = -transGradient.height;

		if(isTransIn)
		{
			camera.zoom = baseZoom * 2.5;
			zoomTween = FlxTween.tween(camera, {zoom: baseZoom}, duration, {type: FlxTween.ONESHOT});
		}
		else
		{
			camera.zoom = baseZoom;
			zoomTween = FlxTween.tween(camera, {zoom: baseZoom * 2.5}, duration, {type: FlxTween.ONESHOT});
		}

		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (camera == null || transGradient == null || transBlack == null)
		{
			close();
			if (finishCallback != null) finishCallback();
			finishCallback = null;
			return;
		}

		final height:Float = FlxG.height * Math.max(camera.zoom, 0.001);
		final targetPos:Float = transGradient.height + 50 * Math.max(camera.zoom, 0.001);
		if(duration > 0)
			transGradient.y += (height + targetPos) * elapsed / duration;
		else
			transGradient.y = (targetPos) * elapsed;

		if(isTransIn)
			transBlack.y = transGradient.y + transGradient.height;
		else
			transBlack.y = transGradient.y - transBlack.height;

		if(transGradient.y >= targetPos)
		{
			if(zoomTween != null) zoomTween.cancel();
			camera.zoom = baseZoom;
			close();
			if(finishCallback != null) finishCallback();
			finishCallback = null;
		}
	}
}