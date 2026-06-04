package states;

class ExtrasState extends FreeplayState
{
	override function create()
	{

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Extras Menu", null);
		#end
		FreeplayState.extrasOnly = true;
		super.create();
	}
}
