local camera = require 'openmw.camera'
local gameSelf = require 'openmw.self'
local input = require 'openmw.input'
local util = require 'openmw.util'

local ModInfo = require 'Scripts.SW4.modinfo'

---@class CameraManager
local CameraManager = require 'Scripts.SW4.helper.protectedTable' (
    'SettingsGlobal' .. ModInfo.name .. 'CoreGroup',
    ModInfo)

---@class CameraManagerState
---@field yawDelta number yaw change between current and last frame
---@field yawThisFrame number
---@field yawLastFrame number
---@field pitchDelta number yaw change between current and last frame
---@field pitchThisFrame number
---@field pitchLastFrame number
---@field isLockedOn boolean
---@field isWielding boolean whether or not the player has a weapon or spell drawn
CameraManager.state = {
    yawDelta = 0,
    yawThisFrame = 0,
    yawLastFrame = 0,

    pitchDelta = 0,
    pitchThisFrame = 0,
    pitchLastFrame = 0,

    isLockedOn = false,
    isWielding = false,
    canDoLockOn = false,
}

-- function CameraManager.getself.state.)
--     return state
-- end

function CameraManager:updateTransform()
    self.state.yawThisFrame = camera.getYaw()
    self.state.pitchThisFrame = camera.getPitch()
    self.state.isWielding = gameSelf.type.getStance(gameSelf) ~= gameSelf.type.STANCE.Nothing
end

function CameraManager.isMoving()
    return gameSelf.controls.sideMovement ~= 0 or gameSelf.controls.movement ~= 0
end

function CameraManager.isThirdPerson()
    return camera.getMode() ~= camera.MODE.FirstPerson
end

function CameraManager:setLockedOn(state)
    self.state.isLockedOn = state
end

--- Override yawChange from mouseInput
---@param dt number deltaTime
---@param managers table<string, any> Direct access to all SW4 subsystems
function CameraManager:onFrameBegin(dt, managers)
    CameraManager:updateTransform()

    --- Override yawChange from mouse inputs
    if CameraManager.isMoving() then
        gameSelf.controls.yawChange = 0
    end

    -- Override first-person pitch change inputs (should really only be while locked on but whatever)
    if self.state.isLockedOn then
        gameSelf.controls.pitchChange = 0
    end
end

--- Tracks yaw and pitch change between frames
function CameraManager:updateDelta()
    if self.state.yawThisFrame ~= 0 then
        self.state.yawDelta = self.state.yawThisFrame - self.state.yawLastFrame
    end

    if self.state.pitchThisFrame ~= 0 then
        self.state.pitchDelta = self.state.pitchThisFrame - self.state.pitchLastFrame
    end
end

function CameraManager:trackTargetUsingViewport(targetObject, normalizedPos)
    if not targetObject then return end

    -- Desired screen position (center of the screen)
    local desiredScreenPos = util.vector2(0.5, 0.5)

    -- Convert the current and desired screen positions to world-space directions
    local currentWorldDir = camera.viewportToWorldVector(normalizedPos.xy)
    local desiredWorldDir = camera.viewportToWorldVector(desiredScreenPos)

    -- Normalize the directions
    currentWorldDir = currentWorldDir:normalize()
    desiredWorldDir = desiredWorldDir:normalize()

    -- Calculate the yaw and pitch differences
    local yawDifference = math.atan2(currentWorldDir.x, currentWorldDir.y) -
        math.atan2(desiredWorldDir.x, desiredWorldDir.y)

    local pitchDifference = math.asin(currentWorldDir.z) - math.asin(desiredWorldDir.z)

    -- Normalize yawDifference to the range [-pi, pi]
    if yawDifference > math.pi then
        yawDifference = yawDifference - 2 * math.pi
    elseif yawDifference < -math.pi then
        yawDifference = yawDifference + 2 * math.pi
    end

    camera.setYaw(util.normalizeAngle(camera.getYaw() + yawDifference))
    camera.setPitch(util.normalizeAngle(camera.getPitch() - pitchDifference))

    gameSelf.controls.yawChange = yawDifference
    gameSelf.controls.pitchChange = -pitchDifference

    return yawDifference, pitchDifference
end

---@param dt number deltaTime
---@param managers table<string, any> Direct access to all SW4 subsystems
function CameraManager:onFrameEnd(dt, managers)
    CameraManager:updateDelta()

    local sideMovement = gameSelf.controls.sideMovement
    local forwardMovement = gameSelf.controls.movement
    local isPressingRun = input.getBooleanActionValue('Run')
    local targetObject = managers.LockOn.getTargetObject()

    -- If not currently locked or not able to lock, and moving horizontally, turn on behalf of the player
    if not isPressingRun and (not self.state.canDoLockOn or not targetObject) and sideMovement ~= 0 then
        gameSelf.controls.yawChange = math.rad(sideMovement * 180 * dt)
    end

    -- Only turn when not moving forward or backward, so that you don't actually strafe around.
    if not isPressingRun and not self.state.isWielding and (sideMovement ~= 0 and forwardMovement == 0) then
        gameSelf.controls.sideMovement = 0
        camera.setYaw(camera.getYaw() + gameSelf.controls.yawChange)
    end

    -- override the behavior of the `Run` actionHandler, so it only controls strafing
    if input.getBooleanActionValue('Run') then
        gameSelf.controls.run = not gameSelf.controls.run
    end

    -- No vertical camera movement, unless the player
    if not self.state.isWielding then
        camera.setPitch(0)
    end

    --- Move the player along with the camera as long as they're not in some self.state.where that's already happening
    if self.state.yawDelta ~= 0 and not CameraManager.isMoving() and not self.state.isWielding then
        if CameraManager.isThirdPerson() then
            gameSelf.controls.yawChange = self.state.yawDelta
        end
        self.state.yawDelta = 0
    end

    self.state.yawLastFrame = self.state.yawThisFrame
    self.state.pitchLastFrame = self.state.pitchThisFrame
end

return function()
    return CameraManager
end
