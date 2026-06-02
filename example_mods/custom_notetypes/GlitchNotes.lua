local activeEffect = nil
local effectTimerTag = 'glitchEffectEnd'
local effectDuration = 999
local pizzaglitch = 'pizzaglitch'
local bfOriginalChar = nil
local bfSwapActive = false
local bfRevertPending = false
local origStrumX = {}
local origStrumY = {}
local origKeysArray = nil
local origDownScroll = false
local controlsInfoShown = false
local windowBaseX = 0
local windowBaseY = 0
local windowRadius = 120
local windowAngle = 0

function onCreate()
	for i = 0, getProperty('unspawnNotes.length') - 1 do
		if getPropertyFromGroup('unspawnNotes', i, 'noteType') == 'GlitchNotes' then
			setPropertyFromGroup('unspawnNotes', i, 'texture', 'GlitchNotes')
			setPropertyFromGroup('unspawnNotes', i, 'missHealth', 0.4)
			if getPropertyFromGroup('unspawnNotes', i, 'mustPress') then
				setPropertyFromGroup('unspawnNotes', i, 'ignoreNote', true)
			end
		end
	end
end

function onCreatePost()
	cacheStrumPositions()
	origKeysArray = getProperty('keysArray')
	origDownScroll = getPropertyFromClass('ClientPrefs', 'downScroll')
	windowBaseX = getPropertyFromClass('openfl.Lib', 'application.window.x')
	windowBaseY = getPropertyFromClass('openfl.Lib', 'application.window.y')
end

function cacheStrumPositions()
	for i = 0, getProperty('strumLineNotes.length') - 1 do
		origStrumX[i] = getPropertyFromGroup('strumLineNotes', i, 'x')
		origStrumY[i] = getPropertyFromGroup('strumLineNotes', i, 'y')
	end
end

function goodNoteHit(id, direction, noteType, isSustainNote)
	if noteType ~= 'GlitchNotes' then
		return
	end
	applyBfSwap()
	if activeEffect ~= nil then
		return
	end
	startRandomEffect()
end

function applyBfSwap()
	if bfSwapActive then
		return
	end
	bfSwapActive = true
	bfOriginalChar = getProperty('boyfriend.curCharacter')
	setProperty('boyfriend.alpha', 0)
	triggerEvent('Change Character', 'bf', pizzaglitch)
	doTweenAlpha('bfGlitchFadeIn', 'boyfriend', 1, 0.3, 'linear')
	runTimer('glitchBfRevert', 15)
end

function startRandomEffect()
	local effects = { 'flip', 'scroll', 'controls', 'scramble', 'scatter', 'window_spin', 'window_notes' }
	local idx = getRandomInt(1, #effects)
	activeEffect = effects[idx]

	if activeEffect == 'flip' then
		setProperty('camGame.angle', 180)
		setProperty('camHUD.angle', 180)
	elseif activeEffect == 'scroll' then
		applyScrollRandom()
	elseif activeEffect == 'controls' then
		applyControlSwap()
	elseif activeEffect == 'scramble' then
		scrambleNotes()
	elseif activeEffect == 'scatter' then
		scatterNotes()
	elseif activeEffect == 'window_spin' then
		setPropertyFromClass('openfl.Lib', 'application.window.maximized', false)
	elseif activeEffect == 'window_notes' then
		createNoteWindow()
	end

	runTimer(effectTimerTag, effectDuration)
end

function applyScrollRandom()
	local down = getRandomBool(50)
	setPropertyFromClass('ClientPrefs', 'downScroll', down)
	setProperty('downscroll', down)
	for i = 0, getProperty('strumLineNotes.length') - 1 do
		setPropertyFromGroup('strumLineNotes', i, 'downScroll', down)
	end
end

function applyControlSwap()
	local maps = {
		{ 'note_up', 'note_right', 'note_left', 'note_down' },
		{ 'note_right', 'note_left', 'note_down', 'note_up' },
		{ 'note_down', 'note_up', 'note_right', 'note_left' }
	}
	local choice = maps[getRandomInt(1, #maps)]
	setProperty('keysArray', choice)
	if not controlsInfoShown then
		controlsInfoShown = true
		local msg = 'Controls scrambled!\nLEFT=' .. shortName(choice[1]) ..
			' DOWN=' .. shortName(choice[2]) ..
			' UP=' .. shortName(choice[3]) ..
			' RIGHT=' .. shortName(choice[4])
		makeLuaText('glitchControlsInfo', msg, 900, 20, 20)
		setTextSize('glitchControlsInfo', 22)
		setTextBorder('glitchControlsInfo', 2, '000000')
		setObjectCamera('glitchControlsInfo', 'hud')
		addLuaText('glitchControlsInfo')
		runTimer('glitchControlsInfoHide', 2)
	end
end

function shortName(keyName)
	if keyName == 'note_left' then return 'LEFT' end
	if keyName == 'note_down' then return 'DOWN' end
	if keyName == 'note_up' then return 'UP' end
	if keyName == 'note_right' then return 'RIGHT' end
	return keyName
end

function scrambleNotes()
	local order = {}
	for i = 0, 3 do
		order[i + 1] = origStrumX[i]
	end
	shuffle(order)
	for i = 0, 3 do
		setPropertyFromGroup('playerStrums', i, 'x', order[i + 1])
		setPropertyFromGroup('strumLineNotes', i + 4, 'x', order[i + 1])
	end
end

function scatterNotes()
	for i = 0, 3 do
		local rx = getRandomInt(60, screenWidth - 60)
		local ry = getRandomInt(120, screenHeight - 120)
		setPropertyFromGroup('playerStrums', i, 'x', rx)
		setPropertyFromGroup('playerStrums', i, 'y', ry)
		setPropertyFromGroup('strumLineNotes', i + 4, 'x', rx)
		setPropertyFromGroup('strumLineNotes', i + 4, 'y', ry)
	end
end

function createNoteWindow()
	makeLuaSprite('glitchWindow', '', 120, 120)
	makeGraphic('glitchWindow', 520, 320, '000000')
	setProperty('glitchWindow.alpha', 0.7)
	setObjectCamera('glitchWindow', 'hud')
	addLuaSprite('glitchWindow', true)
	for i = 0, 3 do
		local rx = 150 + (i * 120)
		local ry = 380
		setPropertyFromGroup('playerStrums', i, 'x', rx)
		setPropertyFromGroup('playerStrums', i, 'y', ry)
		setPropertyFromGroup('strumLineNotes', i + 4, 'x', rx)
		setPropertyFromGroup('strumLineNotes', i + 4, 'y', ry)
	end
end

function shuffle(t)
	for i = #t, 2, -1 do
		local j = getRandomInt(1, i)
		t[i], t[j] = t[j], t[i]
	end
end

function onTimerCompleted(tag, loops, loopsLeft)
	if tag == effectTimerTag then
		endActiveEffect()
	end
	if tag == 'glitchControlsInfoHide' then
		removeLuaText('glitchControlsInfo', true)
	end
	if tag == 'glitchBfRevert' then
		if bfSwapActive and bfOriginalChar ~= nil then
			bfRevertPending = true
			doTweenAlpha('bfGlitchFadeOut', 'boyfriend', 0, 0.4, 'linear')
		end
	end
end

function onTweenCompleted(tag)
	if tag == 'bfGlitchFadeOut' and bfRevertPending then
		bfRevertPending = false
		triggerEvent('Change Character', 'bf', bfOriginalChar)
		doTweenAlpha('bfOrigFadeIn', 'boyfriend', 1, 0.4, 'linear')
		bfSwapActive = false
	end
end

function endActiveEffect()
	if activeEffect == 'flip' then
		setProperty('camGame.angle', 0)
		setProperty('camHUD.angle', 0)
	elseif activeEffect == 'scroll' then
		setPropertyFromClass('ClientPrefs', 'downScroll', origDownScroll)
		setProperty('downscroll', origDownScroll)
		for i = 0, getProperty('strumLineNotes.length') - 1 do
			setPropertyFromGroup('strumLineNotes', i, 'downScroll', origDownScroll)
		end
	elseif activeEffect == 'controls' then
		if origKeysArray ~= nil then
			setProperty('keysArray', origKeysArray)
		end
	elseif activeEffect == 'scramble' or activeEffect == 'scatter' or activeEffect == 'window_notes' then
		for i = 0, 3 do
			setPropertyFromGroup('playerStrums', i, 'x', origStrumX[i])
			setPropertyFromGroup('playerStrums', i, 'y', origStrumY[i])
			setPropertyFromGroup('strumLineNotes', i + 4, 'x', origStrumX[i])
			setPropertyFromGroup('strumLineNotes', i + 4, 'y', origStrumY[i])
		end
		if activeEffect == 'window_notes' then
			removeLuaSprite('glitchWindow', true)
		end
	elseif activeEffect == 'window_spin' then
		setPropertyFromClass('openfl.Lib', 'application.window.maximized', false)
		setPropertyFromClass('openfl.Lib', 'application.window.x', windowBaseX)
		setPropertyFromClass('openfl.Lib', 'application.window.y', windowBaseY)
	end

	activeEffect = nil
end

function onUpdate(elapsed)
	if activeEffect == 'window_spin' then
		windowAngle = windowAngle + elapsed * 10
		local x = windowBaseX + math.cos(windowAngle) * windowRadius
		local y = windowBaseY + math.sin(windowAngle) * windowRadius
		setPropertyFromClass('openfl.Lib', 'application.window.x', math.floor(x))
		setPropertyFromClass('openfl.Lib', 'application.window.y', math.floor(y))
	end
end