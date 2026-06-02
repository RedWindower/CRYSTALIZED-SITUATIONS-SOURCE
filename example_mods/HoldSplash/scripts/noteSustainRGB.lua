---@diagnostic disable
luaDebugMode = false

local isHolding = {false, false, false, false}
local isOppHolding = {false, false, false, false}

function onCreatePost()
    addHaxeLibrary('RGBPalette', 'shaders')
        
    for i = 0, 3 do
        local isPixelStage = getPropertyFromClass('states.PlayState', 'isPixelStage');
        
        if isPixelStage == false then
            makeAnimatedLuaSprite('Anim'..i, 'noteSustain/holdCoverShader', 0, 0)
            addLuaSprite('Anim'..i, true)
            setObjectCamera('Anim'..i, 'hud')

            setProperty('Anim'..i..'.visible', false)

            addAnimationByPrefix('Anim'..i, 'Start', 'holdCoverStart')
            addAnimationByPrefix('Anim'..i, 'Loop', 'holdCover0')
            addAnimationByPrefix('Anim'..i, 'End', 'holdCoverEnd', 24, false)

            addOffset('Anim'..i, 'Loop', 10, -53)
            addOffset('Anim'..i, 'Start', 10, -45)
            addOffset('Anim'..i, 'End', 10, -50)

            makeAnimatedLuaSprite('OppAnim'..i, 'noteSustain/holdCoverShader', 0, 0)
            addLuaSprite('OppAnim'..i, true)
            setObjectCamera('OppAnim'..i, 'hud')

            setProperty('OppAnim'..i..'.visible', false)

            addAnimationByPrefix('OppAnim'..i, 'Start', 'holdCoverStart')
            addAnimationByPrefix('OppAnim'..i, 'Loop', 'holdCover0')
            addAnimationByPrefix('OppAnim'..i, 'End', 'holdCoverEnd', 24, false)

            addOffset('OppAnim'..i, 'Loop', 10, -53)
            addOffset('OppAnim'..i, 'Start', 12, -45)
            addOffset('OppAnim'..i, 'End', 10, -50)
        else
            makeAnimatedLuaSprite('Anim'..i, 'noteSustain/holdCoverPixel', 0, 0)
            addLuaSprite('Anim'..i, true)
            setObjectCamera('Anim'..i, 'hud')
            setProperty('Anim'..i..'.visible', false)
            setProperty('Anim'..i..'.antialiasing', false)
            scaleObject('Anim'..i, 7, 7)
            addAnimationByPrefix('Anim'..i, 'Loop', 'loop0')
            addAnimationByPrefix('Anim'..i, 'End', 'explode', 24, false)
            addOffset('Anim'..i, 'Loop', -792, -185)
            addOffset('Anim'..i, 'End', -792, -190)

            makeAnimatedLuaSprite('OppAnim'..i, 'noteSustain/holdCoverPixel', 0, 0)
            addLuaSprite('OppAnim'..i, true)
            setObjectCamera('OppAnim'..i, 'hud')
            setProperty('OppAnim'..i..'.visible', false)
            setProperty('OppAnim'..i..'.antialiasing', false)
            scaleObject('OppAnim'..i, 7, 7)
            addAnimationByPrefix('OppAnim'..i, 'Loop', 'loop0')
            addAnimationByPrefix('OppAnim'..i, 'End', 'explode', 24, false)
            addOffset('OppAnim'..i, 'Loop', -792, -185)
            addOffset('OppAnim'..i, 'End', -792, -190)
        end
    end
end

function onSongStart()
    for i = 0, 3 do
        runHaxeCode([[
            var PlayerSprite = game.modchartSprites.get('Anim]]..i..[[');
            var OpponentSprite = game.modchartSprites.get('OppAnim]]..i..[[');

            var playerStrum = game.playerStrums.members[]]..i..[[];
            var opponentStrum = game.opponentStrums.members[]]..i..[[];

            var coolShader:RGBPalette = new RGBPalette();
            var oppShader:RGBPalette = new RGBPalette();

            if (PlayerSprite != null) PlayerSprite.shader = coolShader.shader;
            if (OpponentSprite != null) OpponentSprite.shader = oppShader.shader;

            if (playerStrum != null && playerStrum.rgbShader != null) {
                coolShader.r = playerStrum.rgbShader.parent.r;
                coolShader.g = playerStrum.rgbShader.parent.g;
                coolShader.b = playerStrum.rgbShader.parent.b;
            } else if (playerStrum != null) {
                var colors:Array<FlxColor> = ClientPrefs.data.arrowRGB[]]..i..[[];
                coolShader.r = colors[0];
                coolShader.g = colors[1];
                coolShader.b = colors[2];
            }
            
            if (opponentStrum != null && opponentStrum.rgbShader != null) {
                oppShader.r = opponentStrum.rgbShader.parent.r;
                oppShader.g = opponentStrum.rgbShader.parent.g;
                oppShader.b = opponentStrum.rgbShader.parent.b;
            } else if (opponentStrum != null) {
                var colors:Array<FlxColor> = ClientPrefs.data.arrowRGB[]]..i..[[];
                oppShader.r = colors[0];
                oppShader.g = colors[1];
                oppShader.b = colors[2];
            }
        ]])
    end
end

function goodNoteHit(index, noteData, noteType, isSustainNote)
    if isSustainNote == true then
        setProperty('Anim'..noteData..'.visible', true)

        local dynamicHoldTime = math.max(0.15, (getPropertyFromClass('backend.Conductor', 'stepCrochet') / 1000) * 1.5)

        if not isHolding[noteData + 1] then
            isHolding[noteData + 1] = true
            playAnim('Anim'..noteData, 'Start', true)
            runTimer('transToLoop'..noteData, 0.04)
        end
        
        runTimer('holdtimer'..noteData, dynamicHoldTime)
        runTimer('holdsplash'..noteData, dynamicHoldTime + 0.3)
    end
end

function opponentNoteHit(index, noteData, noteType, isSustain)
    if isSustain then
        setProperty('OppAnim'..noteData..'.visible', true)
        
        local dynamicHoldTime = math.max(0.15, (getPropertyFromClass('backend.Conductor', 'stepCrochet') / 1000) * 1.5)

        if not isOppHolding[noteData + 1] then
            isOppHolding[noteData + 1] = true
            playAnim('OppAnim'..noteData, 'Start', true)
            runTimer('oppTransToLoop'..noteData, 0.04)
        end
        runTimer('oppholdtimer'..noteData, dynamicHoldTime)
        runTimer('oppholdsplash'..noteData, dynamicHoldTime)
    end
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'transToLoop0' then playAnim('Anim0', 'Loop', true) end
    if tag == 'transToLoop1' then playAnim('Anim1', 'Loop', true) end
    if tag == 'transToLoop2' then playAnim('Anim2', 'Loop', true) end
    if tag == 'transToLoop3' then playAnim('Anim3', 'Loop', true) end

    if tag == 'oppTransToLoop0' then playAnim('OppAnim0', 'Loop', true) end
    if tag == 'oppTransToLoop1' then playAnim('OppAnim1', 'Loop', true) end
    if tag == 'oppTransToLoop2' then playAnim('OppAnim2', 'Loop', true) end
    if tag == 'oppTransToLoop3' then playAnim('OppAnim3', 'Loop', true) end

    if tag == 'holdtimer0' then playAnim('Anim0', 'End') isHolding[1] = false end
    if tag == 'holdtimer1' then playAnim('Anim1', 'End') isHolding[2] = false end
    if tag == 'holdtimer2' then playAnim('Anim2', 'End') isHolding[3] = false end
    if tag == 'holdtimer3' then playAnim('Anim3', 'End') isHolding[4] = false end

    if tag == 'oppholdtimer0' then playAnim('OppAnim0', 'End') isOppHolding[1] = false end
    if tag == 'oppholdtimer1' then playAnim('OppAnim1', 'End') isOppHolding[2] = false end
    if tag == 'oppholdtimer2' then playAnim('OppAnim2', 'End') isOppHolding[3] = false end
    if tag == 'oppholdtimer3' then playAnim('OppAnim3', 'End') isOppHolding[4] = false end

    if tag == 'holdsplash0' then setProperty('Anim0.visible', false) end
    if tag == 'holdsplash1' then setProperty('Anim1.visible', false) end
    if tag == 'holdsplash2' then setProperty('Anim2.visible', false) end
    if tag == 'holdsplash3' then setProperty('Anim3.visible', false) end

    if tag == 'oppholdsplash0' then setProperty('OppAnim0.visible', false) end
    if tag == 'oppholdsplash1' then setProperty('OppAnim1.visible', false) end
    if tag == 'oppholdsplash2' then setProperty('OppAnim2.visible', false) end
    if tag == 'oppholdsplash3' then setProperty('OppAnim3.visible', false) end
end

function onUpdate(elapsed)
    for i = 0,3 do
        local notaAlpha = getPropertyFromGroup('playerStrums', i, 'alpha')
        local oppNotaAlpha = getPropertyFromGroup('opponentStrums', i, 'alpha')
        setProperty('Anim'..i..".alpha", notaAlpha)
        setProperty('OppAnim'..i..".alpha", oppNotaAlpha)
        setProperty('Anim'..i..".x", getPropertyFromGroup('playerStrums', i, 'x') + (getPropertyFromGroup('playerStrums', i, 'width') / 2) - (getProperty('Anim'..i..'.width') / 2))
        setProperty('Anim'..i..".y", getPropertyFromGroup('playerStrums', i, 'y') + (getPropertyFromGroup('playerStrums', i, 'height') / 2) - (getProperty('Anim'..i..'.height') / 2))
        setProperty('OppAnim'..i..".x", getPropertyFromGroup('opponentStrums', i, 'x') + (getPropertyFromGroup('opponentStrums', i, 'width') / 2) - (getProperty('OppAnim'..i..'.width') / 2))
        setProperty('OppAnim'..i..".y", getPropertyFromGroup('opponentStrums', i, 'y') + (getPropertyFromGroup('opponentStrums', i, 'height') / 2) - (getProperty('OppAnim'..i..'.height') / 2))
    end
end