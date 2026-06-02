package states;

class ExtrasState extends FreeplayState
{
	override function create()
	{
		FreeplayState.extrasOnly = true;
		super.create();
	}
}
