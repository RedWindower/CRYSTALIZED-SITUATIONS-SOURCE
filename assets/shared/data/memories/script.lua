function onStepHit()

    if curStep == 74.93 then
        makeLuaSprite('GRASS', 'BFDI/Grass', -16.9, 460.1);
	    setLuaSpriteScrollFactor('GRASS', 0.9, 0.9);
	    scaleObject('GRASS', 1.1, 1.1);

        makeLuaSprite('SKY', 'BFDI/Sky', 0, 0);
	    setLuaSpriteScrollFactor('SKY', 0.9, 0.9);
	    scaleObject('SKY', 1.1, 1.1);

        makeLuaSprite('CLOUDS', 'BFDI/Clouds', -98, 73.7);
	    setLuaSpriteScrollFactor('CLOUDS', 0.9, 0.9);
	    scaleObject('CLOUDS', 1.1, 1.1);

        addLuaSprite('SKY', false);
        addLuaSprite('CLOUDS', false);
        addLuaSprite('GRASS', false);
    end
end