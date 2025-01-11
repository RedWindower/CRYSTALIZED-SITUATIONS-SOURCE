local allowCountdown = false

bit = 2


function onUpdatePost()

if getProperty('endingSong') then

	if keyJustPressed('accept') then
		endSong(true)
	end

end

end
function onEndSong()


	bit = bit - 1
	if isStoryMode and bit >0 then --Block the first countdown
	
		if bit == 1 then
			rank = 'good'
			if ratingFC == 'Clear' then
			rank = 'bad'
			if ratingFC == 'SFC' then
			rank = 'perfect'
			end
			makeLuaSprite('ending','endings/ending-'..rank,0,0)
			addLuaSprite('ending',false)
			screenCenter('ending')
			setProperty('ending.antialiasing',false)
			setObjectCamera('ending','other')
			playMusic('ending-'..rank,1,false)
		return Function_Stop;
		end
	end
	if bit == 0 then
	return Function_Continue;
	end
end
end