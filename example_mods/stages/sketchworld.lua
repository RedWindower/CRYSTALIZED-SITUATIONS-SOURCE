function onCreate()
	-- background shit
	makeLuaSprite('SKETCH', 'SKETCHWORLD/sketch', 0, 0);
	setLuaSpriteScrollFactor('SKETCH', 0.9, 0.9);
	scaleObject('SKETCH', 3, 3)
	screenCenter('SKETCH', 4, 4)
	
	addLuaSprite('SKETCH', false);
	
	close(true); --For performance reasons, close this script once the stage is fully loaded, as this script won't be used anymore after loading the stage
end