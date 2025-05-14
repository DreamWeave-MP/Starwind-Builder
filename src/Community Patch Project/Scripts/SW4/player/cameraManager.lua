local camera = require 'openmw.camera'
local input = require 'openmw.input'
local self = require 'openmw.self'

local CameraManager = {
    yawDelta = 0,
    yawThisFrame = 0,
    yawLastFrame = 0,

    pitchDelta = 0,
    pitchThisFrame = 0,
    pitchLastFrame = 0,

    isWielding = false,
}

function CameraManager.updateTransform()
    CameraManager.yawThisFrame = camera.getYaw()
    CameraManager.pitchThisFrame = camera.getPitch()
    CameraManager.isWielding = self.type.getStance(self) ~= self.type.STANCE.Nothing
end

function CameraManager.isMoving()
    return self.controls.sideMovement ~= 0 or self.controls.movement ~= 0
end

function CameraManager.isThirdPerson()
    return camera.getMode() ~= camera.MODE.FirstPerson
end

--- Override yawChange from mouseInput
---@param dt number deltaTime
function CameraManager.onFrameBegin(dt)
    CameraManager.updateTransform()

    --- Override yawChange from mouse inputs
    if CameraManager.isMoving() then
        self.controls.yawChange = 0
    end
end

function CameraManager.updateDelta()
    if CameraManager.yawThisFrame ~= 0 then
        CameraManager.yawDelta = CameraManager.yawThisFrame - CameraManager.yawLastFrame
    end

    if CameraManager.pitchThisFrame ~= 0 then
        CameraManager.pitchDelta = CameraManager.pitchThisFrame - CameraManager.pitchLastFrame
    end
end

---@param dt number deltaTime
---@param targetObject any Lock-on target
function CameraManager.onFrameEnd(dt, targetObject)
    CameraManager.updateDelta()

    local sideMovement = self.controls.sideMovement
    local forwardMovement = self.controls.movement
    local isPressingRun = input.getBooleanActionValue('Run')
    local canDoLockOn = false

    -- If not currently locked or not able to lock, and moving horizontally, turn on behalf of the player
    if not isPressingRun and (not canDoLockOn or not targetObject) and sideMovement ~= 0 then
        self.controls.yawChange = math.rad(sideMovement * 180 * dt)
    end

    -- Only turn when not moving forward or backward, so that you don't actually strafe around.
    if not isPressingRun and not CameraManager.isWielding and (sideMovement ~= 0 and forwardMovement == 0) then
        self.controls.sideMovement = 0
        camera.setYaw(camera.getYaw() + self.controls.yawChange)
    end

    -- override the behavior of the `Run` actionHandler, so it only controls strafing
    if input.getBooleanActionValue('Run') then
        self.controls.run = not self.controls.run
    end

    -- No vertical camera movement, unless the player
    if not CameraManager.isWielding then
        camera.setPitch(0)
    end

    --- Move the player along with the camera as long as they're not in some state where that's already happening
    if CameraManager.yawDelta ~= 0 and not CameraManager.isMoving() and not CameraManager.isWielding then
        if CameraManager.isThirdPerson() then
            self.controls.yawChange = CameraManager.yawDelta
        end
        CameraManager.yawDelta = 0
    end

    CameraManager.yawLastFrame = CameraManager.yawThisFrame
    CameraManager.pitchLastFrame = CameraManager.pitchThisFrame
end

return function()
    return CameraManager
end
