function onCreate()
	makeLuaSprite('PAPER', 'SCRATCH/paper',0,0)
	setLuaSpriteScrollFactor('PAPER', 0.9, 0.9);
	scaleObject('PAPER', 3, 3);
	screenCenter('PAPER', 4, 4);


	addLuaSprite('PAPER',false)

end

	--true = infront of charaters false = behind charaters