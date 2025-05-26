function onCreate()
	--Iterate over all notes
	for i = 0, getProperty('unspawnNotes.length')-1 do
		--Check if the note is a Blast Note
		if getPropertyFromGroup('unspawnNotes', i, 'noteType') == 'BlastNotes' then
			setPropertyFromGroup('unspawnNotes', i, 'texture', 'BlastNotes'); --Change texture
			setPropertyFromGroup('unspawnNotes', i, 'multSpeed', 1.2); --Change note speed (holy shit 0.6 is good)
			setPropertyFromGroup('unspawnNotes', i, 'missHealth', 0.6); --Change amount of health to take when you miss like a fucking moron
		end
	end
	--debugPrint('Script started!')
end

-- Function called when you hit a note (after note hit calculations)
-- id: The note member id, you can get whatever variable you want from this note, example: "getPropertyFromGroup('notes', id, 'strumTime')"
-- noteData: 0 = Left, 1 = Down, 2 = Up, 3 = Right
-- noteType: The note type string/tag
-- isSustainNote: If it's a hold note, can be either true or false
-- taken from Fanmade Gunfight Hank mod

dodgeAnimations = {'dodge', 'dodge', 'dodge', 'dodge'}
attackAnimations = {'attack', 'attack', 'attack', 'attack'}
function goodNoteHit(id, noteData, noteType, isSustainNote)
	if noteType == 'BlastNotes' then
		characterPlayAnim('bf', dodgeAnimations[noteData+1], true);
		setProperty('bf.specialAnim', true);
		playSound('blast', 0.7, 'blast');
		soundFadeOut('blast', 0.3, 0);

		local animToPlay = '';
		if noteData == 0 then
			animToPlay = 'singLEFT-alt';
		elseif noteData == 1 then
			animToPlay = 'singDOWN-alt';
		elseif noteData == 2 then
			animToPlay = 'singUP-alt';
		elseif noteData == 3 then
			animToPlay = 'singRIGHT-alt';
		end
		characterPlayAnim('dad', attackAnimations[noteData+1], true);
		setProperty('dad.specialAnim', true);
	end
end

local healthDrain = 0;
function noteMiss(id, noteData, noteType, isSustainNote)
	if noteType == 'BlastNotes' then
		playSound('blast', 0.7, 'blast');
		soundFadeOut('blast', 0.8, 0.3);
		-- bf anim
		characterPlayAnim('bf', 'hurt', true);
		setProperty('bf.specialAnim', true);

		-- dad anim
		characterPlayAnim('dad', 'attack', true);
		setProperty('dad.specialAnim', true);

		-- health loss | || || |_
		--setProperty('health', getProperty('health') - 0.6);
		healthDrain = healthDrain + 0.1;
	end
end

function onUpdate(elapsed)
	if healthDrain > 0 then
		healthDrain = healthDrain - 0.1 * elapsed;
		setProperty('health', getProperty('health') - 0.1 * elapsed);
		if healthDrain < 0 then
			healthDrain = 0;
		end
	end
end