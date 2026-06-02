package states;

import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import openfl.utils.Assets as OpenFlAssets;

#if sys
import sys.FileSystem;
#end

typedef OSTTrack = {
	var name:String;
	var isSong:Bool;
}

class OSTState extends MusicBeatState
{
	var tracks:Array<OSTTrack> = [];
	var trackTexts:FlxTypedGroup<FlxText>;
	var curSelected:Int = 0;
	var titleText:FlxText;
	var nowPlayingText:FlxText;
	var helpText:FlxText;
	var previewTimer:FlxTimer;
	var previewDuration:Float = 6;
	var isPlayingFull:Bool = false;
	var isPaused:Bool = false;
	var loopEnabled:Bool = true;

	override function create()
	{
		FlxG.mouse.visible = true;

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		titleText = new FlxText(0, 16, FlxG.width, 'OST', 32);
		titleText.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.scrollFactor.set();
		add(titleText);

		nowPlayingText = new FlxText(0, 56, FlxG.width, 'Now Playing: -', 16);
		nowPlayingText.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		nowPlayingText.scrollFactor.set();
		add(nowPlayingText);

		buildTrackList();

		trackTexts = new FlxTypedGroup<FlxText>();
		add(trackTexts);

		var startY:Float = 96;
		for (i in 0...tracks.length)
		{
			var label = (tracks[i].isSong ? 'SONG - ' : 'MUSIC - ') + tracks[i].name.toUpperCase();
			var item = new FlxText(40, startY + (i * 28), FlxG.width - 80, label, 16);
			item.setFormat('VCR OSD Mono', 16, FlxColor.GRAY, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			item.scrollFactor.set();
			trackTexts.add(item);
		}

		helpText = new FlxText(0, FlxG.height - 24, FlxG.width, 'ENTER: Play  |  ESC: Back', 16);
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
		if (controls.UI_UP_P)
			changeSelection(-1, true);
		if (controls.UI_DOWN_P)
			changeSelection(1, true);
		if (controls.UI_LEFT_P)
			changeSelection(-1, true);
		if (controls.UI_RIGHT_P)
			changeSelection(1, true);
		if (controls.ACCEPT)
			togglePlayPause();
		if (FlxG.keys.justPressed.L)
			toggleLoop();
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
					tracks.push({name: file.substr(0, file.length - 4), isSong: false});
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
					tracks.push({name: entry, isSong: true});
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
		var i = 0;
		for (item in trackTexts.members)
		{
			if (item == null) continue;
			item.color = (i == curSelected) ? FlxColor.WHITE : FlxColor.GRAY;
			item.alpha = (i == curSelected) ? 1 : 0.6;
			i++;
		}
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
		var status = isPlayingFull ? (isPaused ? 'Paused: ' : 'Now Playing: ') : 'Now Playing: ';
		nowPlayingText.text = status + track.name.toUpperCase();
	}

	function updateHelpText():Void
	{
		var loopLabel = loopEnabled ? 'ON' : 'OFF';
		helpText.text = 'ENTER: Play/Pause  |  Left/Right: Prev/Next  |  L: Loop ' + loopLabel + '  |  ESC: Back';
	}
}