package states;

import flixel.FlxG;
import states.TitleState;
import states.MP4HandlerVideo;

class GameStartupIntroState extends MusicBeatState
{
    var video:MP4HandlerVideo;

    override function create()
    {
        super.create();

        video = new MP4HandlerVideo();

        // Just play the video and switch to TitleState after it's done
        video.playMP4(Paths.video("warning"), new TitleState());
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}
