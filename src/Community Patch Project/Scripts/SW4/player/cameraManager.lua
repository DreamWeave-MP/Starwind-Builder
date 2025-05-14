local camera = require 'openmw.camera'
local input = require 'openmw.input'
local self = require 'openmw.self'

local ModInfo = require 'Scripts.SW4.modinfo'

---@class CameraManagerState
---@field yawDelta number yaw change between current and last frame
---@field yawThisFrame number
---@field yawLastFrame number
---@field pitchDelta number yaw change between current and last frame
---@field pitchThisFrame number
---@field pitchLastFrame number
---@field isWielding boolean whether or not the player has a weapon or spell drawn
local state = {
    yawDelta = 0,
    yawThisFrame = 0,
    yawLastFrame = 0,

    pitchDelta = 0,
    pitchThisFrame = 0,
    pitchLastFrame = 0,
    isWielding = false,
    canDoLockOn = false,
}

local CameraManager = require 'Scripts.SW4.helper.protectedTable' (
    'SettingsGlobal' .. ModInfo.name .. 'CameraMovementPage',
    ModInfo)

function CameraManager.getState()
    return state
end

function CameraManager.updateTransform()
    state.yawThisFrame = camera.getYaw()
    state.pitchThisFrame = camera.getPitch()
    state.isWielding = self.type.getStance(self) ~= self.type.STANCE.Nothing
end

function CameraManager.isMoving()
    return self.controls.sideMovement ~= 0 or self.controls.movement ~= 0
end

function CameraManager.isThirdPerson()
    return camera.getMode() ~= camera.MODE.FirstPerson
end

--- Override yawChange from mouseInput
---@param dt number deltaTime
---@param managers table<string, any> Direct access to all SW4 subsystems
function CameraManager.onFrameBegin(dt, managers)
    CameraManager.updateTransform()

    --- Override yawChange from mouse inputs
    if CameraManager.isMoving() then
        self.controls.yawChange = 0
    end
end

function CameraManager.updateDelta()
    if state.yawThisFrame ~= 0 then
        state.yawDelta = state.yawThisFrame - state.yawLastFrame
    end

    if state.pitchThisFrame ~= 0 then
        state.pitchDelta = state.pitchThisFrame - state.pitchLastFrame
    end
end

---@param dt number deltaTime
---@param managers table<string, any> Direct access to all SW4 subsystems
function CameraManager.onFrameEnd(dt, managers)
    CameraManager.updateDelta()

    local sideMovement = self.controls.sideMovement
    local forwardMovement = self.controls.movement
    local isPressingRun = input.getBooleanActionValue('Run')
    local targetObject = managers.LockOn.getTargetObject()

    -- If not currently locked or not able to lock, and moving horizontally, turn on behalf of the player
    if not isPressingRun and (not state.canDoLockOn or not targetObject) and sideMovement ~= 0 then
        self.controls.yawChange = math.rad(sideMovement * 180 * dt)
    end

    -- Only turn when not moving forward or backward, so that you don't actually strafe around.
    if not isPressingRun and not state.isWielding and (sideMovement ~= 0 and forwardMovement == 0) then
        self.controls.sideMovement = 0
        camera.setYaw(camera.getYaw() + self.controls.yawChange)
    end

    -- override the behavior of the `Run` actionHandler, so it only controls strafing
    if input.getBooleanActionValue('Run') then
        self.controls.run = not self.controls.run
    end

    -- No vertical camera movement, unless the player
    if not state.isWielding then
        camera.setPitch(0)
    end

    --- Move the player along with the camera as long as they're not in some state where that's already happening
    if state.yawDelta ~= 0 and not CameraManager.isMoving() and not state.isWielding then
        if CameraManager.isThirdPerson() then
            self.controls.yawChange = state.yawDelta
        end
        state.yawDelta = 0
    end

    state.yawLastFrame = state.yawThisFrame
    state.pitchLastFrame = state.pitchThisFrame
end

return function()
    return CameraManager
end
