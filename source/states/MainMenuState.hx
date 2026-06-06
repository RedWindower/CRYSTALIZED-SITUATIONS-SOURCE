package states;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKey;
import lime.app.Application;
import backend.WeekData;
import backend.Song;
import backend.Highscore;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import backend.MP4Handler;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.7.3'; // This is also used for Discord RPC
	public static var CSVersion:String = '1.5 HOFIX';
	public static var curSelected:Int = 0;

	static inline var ellaUnlockCode:String = 'ELLA';
	static inline var realityUnlockCode:String = 'REALITY';
	static inline var nerdUnlockCode:String = 'NERD';
	static inline var ellaSongDisplay:String = 'PIPE-DOWN-LIL-BRO';
	static inline var realitySongName:String = 'reality';
	static inline var nerdSongName:String = 'nerd';
	static inline var ellaSongDescription:String = 'its in the extras menu go check';
	static inline var ellaRequiredWeek:String = 'deletion';

	var menuItems:FlxTypedGroup<FlxSprite>;

	var optionShit:Array<String> = [
		'play',
		'freeplay',
		'ost',
		'credits',
		'options'
	];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var ellaKeysBuffer:String = '';
	var allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	var unlockOverlayActive:Bool = false;
	var unlockOverlay:FlxSprite;
	var unlockTitleText:FlxText;
	var unlockSongText:FlxText;
	var unlockDescText:FlxText;
	var hintOverlayActive:Bool = false;
	var hintOverlay:FlxSprite;
	var hintText:FlxText;
	var playWeekIndex:Int = 0;
	var curDifficulty:Int = 0;
	var difficultyText:FlxText;
	var errorOverlay:FlxSprite;
	var errorText:FlxText;
	var menuVideoPlaying:Bool = false;

	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();
		FlxG.mouse.visible = true;

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);
		maybeBackfillNerdEligibility();
		if ((FlxG.save.data.ellaUnlock == true || FlxG.save.data.realityUnlock == true || FlxG.save.data.nerdUnlock == true) && FlxG.save.data.extrasUnlocked != true)
		{
			FlxG.save.data.extrasUnlocked = true;
			FlxG.save.flush();
		}
		if (FlxG.save.data.extrasUnlocked == true && !optionShit.contains('extras') && canShowExtrasMenu())
			optionShit.push('extras');
		buildMenuItems();

		var csVer:FlxText = new FlxText(12, FlxG.height - 64, 0, "Crystalized Situations v" + CSVersion, 12);

		csVer.scrollFactor.set();
		csVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(csVer);
		var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);
		var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		fnfVer.scrollFactor.set();
		fnfVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fnfVer);
		initPlayWeekData();
		initDifficultyPicker();
		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		super.create();

		FlxG.camera.follow(camFollow, null, 9);
		tryShowEllaHint();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}
		if (unlockOverlayActive || hintOverlayActive)
		{
			super.update(elapsed);
			return;
		}
		if (errorOverlay != null)
		{
			if (controls.BACK || controls.ACCEPT || FlxG.mouse.justPressed)
				clearErrorOverlay();
			super.update(elapsed);
			return;
		}

		if (!selectedSomethin)
		{
			var mouseIndex:Int = getMouseMenuIndex();
			if (mouseIndex != -1 && mouseIndex != curSelected)
				setSelection(mouseIndex, false);
			if (mouseIndex == curSelected && FlxG.mouse.justPressed)
				confirmSelection();

			updateDifficultyPickerVisibility();
			if (isPlaySelected())
			{
				if (controls.UI_LEFT_P)
					changeDifficulty(-1);
				if (controls.UI_RIGHT_P)
					changeDifficulty(1);
			}

			if (controls.UI_UP_P)
				changeItem(-1);
	
			if (controls.UI_DOWN_P)
				changeItem(1);
	
			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
			{
				var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
				var keyName:String = Std.string(keyPressed);
				if (allowedKeys.contains(keyName))
				{
					ellaKeysBuffer += keyName;
					if (ellaKeysBuffer.length > 16)
						ellaKeysBuffer = ellaKeysBuffer.substring(ellaKeysBuffer.length - 16);
					if (ellaKeysBuffer.contains(realityUnlockCode))
					{
						handleRealityUnlock();
						ellaKeysBuffer = '';
					}
					else if (ellaKeysBuffer.contains(nerdUnlockCode))
					{
						handleNerdUnlock();
						ellaKeysBuffer = '';
					}
					else if (ellaKeysBuffer.contains(ellaUnlockCode))
					{
						if (FlxG.save.data.ellaUnlock != true)
						{
							if (FlxG.save.data.ellaUnlockEligible == true)
							{
								FlxG.save.data.ellaUnlock = true;
								FlxG.save.flush();
								maybeUnlockExtrasMenu();
								triggerEllaUnlock();
							}
							else
							{
								showEllaLockedOverlay();
							}
						}
						ellaKeysBuffer = '';
					}
				}
			}

			if (controls.ACCEPT)
				confirmSelection();
			#if desktop
			if (FlxG.keys.justPressed.V && !menuVideoPlaying)
			{
				menuVideoPlaying = true;
				selectedSomethin = true;
				new MP4Handler().playMP4Inline(Paths.video('pleadcutscene'), function()
				{
					menuVideoPlaying = false;
					selectedSomethin = false;
				});
			}
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	function triggerEllaUnlock():Void
	{
		if (unlockOverlayActive)
			return;
		unlockOverlayActive = true;
		selectedSomethin = true;
		FlxG.sound.play(Paths.sound('unlock'));

		unlockOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		unlockOverlay.scrollFactor.set();
		unlockOverlay.alpha = 0;
		add(unlockOverlay);
		FlxTween.tween(unlockOverlay, {alpha: 0.5}, 0.25, {ease: FlxEase.quadOut});

		unlockTitleText = new FlxText(0, -60, FlxG.width, 'YOU UNLOCKED...', 32);
		unlockTitleText.scrollFactor.set();
		unlockTitleText.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		unlockTitleText.alpha = 0;
		add(unlockTitleText);
		FlxTween.tween(unlockTitleText, {y: 80, alpha: 1}, 0.35, {ease: FlxEase.quadOut});

		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			showEllaUnlockSong();
		});
	}

	function showEllaUnlockSong():Void
	{
		unlockSongText = new FlxText(0, FlxG.height * 0.58, FlxG.width, ellaSongDisplay, 40);
		unlockSongText.scrollFactor.set();
		unlockSongText.setFormat('VCR OSD Mono', 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		unlockSongText.alpha = 0;
		unlockSongText.scale.set(0.9, 0.9);
		add(unlockSongText);

		var targetY:Float = FlxG.height * 0.45;
		FlxTween.tween(unlockSongText, {y: targetY, alpha: 1}, 0.25, {ease: FlxEase.quadOut});
		FlxTween.tween(unlockSongText.scale, {x: 1.05, y: 1.05}, 0.12, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween)
		{
			FlxTween.tween(unlockSongText.scale, {x: 1, y: 1}, 0.12, {ease: FlxEase.quadIn});
		}});

		unlockDescText = new FlxText(0, FlxG.height - 60, FlxG.width, ellaSongDescription, 18);
		unlockDescText.scrollFactor.set();
		unlockDescText.setFormat('VCR OSD Mono', 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		unlockDescText.alpha = 0;
		add(unlockDescText);
		FlxTween.tween(unlockDescText, {alpha: 1}, 0.25, {ease: FlxEase.quadOut});

		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			clearEllaUnlockOverlay();
		});
	}

	function clearEllaUnlockOverlay():Void
	{
		var fadeTime:Float = 0.3;
		if (unlockOverlay != null)
			FlxTween.tween(unlockOverlay, {alpha: 0}, fadeTime, {ease: FlxEase.quadIn});
		if (unlockTitleText != null)
			FlxTween.tween(unlockTitleText, {alpha: 0}, fadeTime, {ease: FlxEase.quadIn});
		if (unlockSongText != null)
			FlxTween.tween(unlockSongText, {alpha: 0}, fadeTime, {ease: FlxEase.quadIn});
		if (unlockDescText != null)
			FlxTween.tween(unlockDescText, {alpha: 0}, fadeTime, {ease: FlxEase.quadIn});

		new FlxTimer().start(fadeTime, function(tmr:FlxTimer)
		{
			cleanupUnlockObjects();
		});
	}

	function cleanupUnlockObjects():Void
	{
		if (unlockOverlay != null)
		{
			remove(unlockOverlay, true);
			unlockOverlay.destroy();
			unlockOverlay = null;
		}
		if (unlockTitleText != null)
		{
			remove(unlockTitleText, true);
			unlockTitleText.destroy();
			unlockTitleText = null;
		}
		if (unlockSongText != null)
		{
			remove(unlockSongText, true);
			unlockSongText.destroy();
			unlockSongText = null;
		}
		if (unlockDescText != null)
		{
			remove(unlockDescText, true);
			unlockDescText.destroy();
			unlockDescText = null;
		}
		unlockOverlayActive = false;
		selectedSomethin = false;
	}

	function tryShowEllaHint():Void
	{
		if (FlxG.save.data.ellaHintPending == true)
		{
			FlxG.save.data.ellaHintPending = false;
			FlxG.save.data.ellaHintShown = true;
			FlxG.save.flush();
			showEllaHintOverlay();
		}
	}

	function maybeBackfillNerdEligibility():Void
	{
		if (FlxG.save.data.nerdUnlockEligible == true || FlxG.save.data.nerdUnlock == true)
			return;

		var weekCompleted:Map<String, Bool> = cast FlxG.save.data.weekCompleted;
		var deletionCompleted:Bool = weekCompleted != null && weekCompleted.exists('deletion') && weekCompleted.get('deletion');
		if (!deletionCompleted)
			return;

		var hasLegacyRealvancyScore:Bool = false;
		var songScores:Map<String, Int> = cast FlxG.save.data.songScores;
		if (songScores != null)
		{
			for (key => score in songScores)
			{
				if (score > 0 && key != null && key.indexOf('realvancy') == 0)
				{
					hasLegacyRealvancyScore = true;
					break;
				}
			}
		}

		if (hasLegacyRealvancyScore)
		{
			FlxG.save.data.nerdUnlockEligible = true;
			FlxG.save.flush();
		}
	}

	function showEllaHintOverlay():Void
	{
		if (hintOverlayActive) return;
		hintOverlayActive = true;
		selectedSomethin = true;

		hintOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		hintOverlay.scrollFactor.set();
		hintOverlay.alpha = 0;
		add(hintOverlay);
		FlxTween.tween(hintOverlay, {alpha: 0.5}, 0.25, {ease: FlxEase.quadOut});

		hintText = new FlxText(0, 0, FlxG.width,
			'Type in ELLA for a surprise!', 24);
		hintText.scrollFactor.set();
		hintText.setFormat('VCR OSD Mono', 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		hintText.alpha = 0;
		hintText.screenCenter();
		add(hintText);
		FlxTween.tween(hintText, {alpha: 1}, 0.25, {ease: FlxEase.quadOut});

		new FlxTimer().start(4, function(_)
		{
			clearEllaHintOverlay();
		});
	}

	function clearEllaHintOverlay():Void
	{
		var fadeTime:Float = 0.3;
		if (hintOverlay != null)
			FlxTween.tween(hintOverlay, {alpha: 0}, fadeTime, {ease: FlxEase.quadIn});
		if (hintText != null)
			FlxTween.tween(hintText, {alpha: 0}, fadeTime, {ease: FlxEase.quadIn});

		new FlxTimer().start(fadeTime, function(_)
		{
			if (hintOverlay != null)
			{
				remove(hintOverlay, true);
				hintOverlay.destroy();
				hintOverlay = null;
			}
			if (hintText != null)
			{
				remove(hintText, true);
				hintText.destroy();
				hintText = null;
			}
			hintOverlayActive = false;
			selectedSomethin = false;
		});
	}

	function showEllaLockedOverlay(?message:String):Void
	{
		if (hintOverlayActive) return;
		hintOverlayActive = true;
		selectedSomethin = true;

		hintOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		hintOverlay.scrollFactor.set();
		hintOverlay.alpha = 0.5;
		add(hintOverlay);

		var hintMessage:String = message;
		if (hintMessage == null)
			hintMessage = 'UH OH!\n\nYou must beat the ' + ellaRequiredWeek.toUpperCase() + ' week first.';

		hintText = new FlxText(0, 0, FlxG.width,
			hintMessage, 24);
		hintText.scrollFactor.set();
		hintText.setFormat('VCR OSD Mono', 24, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		hintText.screenCenter();
		add(hintText);

		new FlxTimer().start(4, function(_)
		{
			clearEllaHintOverlay();
		});
	}

	function handleRealityUnlock():Void
	{
		if (FlxG.save.data.realityUnlock != true)
		{
			FlxG.save.data.realityUnlock = true;
			FlxG.save.flush();
		}
		maybeUnlockExtrasMenu();
		curDifficulty = getHardDifficultyIndex();
		startSecretSong(realitySongName);
	}

	function handleNerdUnlock():Void
	{
		if (FlxG.save.data.nerdUnlockEligible != true)
		{
			showEllaLockedOverlay('UH OH!\n\nYou must beat REALVANCY with no misses first.');
			return;
		}
		if (FlxG.save.data.nerdUnlock != true)
		{
			FlxG.save.data.nerdUnlock = true;
			FlxG.save.flush();
		}
		maybeUnlockExtrasMenu();
		startSecretSong(nerdSongName);
	}

	function getHardDifficultyIndex():Int
	{
		if (Difficulty.list.length <= 0)
			return 0;
		for (i in 0...Difficulty.list.length)
		{
			if (Difficulty.list[i].toLowerCase() == 'hard')
				return i;
		}
		return Difficulty.list.length - 1;
	}

	function startSecretSong(songName:String):Void
	{
		selectedSomethin = true;
		var songLowercase:String = Paths.formatToSongPath(songName);
		if (isHardOnlySong(songLowercase))
			curDifficulty = getHardDifficultyIndex();
		var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
		try
		{
			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			LoadingState.loadAndSwitchState(new PlayState());
			FlxG.sound.music.volume = 0;
			FreeplayState.destroyFreeplayVocals();
			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
		}
		catch (e:Dynamic)
		{
			selectedSomethin = false;
			showErrorOverlay('Failed to load secret song.\n' + e);
		}
	}

	function isHardOnlySong(songName:String):Bool
	{
		return songName == 'reality' || songName == 'pipe-down-lil-bro';
	}

	function confirmSelection():Void
	{
		FlxG.sound.play(Paths.sound('confirmMenu'));
		if (optionShit[curSelected] == 'donate')
		{
			CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
			return;
		}
		selectedSomethin = true;

		if (ClientPrefs.data.flashing && magenta != null)
			FlxTween.tween(magenta, {alpha: 0.35}, 0.12, {ease: FlxEase.quadOut, type: PINGPONG});

		var selectedItem:FlxSprite = menuItems.members[curSelected];
		for (i in 0...menuItems.members.length)
		{
			var item = menuItems.members[i];
			if (item == null || i == curSelected)
				continue;

			FlxTween.tween(item, {alpha: 0}, 0.24, {
				ease: FlxEase.quadOut,
				onComplete: function(_)
				{
					item.kill();
				}
			});
		}

		if (selectedItem != null)
		{
			selectedItem.animation.play('selected');
			selectedItem.centerOffsets();
			selectedItem.updateHitbox();
			FlxTween.tween(selectedItem, {
				x: (FlxG.width - selectedItem.width) * 0.5,
				y: (FlxG.height - selectedItem.height) * 0.5
			}, 0.28, {
				ease: FlxEase.quadOut,
				onComplete: function(_)
				{
					runSelectedOption();
				}
			});
		}
		else
		{
			runSelectedOption();
		}
	}

	function runSelectedOption():Void
	{
		switch (optionShit[curSelected])
		{
			case 'play':
				startPlayWeek();
			case 'freeplay':
				MusicBeatState.switchState(new FreeplayState());
			case 'ost':
				MusicBeatState.switchState(new OSTState());
			case 'extras':
				MusicBeatState.switchState(new ExtrasState());
			case 'credits':
				MusicBeatState.switchState(new CreditsState());
			case 'options':
				MusicBeatState.switchState(new OptionsState());
				OptionsState.onPlayState = false;
				if (PlayState.SONG != null)
				{
					PlayState.SONG.arrowSkin = null;
					PlayState.SONG.splashSkin = null;
					PlayState.stageUI = 'normal';
				}
		}

	}

	function initPlayWeekData():Void
	{
		WeekData.reloadWeekFiles(true);
		if (WeekData.weeksList.length == 0)
			return;
		playWeekIndex = getFirstUnlockedWeek();
		PlayState.storyWeek = playWeekIndex;
		var week:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[playWeekIndex]);
		if (week != null)
		{
			WeekData.setDirectoryFromWeek(week);
			Difficulty.loadFromWeek(week);
		}
		syncDifficultyToList();
	}

	function initDifficultyPicker():Void
	{
		difficultyText = new FlxText(0, 12, 0, '', 16);
		difficultyText.scrollFactor.set();
		difficultyText.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(difficultyText);
		updateDifficultyText();
		updateDifficultyPickerVisibility();
	}

	function updateDifficultyText():Void
	{
		if (difficultyText == null)
			return;
		if (Difficulty.list.length <= 0)
		{
			difficultyText.text = '';
			return;
		}
		difficultyText.text = 'DIFFICULTY: ' + Difficulty.getString(curDifficulty).toUpperCase();
		difficultyText.x = FlxG.width - (difficultyText.width + 12);
		difficultyText.y = 12;
	}

	function updateDifficultyPickerVisibility():Void
	{
		if (difficultyText != null)
			difficultyText.visible = isPlaySelected();
	}

	function isPlaySelected():Bool
	{
		return optionShit[curSelected] == 'play';
	}

	function changeDifficulty(change:Int = 0):Void
	{
		if (Difficulty.list.length <= 0)
			return;
		curDifficulty += change;
		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length - 1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;
		updateDifficultyText();
	}

	function syncDifficultyToList():Void
	{
		if (Difficulty.list.length <= 0)
		{
			curDifficulty = 0;
			updateDifficultyText();
			return;
		}
		var defaultName:String = Difficulty.getDefault();
		var defaultIndex:Int = Difficulty.list.indexOf(defaultName);
		if (defaultIndex < 0)
			defaultIndex = 0;
		if (curDifficulty < 0 || curDifficulty >= Difficulty.list.length)
			curDifficulty = defaultIndex;
		updateDifficultyText();
	}

	function startPlayWeek():Void
	{
		if (WeekData.weeksList.length == 0)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}
		var weekName:String = WeekData.weeksList[playWeekIndex];
		if (weekIsLocked(weekName))
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}
		var week:WeekData = WeekData.weeksLoaded.get(weekName);
		if (week == null)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}

		WeekData.setDirectoryFromWeek(week);
		Difficulty.loadFromWeek(week);
		syncDifficultyToList();

		var songArray:Array<String> = [];
		for (i in 0...week.songs.length)
			songArray.push(week.songs[i][0]);
		if (songArray.length == 0)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}

		try
		{
			PlayState.storyPlaylist = songArray;
			PlayState.isStoryMode = true;
			PlayState.storyDifficulty = curDifficulty;
			PlayState.storyWeek = playWeekIndex;
			PlayState.campaignScore = 0;
			PlayState.campaignMisses = 0;
			PlayState.seenCutscene = false;

			var diffic:String = Difficulty.getFilePath(curDifficulty);
			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			LoadingState.loadAndSwitchState(new PlayState(), true);
			//new MP4Handler().playMP4(Paths.video('pleadcutscene'), new PlayState(), false, false, false);
			FreeplayState.destroyFreeplayVocals();
		}
		catch (e:Dynamic)
		{
			trace('Failed to start week: ' + e);
			FlxG.sound.play(Paths.sound('cancelMenu'));
			showErrorOverlay('Failed to start week.\n' + e);
		}
	}

	function getFirstUnlockedWeek():Int
	{
		for (i in 0...WeekData.weeksList.length)
		{
			if (!weekIsLocked(WeekData.weeksList[i]))
				return i;
		}
		return 0;
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		if (leWeek == null)
			return true;
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0
			&& (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	function showErrorOverlay(message:String):Void
	{
		if (errorOverlay != null)
			clearErrorOverlay();
		errorOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		errorOverlay.scrollFactor.set();
		errorOverlay.alpha = 0.7;
		add(errorOverlay);

		errorText = new FlxText(40, 0, FlxG.width - 80, message, 16);
		errorText.scrollFactor.set();
		errorText.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		errorText.screenCenter(Y);
		add(errorText);
	}

	function clearErrorOverlay():Void
	{
		if (errorText != null)
		{
			remove(errorText, true);
			errorText.destroy();
			errorText = null;
		}
		if (errorOverlay != null)
		{
			remove(errorOverlay, true);
			errorOverlay.destroy();
			errorOverlay = null;
		}
	}

	function buildMenuItems():Void
	{
		if (menuItems == null)
		{
			menuItems = new FlxTypedGroup<FlxSprite>();
			add(menuItems);
		}
		else
		{
			for (item in menuItems.members)
			{
				if (item != null)
				{
					remove(item, true);
					item.destroy();
				}
			}
			menuItems.clear();
		}

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140) + offset);
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6)
				scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.updateHitbox();
			menuItem.screenCenter(X);
		}
	}

	function maybeUnlockExtrasMenu():Void
	{
		if (FlxG.save.data.extrasUnlocked == true)
			return;
		FlxG.save.data.extrasUnlocked = true;
		FlxG.save.flush();
		if (!canShowExtrasMenu())
		{
			showErrorOverlay('Missing menu_extras asset.\nAdd images/mainmenu/menu_extras.png and .xml.');
			return;
		}
		if (!optionShit.contains('extras'))
		{
			optionShit.push('extras');
			buildMenuItems();
			curSelected = optionShit.length - 1;
			changeItem(0);
		}
	}

	function canShowExtrasMenu():Bool
	{
		return Paths.fileExists('images/mainmenu/menu_extras.png', IMAGE);
	}

	function getMouseMenuIndex():Int
	{
		for (i in 0...menuItems.members.length)
		{
			var item = menuItems.members[i];
			if (item != null && isMouseOverItem(item))
				return i;
		}
		return -1;
	}

	function isMouseOverItem(item:FlxSprite):Bool
	{
		return FlxG.mouse.x >= item.x && FlxG.mouse.x <= item.x + item.width
			&& FlxG.mouse.y >= item.y && FlxG.mouse.y <= item.y + item.height;
	}

	function setSelection(newIndex:Int, playSound:Bool = true):Void
	{
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'));
		menuItems.members[curSelected].animation.play('idle');
		menuItems.members[curSelected].updateHitbox();
		menuItems.members[curSelected].screenCenter(X);

		curSelected = newIndex;

		menuItems.members[curSelected].animation.play('selected');
		menuItems.members[curSelected].centerOffsets();
		menuItems.members[curSelected].screenCenter(X);

		camFollow.setPosition(menuItems.members[curSelected].getGraphicMidpoint().x,
			menuItems.members[curSelected].getGraphicMidpoint().y - (menuItems.length > 4 ? menuItems.length * 8 : 0));
		updateDifficultyPickerVisibility();
	}

	function changeItem(huh:Int = 0)
	{
		var newIndex:Int = curSelected + huh;

		if (newIndex >= menuItems.length)
			newIndex = 0;
		if (newIndex < 0)
			newIndex = menuItems.length - 1;
		setSelection(newIndex, true);
	}
}
