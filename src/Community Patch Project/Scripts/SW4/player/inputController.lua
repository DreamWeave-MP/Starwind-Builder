local async = require 'openmw.async'
local core = require 'openmw.core'
local gameSelf = require 'openmw.self'
local input = require 'openmw.input'
local storage = require 'openmw.storage'
local types = require 'openmw.types'
local util = require 'openmw.util'

local Player = types.Player
local I = require 'openmw.interfaces'

local ModInfo = require 'Scripts.SW4.modinfo'

local SW4InputSectionName = 'SettingsGlobal' .. ModInfo.name .. 'MoveTurnGroup'
local SW4InputSection = storage.globalSection(SW4InputSectionName)

local EngineMovementSettings = storage.playerSection('SettingsOMWControls')

-- Setting-related movement state
---@class InputManager:ProtectedTable
---@field Enabled boolean
---@field MoveRampUpTimeMax number
---@field MoveRampUpMinSpeed number
---@field MoveRampUpMaxSpeed number
---@field MoveBackRampUpTimeMax number
---@field MoveBackRampUpMinSpeed number
---@field MoveBackRampUpMaxSpeed number
---@field MoveRampDownTimeMax number
---@field MoveSpeedPeak number
---@field TurnRampTimeMax number
---@field TurnDegreesPerSecondMax number
---@field TurnDegreesPerSecondMin number
---@field SideMovementMaxSpeed number
local InputManager = I.StarwindVersion4ProtectedTable.new {
    modName = ModInfo.name,
    logPrefix = ModInfo.logPrefix,
    inputGroupName = SW4InputSectionName,
}

local Enabled,
MoveRampUpTimeMax,
MoveRampUpMinSpeed,
MoveRampUpMaxSpeed,
MoveBackRampUpTimeMax,
MoveBackRampUpMinSpeed,
MoveBackRampUpMaxSpeed,
MoveRampDownTimeMax,
MoveSpeedPeak,
TurnRampTimeMax,
TurnDegreesPerSecondMax,
TurnDegreesPerSecondMin,
SideMovementMaxSpeed,
newMax

-- non-setting movement state
local CurrentForwardRampTime = 0.0
local CurrentTurnRampTime = 0.0
local autoMove = false
local attemptToJump = false
local movementControlsOverridden = false
local didPressRun = false

---@type ManagementStore
local GlobalManagement

--- Updates local variables corresponding to internal setting values
function InputManager:updateSettings()
    MoveRampUpTimeMax = self.MoveRampUpTimeMax

    MoveRampUpMinSpeed = self.MoveRampUpMinSpeed
    MoveRampUpMaxSpeed = self.MoveRampUpMaxSpeed

    MoveBackRampUpTimeMax = self.MoveBackRampUpTimeMax

    MoveBackRampUpMinSpeed = self.MoveBackRampUpMinSpeed
    MoveBackRampUpMaxSpeed = self.MoveBackRampUpMaxSpeed

    MoveRampDownTimeMax = self.MoveRampDownTimeMax

    MoveSpeedPeak = self.MoveSpeedPeak
    newMax = MoveSpeedPeak

    TurnRampTimeMax = self.TurnRampTimeMax

    TurnDegreesPerSecondMax = self.TurnDegreesPerSecondMax
    TurnDegreesPerSecondMin = self.TurnDegreesPerSecondMin

    SideMovementMaxSpeed = self.SideMovementMaxSpeed

    Enabled = self.Enabled
    I.Controls.overrideMovementControls(Enabled)
end

SW4InputSection:subscribe(async:callback(function()
    InputManager:updateSettings()
end))

local function controlsAllowed()
    return not core.isWorldPaused()
        and Player.getControlSwitch(gameSelf, Player.CONTROL_SWITCH.Controls)
        and not I.UI.getMode()
end

function InputManager:processMovement(dt)
    if not controlsAllowed() then return end

    local movement = input.getRangeActionValue('MoveForward') - input.getRangeActionValue('MoveBackward')
    local sideMovement = input.getRangeActionValue('MoveRight') - input.getRangeActionValue('MoveLeft')
    local run = EngineMovementSettings:get('alwaysRun')
    local strafeInsteadOfTurn = input.getBooleanActionValue('Run') or GlobalManagement.LockOn.getMarkerVisibility()
    local hasSpeederEquipped = GlobalManagement.MountFunctions.hasSpeederEquipped()

    if movement ~= 0 then
        autoMove = false
    elseif autoMove then
        movement = 1
    end

    if sideMovement == 0 then
        CurrentTurnRampTime = 0.0
    end

    --- When the player first starts running, bring their ramp down to match where they were before
    if strafeInsteadOfTurn and not didPressRun then
        CurrentForwardRampTime = CurrentForwardRampTime * MoveRampUpMaxSpeed
    end

    --- Don't ramp, walk, or strafe on a speeder
    if hasSpeederEquipped then
        CurrentForwardRampTime = 0.0
        run = true
    elseif movement == 1 or autoMove then
        CurrentForwardRampTime = math.min(MoveRampUpTimeMax, CurrentForwardRampTime + dt)

        newMax = strafeInsteadOfTurn and MoveSpeedPeak or MoveRampUpMaxSpeed

        movement = util.remap(CurrentForwardRampTime, 0.0, MoveRampUpTimeMax, MoveRampUpMinSpeed, newMax) *
            (movement < 0 and -1 or 1)
    elseif movement == -1 then
        CurrentForwardRampTime = math.min(MoveBackRampUpTimeMax, CurrentForwardRampTime + dt)

        newMax = MoveBackRampUpMaxSpeed

        movement = util.remap(CurrentForwardRampTime, 0.0, MoveBackRampUpTimeMax, MoveBackRampUpMinSpeed,
            MoveBackRampUpMaxSpeed)
    else
        CurrentForwardRampTime = math.min(
            math.max(
                0.0, CurrentForwardRampTime - dt
            ),
            MoveRampDownTimeMax)

        movement = util.remap(CurrentForwardRampTime, 0.0, MoveRampDownTimeMax, 0.0, newMax)
            * (gameSelf.controls.movement < 0 and -1 or 1)
    end

    gameSelf.controls.movement = movement

    if strafeInsteadOfTurn and not hasSpeederEquipped then
        gameSelf.controls.sideMovement = math.min(
                math.abs(sideMovement), SideMovementMaxSpeed
            ) *
            (sideMovement < 0 and -1 or 1)

        gameSelf.controls.yawChange = 0
    else
        CurrentTurnRampTime = math.min(TurnRampTimeMax, CurrentTurnRampTime + dt)

        local turnSpeed = util.round(
            util.remap(CurrentTurnRampTime,
                0.0,
                TurnRampTimeMax,
                TurnDegreesPerSecondMin,
                TurnDegreesPerSecondMax)
        )

        gameSelf.controls.yawChange = math.rad(sideMovement * turnSpeed * dt)
        gameSelf.controls.sideMovement = 0
    end

    gameSelf.controls.run = run
    gameSelf.controls.jump = attemptToJump
    didPressRun = strafeInsteadOfTurn
    attemptToJump = false

    if not EngineMovementSettings:get('toggleSneak') then
        gameSelf.controls.sneak = input.getBooleanActionValue('Sneak')
    end
end

local function movementAllowed()
    return controlsAllowed() and not movementControlsOverridden
end

input.registerTriggerHandler('Jump', async:callback(function()
    if not movementAllowed() then return end

    attemptToJump = Player.getControlSwitch(gameSelf, Player.CONTROL_SWITCH.Jumping)
end))

input.registerTriggerHandler('ToggleSneak', async:callback(function()
    if not movementAllowed() or not EngineMovementSettings:get('toggleSneak') then return end

    gameSelf.controls.sneak = not gameSelf.controls.sneak
end))

input.registerTriggerHandler('AlwaysRun', async:callback(function()
    if not movementAllowed() then return end

    EngineMovementSettings:set('alwaysRun', not EngineMovementSettings:get('alwaysRun'))
end))

input.registerTriggerHandler('AutoMove', async:callback(function()
    if not movementAllowed() then return end

    autoMove = not autoMove
end))

function InputManager:onFrameBegin(dt)
end

function InputManager:onFrame(dt)
    if not Enabled then return end
    self:processMovement(dt)
end

function InputManager:onFrameEnd(dt)
end

---@param managementStore ManagementStore
---@return InputManager
return function(managementStore)
    assert(managementStore)
    GlobalManagement = managementStore
    InputManager:updateSettings()
    return InputManager
end
