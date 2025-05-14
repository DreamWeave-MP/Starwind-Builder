local async = require 'openmw.async'
local camera = require 'openmw.camera'
local input = require 'openmw.input'
local nearby = require 'openmw.nearby'
local self = require 'openmw.self'
local types = require 'openmw.types'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local CenterVector2 = util.vector2(0.5, 0.5)
local ZeroVector2 = util.vector2(0, 0)
local CamForwardCastVector = util.vector3(0, camera.getViewDistance(), 0)

local LockOnManager = {
    targetObject = nil,
    lockOnMarker = nil,
    markerDefaultSize = util.vector2(128, 128),
    markerDefaultPath = 'textures/target.dds',
}

function LockOnManager.setElementPosition(element, newPosition)
    element.layout.props.relativePosition = newPosition
    element:update()
end

function LockOnManager.getLockOnMarker()
    return LockOnManager.lockOnMarker
end

function LockOnManager.getTargetObject()
    return LockOnManager.targetObject
end

function LockOnManager.targetIsActor()
    local target = LockOnManager.getTargetObject()
    if not target then return false end

    return types.Actor.objectIsInstance(target)
end

function LockOnManager.getMarkerVisibility()
    local marker = LockOnManager.getLockOnMarker()
    if marker == nil then return false end

    local visibility = true

    if marker.layout.props.visible ~= nil then
        visibility = marker.layout.props.visible
    end

    print('marker visibility is:', visibility)
    return visibility
end

--- Depending on whether it already exists or not, creates the lock on marker
--- or simply toggles its visibility
---@return nil
function LockOnManager.toggleLockOnMarkerDisplay()
    local marker = LockOnManager.getLockOnMarker()

    if not marker then
        LockOnManager.lockOnMarker = ui.create {
            layer = 'HUD',
            type = ui.TYPE.Image,
            props = {
                anchor = CenterVector2,
                relativePosition = ZeroVector2,
                resource = ui.texture { path = LockOnManager.markerDefaultPath },
                size = LockOnManager.markerDefaultSize,
                visible = false,
            },
        }
    else
        LockOnManager.setMarkerVisibility(false)
    end
end

function LockOnManager.trackTargetUsingViewport(targetObject, normalizedPos)
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

    local maxPitch = math.rad(89)
    local newPitch = math.max(-maxPitch, math.min(maxPitch, camera.getPitch() - pitchDifference))

    camera.setYaw(camera.getYaw() + yawDifference)
    camera.setPitch(newPitch)

    if camera.getMode() == camera.MODE.FirstPerson then
        self.controls.pitchChange = pitchDifference - self.rotation:getPitch()
    end
    print(yawDifference)
    self.controls.yawChange = yawDifference

    return yawDifference, pitchDifference
end

--- Responds to the 'SW4_TargetLock' action, engaging or disengaging target locking as appropriate
--- Toggle type action, but, maybe we could make it a hold??
function LockOnManager.lockOnHandler(state)
    if not state then return end

    if LockOnManager.targetObject then
        LockOnManager.targetObject = nil
        LockOnManager.toggleLockOnMarkerDisplay()
        return
    end

    local camTransform = CamHelper.getCameraTransform()
    local castToPos = camTransform.position + camTransform.rotation * CamForwardCastVector

    local result = nearby.castRay(camTransform.position, castToPos, { ignore = { self.object, } })

    if not result.hit or not result.hitObject then return end
    if types.Actor.objectIsInstance(result.hitObject) and types.Actor.isDead(result.hitObject) then return end

    LockOnManager.targetObject = result.hitObject

    local pitchDiff = self.rotation:getPitch() - camera.getPitch()
    self.controls.pitchChange = pitchDiff
end

---@param state boolean whether or not the marker should be visible
---@return boolean? changed whether or not the state actually updated (due to the marker not existing)
function LockOnManager.setMarkerVisibility(state)
    local marker = LockOnManager.getLockOnMarker()
    if not marker then return end

    marker.layout.props.visible = state
    marker:update()
    return true
end

---@param targetIsActor boolean whether or not the target is an actor
---@return boolean? updated whether or not the marker was hidden due to the target being dead
function LockOnManager.checkForDeadTarget(targetIsActor)
    local targetObject = LockOnManager.getTargetObject()

    if not targetObject or not targetIsActor then return end
    if not targetObject.type.isDead(targetObject) then return end

    if LockOnManager.setMarkerVisibility(false) then
        LockOnManager.targetObject = nil
        return true
    end
end

---@param dt number deltaTime
---@param managers table<string, any> direct access to all SW4 subsystems
function LockOnManager.onFrame(dt, managers)
    local targetIsActor = LockOnManager.targetIsActor()
    LockOnManager.checkForDeadTarget(targetIsActor)

    local targetObject = LockOnManager.getTargetObject()
    local camState = managers.Camera.getState()

    camState.canDoLockOn = targetObject and (
        (targetIsActor and camState.isWielding)
    --or (not targetIsActor and not isWielding)
    )

    local markerExists = LockOnManager.getLockOnMarker() ~= nil
    local markerIsVisible = LockOnManager.getMarkerVisibility()

    if camState.canDoLockOn then
        assert(targetObject)
        if not markerExists then
            LockOnManager.toggleLockOnMarkerDisplay()
        elseif not markerIsVisible then
            LockOnManager.setMarkerVisibility(true)
        end

        local normalizedPos = CamHelper.objectIsOnscreen(targetObject, not types.NPC.objectIsInstance(targetObject))

        if normalizedPos then
            LockOnManager.setElementPosition(LockOnManager.getLockOnMarker(),
                util.vector2(normalizedPos.x, normalizedPos.y))
            LockOnManager.trackTargetUsingViewport(targetObject, normalizedPos)
            -- LockOnManager.setMarkerVisibility(true)
            camera.showCrosshair(false)
        else
            LockOnManager.setMarkerVisibility(false)
            camera.showCrosshair(true)
        end
    else
        if markerIsVisible then
            LockOnManager.setMarkerVisibility(false)
            camera.showCrosshair(true)
        end
    end

    return camState.canDoLockOn
end

input.registerActionHandler('SW4_TargetLock', async:callback(LockOnManager.lockOnHandler))

return function()
    return LockOnManager
end
