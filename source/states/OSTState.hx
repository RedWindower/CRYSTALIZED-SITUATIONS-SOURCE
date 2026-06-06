package states;

import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import objects.Alphabet;
import openfl.utils.AssetType;

#if sys
import sys.FileSystem;
#end

typedef OSTTrack = {
	var name:String;
	var isSong:Bool;
	var color:Int;
}

class OSTState extends MusicBeatState
{
	static inline var BASE_ASSET:String = 'ostassets/base';
	static inline var CD_ASSET:String = 'ostassets/cd';
	static inline var LEFT_ARROW_ASSET:String = 'ostassets/arrow_left';
	static inline var RIGHT_ARROW_ASSET:String = 'ostassets/arrow_right';
	static inline var DEFAULT_BG_COLOR:Int = 0xFF3B314B;
	static inline var ARROW_PRESS_OFFSET:Float = 24;
	static inline var CD_SPIN_SPEED:Float = 180;

	var tracks:Array<OSTTrack> = [];
	var curSelected:Int = 0;
	var bg:FlxSprite;
	var titleText:FlxText;
	var nowPlayingText:FlxText;
	var helpText:FlxText;
	var indexText:FlxText;
	var baseRect:FlxSprite;
	var cdSprite:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	var songNameText:Alphabet;
	var previewTimer:FlxTimer;
	var colorTween:FlxTween;
	var leftArrowTween:FlxTween;
	var leftArrowScaleTween:FlxTween;
	var rightArrowTween:FlxTween;
	var rightArrowScaleTween:FlxTween;
	var leftArrowBaseX:Float = 0;
	var rightArrowBaseX:Float = 0;
	var previewDuration:Float = 6;
	var isPlayingFull:Bool = false;
	var isPaused:Bool = false;
	var loopEnabled:Bool = true;

	override function create()
	{
		FlxG.mouse.visible = true;

		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = DEFAULT_BG_COLOR;
		add(bg);

		titleText = new FlxText(0, 16, FlxG.width, 'OST', 32);
		titleText.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.scrollFactor.set();
		add(titleText);

		nowPlayingText = new FlxText(0, 58, FlxG.width, 'Now Playing: -', 16);
		nowPlayingText.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		nowPlayingText.scrollFactor.set();
		add(nowPlayingText);

		buildTrackList();
		createLayout();

		indexText = new FlxText(0, baseRect.y + baseRect.height + 26, FlxG.width, '', 16);
		indexText.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		indexText.scrollFactor.set();
		add(indexText);

		helpText = new FlxText(0, FlxG.height - 24, FlxG.width, '', 16);
		helpText.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		helpText.scrollFactor.set();
		add(helpText);

		updateSelection();
		updateNowPlaying();
		updateHelpText();
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.UI_LEFT_P)
		{
			animateArrowPress(true);
			changeSelection(-1, true);
		}
		if (controls.UI_RIGHT_P)
		{
			animateArrowPress(false);
			changeSelection(1, true);
		}
		if (controls.ACCEPT)
			togglePlayPause();
		if (FlxG.keys.justPressed.L)
			toggleLoop();

		if (cdSprite != null)
		{
			if (isMusicActive())
				cdSprite.angle += elapsed * CD_SPIN_SPEED;
			else
				cdSprite.angle = FlxMath.lerp(cdSprite.angle, 0, Math.min(elapsed * 8, 1));
		}

		if (controls.BACK)
		{
			stopPlayback();
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	function buildTrackList():Void
	{
		tracks = [];

		#if sys
		var musicDir = Paths.getSharedPath('music');
		if (FileSystem.exists(musicDir))
		{
			for (file in FileSystem.readDirectory(musicDir))
			{
				if (StringTools.endsWith(file, '.ogg') || StringTools.endsWith(file, '.mp3'))
				{
					var trackName:String = file.substr(0, file.length - 4);
					tracks.push({name: trackName, isSong: false, color: getTrackColor(trackName)});
				}
			}
		}

		var songsDir = 'assets/songs';
		if (FileSystem.exists(songsDir))
		{
			for (entry in FileSystem.readDirectory(songsDir))
			{
				var path = songsDir + '/' + entry;
				if (FileSystem.isDirectory(path))
				{
					tracks.push({name: entry, isSong: true, color: getTrackColor(entry)});
				}
			}
		}
		#end

		tracks.sort(function(a:OSTTrack, b:OSTTrack)
		{
			if (a.isSong != b.isSong) return a.isSong ? 1 : -1;
			return Reflect.compare(a.name, b.name);
		});
	}

	function changeSelection(change:Int, playPreview:Bool):Void
	{
		if (tracks.length == 0) return;
		curSelected += change;
		if (curSelected < 0) curSelected = tracks.length - 1;
		if (curSelected >= tracks.length) curSelected = 0;
		updateSelection();
		FlxG.sound.play(Paths.sound('scrollMenu'));
		if (playPreview)
			startPreview();
	}

	function updateSelection():Void
	{
		if (tracks.length <= 0)
		{
			if (songNameText != null)
			{
				songNameText.text = 'NO TRACKS';
				repositionSongName();
			}
			if (indexText != null)
				indexText.text = '';
			return;
		}

		var track = tracks[curSelected];
		if (songNameText != null)
		{
			songNameText.text = track.name.toUpperCase();
			repositionSongName();
		}
		if (indexText != null)
			indexText.text = (track.isSong ? 'SONG' : 'MUSIC') + '  ' + (curSelected + 1) + ' / ' + tracks.length;
		updateBackgroundColor(track.color);
	}

	function togglePlayPause():Void
	{
		if (tracks.length == 0) return;
		if (isPlayingFull)
		{
			if (FlxG.sound.music != null)
			{
				if (isPaused)
				{
					FlxG.sound.music.resume();
					isPaused = false;
				}
				else
				{
					FlxG.sound.music.pause();
					isPaused = true;
				}
			}
			updateNowPlaying();
			return;
		}

		playFull(tracks[curSelected]);
	}

	function playFull(track:OSTTrack):Void
	{
		clearPreview();
		isPlayingFull = true;
		isPaused = false;

		if (track.isSong)
			FlxG.sound.playMusic(Paths.inst(track.name), 1, loopEnabled);
		else
			FlxG.sound.playMusic(Paths.music(track.name), 1, loopEnabled);

		FlxG.sound.play(Paths.sound('confirmMenu'));
		updateNowPlaying();
	}

	function startPreview():Void
	{
		if (tracks.length == 0) return;
		clearPreview();
		if (isPlayingFull)
		{
			stopPlayback();
		}

		var track = tracks[curSelected];
		if (track.isSong)
			FlxG.sound.playMusic(Paths.inst(track.name), 0.7, false);
		else
			FlxG.sound.playMusic(Paths.music(track.name), 0.7, false);

		nowPlayingText.text = 'Preview: ' + track.name.toUpperCase();
		updateBackgroundColor(track.color);
		previewTimer = new FlxTimer().start(previewDuration, function(_)
		{
			if (!isPlayingFull)
				stopPlayback();
		});
	}

	function stopPlayback():Void
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
		clearPreview();
		isPlayingFull = false;
		isPaused = false;
		updateBackgroundColor((tracks.length > 0) ? tracks[curSelected].color : DEFAULT_BG_COLOR);
		updateNowPlaying();
	}

	function clearPreview():Void
	{
		if (previewTimer != null)
		{
			previewTimer.cancel();
			previewTimer.destroy();
			previewTimer = null;
		}
	}

	function toggleLoop():Void
	{
		loopEnabled = !loopEnabled;
		updateHelpText();
		if (isPlayingFull && FlxG.sound.music != null)
			FlxG.sound.music.looped = loopEnabled;
	}

	function updateNowPlaying():Void
	{
		if (tracks.length == 0)
		{
			nowPlayingText.text = 'Now Playing: -';
			return;
		}

		var track = tracks[curSelected];
		var status = isMusicActive() ? (isPlayingFull ? 'Now Playing: ' : 'Preview: ') : (isPaused ? 'Paused: ' : 'Selected: ');
		if (isPaused)
			status = 'Paused: ';
		nowPlayingText.text = status + track.name.toUpperCase();
	}

	function updateHelpText():Void
	{
		var loopLabel = loopEnabled ? 'ON' : 'OFF';
		helpText.text = 'LEFT/RIGHT: Change Track  |  ENTER: Play/Pause  |  L: Loop ' + loopLabel + '  |  ESC: Back';
	}

	function createLayout():Void
	{
		baseRect = createBaseRect();
		baseRect.screenCenter();
		baseRect.x = 136.4;
		baseRect.y = 540.3;
		add(baseRect);

		cdSprite = createStaticSprite(CD_ASSET, 220, 220, FlxColor.WHITE);
		cdSprite.antialiasing = ClientPrefs.data.antialiasing;
		cdSprite.x = 459;
		cdSprite.y = 112;
		add(cdSprite);

		leftArrow = createStaticSprite(LEFT_ARROW_ASSET, 88, 88, FlxColor.fromRGB(255, 240, 180));
		leftArrow.antialiasing = ClientPrefs.data.antialiasing;
		leftArrowBaseX = baseRect.x - leftArrow.width - 36;
		leftArrow.x = leftArrowBaseX;
		leftArrow.y = baseRect.y + (baseRect.height - leftArrow.height) * 0.5;
		add(leftArrow);

		rightArrow = createStaticSprite(RIGHT_ARROW_ASSET, 88, 88, FlxColor.fromRGB(255, 240, 180));
		rightArrow.antialiasing = ClientPrefs.data.antialiasing;
		rightArrowBaseX = baseRect.x + baseRect.width + 36;
		rightArrow.x = rightArrowBaseX;
		rightArrow.y = baseRect.y + (baseRect.height - rightArrow.height) * 0.5;
		add(rightArrow);

		songNameText = new Alphabet(0, 0, '', true);
		songNameText.alignment = CENTERED;
		songNameText.setScale(0.85);
		add(songNameText);
		repositionSongName();
	}

	function createBaseRect():FlxSprite
	{
		var spr:FlxSprite = new FlxSprite();
		var atlasPath:String = 'images/' + BASE_ASSET + '.xml';
		if (Paths.fileExists(atlasPath, AssetType.TEXT))
		{
			spr.frames = Paths.getSparrowAtlas(BASE_ASSET);
			var framesAdded:Bool = false;
			for (prefix in ['idle', 'base', 'rect', 'rectangle', 'float'])
			{
				spr.animation.addByPrefix(prefix, prefix, 24, true);
				var anim = spr.animation.getByName(prefix);
				if (anim != null && anim.frames != null && anim.frames.length > 0)
				{
					framesAdded = true;
					spr.animation.play(prefix);
					break;
				}
			}

			if (!framesAdded && spr.frames != null && spr.frames.frames != null && spr.frames.frames.length > 0)
			{
				var frameIndices:Array<Int> = [];
				for (i in 0...spr.frames.frames.length)
					frameIndices.push(i);
				spr.animation.add('idle', frameIndices, 24, true);
				spr.animation.play('idle');
			}
		}
		else if (Paths.fileExists('images/' + BASE_ASSET + '.png', AssetType.IMAGE))
		{
			spr.loadGraphic(Paths.image(BASE_ASSET));
		}
		else
		{
			spr.makeGraphic(640, 220, FlxColor.fromRGB(28, 21, 40));
		}

		if (spr.width <= 0 || spr.height <= 0)
			spr.makeGraphic(640, 220, FlxColor.fromRGB(28, 21, 40));

		spr.antialiasing = ClientPrefs.data.antialiasing;
		return spr;
	}

	function createStaticSprite(asset:String, fallbackWidth:Int, fallbackHeight:Int, fallbackColor:Int):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite();
		if (Paths.fileExists('images/' + asset + '.png', AssetType.IMAGE))
			spr.loadGraphic(Paths.image(asset));
		else
			spr.makeGraphic(fallbackWidth, fallbackHeight, fallbackColor);
		return spr;
	}

	function repositionSongName():Void
	{
		if (songNameText == null || baseRect == null)
			return;

		songNameText.x = 631.8;
		songNameText.y = 563.8;
	}

	function animateArrowPress(isLeft:Bool):Void
	{
		var arrow = isLeft ? leftArrow : rightArrow;
		if (arrow == null)
			return;

		var baseX:Float = isLeft ? leftArrowBaseX : rightArrowBaseX;
		var offset:Float = isLeft ? -ARROW_PRESS_OFFSET : ARROW_PRESS_OFFSET;
		var moveTween:FlxTween = isLeft ? leftArrowTween : rightArrowTween;
		var scaleTween:FlxTween = isLeft ? leftArrowScaleTween : rightArrowScaleTween;

		if (moveTween != null) moveTween.cancel();
		if (scaleTween != null) scaleTween.cancel();

		arrow.x = baseX;
		arrow.scale.set(1, 1);

		moveTween = FlxTween.tween(arrow, {x: baseX + offset}, 0.08, {ease: FlxEase.circOut, onComplete: function(_)
		{
			if (isLeft)
				leftArrowTween = FlxTween.tween(arrow, {x: baseX}, 0.08, {ease: FlxEase.circOut});
			else
				rightArrowTween = FlxTween.tween(arrow, {x: baseX}, 0.08, {ease: FlxEase.circOut});
		}});

		scaleTween = FlxTween.tween(arrow.scale, {x: 1.12, y: 1.12}, 0.08, {ease: FlxEase.circOut, onComplete: function(_)
		{
			if (isLeft)
				leftArrowScaleTween = FlxTween.tween(arrow.scale, {x: 1, y: 1}, 0.08, {ease: FlxEase.circOut});
			else
				rightArrowScaleTween = FlxTween.tween(arrow.scale, {x: 1, y: 1}, 0.08, {ease: FlxEase.circOut});
		}});

		if (isLeft)
		{
			leftArrowTween = moveTween;
			leftArrowScaleTween = scaleTween;
		}
		else
		{
			rightArrowTween = moveTween;
			rightArrowScaleTween = scaleTween;
		}
	}

	function updateBackgroundColor(color:Int):Void
	{
		if (bg == null)
			return;

		if (colorTween != null)
			colorTween.cancel();

		colorTween = FlxTween.color(bg, 0.45, bg.color, color, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				colorTween = null;
			}
		});
	}

	function getTrackColor(name:String):Int
	{
		var hueSeed:Int = 0;
		for (i in 0...name.length)
			hueSeed = (hueSeed + name.charCodeAt(i) * (i + 17)) % 360;
		return FlxColor.fromHSB(hueSeed, 0.55, 0.95);
	}

	function isMusicActive():Bool
	{
		return FlxG.sound.music != null && FlxG.sound.music.playing && !isPaused;
	}
}