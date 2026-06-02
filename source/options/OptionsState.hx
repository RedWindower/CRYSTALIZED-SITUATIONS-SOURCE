package options;

import states.MainMenuState;
import states.StoryMenuState;
import states.TitleState;
import backend.StageData;
import backend.Highscore;
import substates.Prompt;
import flixel.util.FlxSave;

#if ACHIEVEMENTS_ALLOWED
import backend.Achievements;
#end

class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay', 'Reset Data'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'Reset Data':
				openSubState(new Prompt('This will reset all save data.\nThis cannot be undone.\n\nProceed?', 0, function() {
					resetAllData();
				}, null));
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create() {
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		FlxG.mouse.visible = true;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.updateHitbox();

		bg.screenCenter();
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		var mouseIndex:Int = getMouseOptionIndex();
		if (mouseIndex != -1 && mouseIndex != curSelected)
			setSelection(mouseIndex, false);
		if (mouseIndex == curSelected && FlxG.mouse.justPressed)
			openSelectedSubstate(options[curSelected]);

		if (controls.UI_UP_P) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1);
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else MusicBeatState.switchState(new MainMenuState());
		}
		else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
	}
	
	function changeSelection(change:Int = 0) {
		var newIndex:Int = curSelected + change;
		if (newIndex < 0)
			newIndex = options.length - 1;
		if (newIndex >= options.length)
			newIndex = 0;
		setSelection(newIndex, true);
	}

	function setSelection(newIndex:Int, playSound:Bool = true):Void
	{
		curSelected = newIndex;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function getMouseOptionIndex():Int
	{
		for (i in 0...grpOptions.members.length)
		{
			var item = grpOptions.members[i];
			if (item != null && isMouseOverOption(item))
				return i;
		}
		return -1;
	}

	function isMouseOverOption(item:Alphabet):Bool
	{
		return FlxG.mouse.x >= item.x && FlxG.mouse.x <= item.x + item.width
			&& FlxG.mouse.y >= item.y && FlxG.mouse.y <= item.y + item.height;
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}

	function resetAllData():Void
	{
		FlxG.save.erase();
		FlxG.save.flush();

		var controlsSave:FlxSave = new FlxSave();
		controlsSave.bind('controls_v3', CoolUtil.getSavePath());
		controlsSave.erase();
		controlsSave.flush();

		StoryMenuState.weekCompleted = new Map<String, Bool>();
		Highscore.weekScores = new Map();
		Highscore.songScores = new Map();
		Highscore.songRating = new Map();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.achievementsUnlocked = [];
		Achievements.variables = [];
		Achievements.save();
		#end

		ClientPrefs.data = {};
		ClientPrefs.resetKeys();
		ClientPrefs.saveSettings();

		FlxG.sound.play(Paths.sound('confirmMenu'));
		MusicBeatState.switchState(new TitleState());
	}
}