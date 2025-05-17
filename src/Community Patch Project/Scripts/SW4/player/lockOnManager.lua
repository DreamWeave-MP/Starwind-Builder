local async = require 'openmw.async'
local camera = require 'openmw.camera'
local input = require 'openmw.input'
local nearby = require 'openmw.nearby'
local gameSelf = require 'openmw.self'
local types = require 'openmw.types'
local ui = require 'openmw.ui'
---@type openmw.util
local util = require 'openmw.util'

local ModInfo = require 'scripts.sw4.modinfo'
local CameraManager = nil

local CenterVector2 = util.vector2(0.5, 0.5)
local ZeroVector2 = util.vector2(0, 0)
local CamForwardCastVector = util.vector3(0, camera.getViewDistance(), 0)

--- TODO: Make a subscript function to reconstruct the vectors for the size remapping instead of reconstructing vectors on every call
--- expensive!
---@class LockOnManager
---@field TargetLockIcon string baseName of the texture file used for the lock-on icon
---@field TargetMinSize integer minimum size of the target lock icon
---@field TargetMaxSize integer maximum size of the target lock icon
---@field TargetMinDistance integer Distance from the target to the camera at which the target lock icon will be minimum size
---@field TargetMaxDistance integer Distance from the target to the camera at which the target lock icon will be maximum size
---@field TargetColorF util.color Color applied to the target icon when target has >= 100% health. Mixes with TargetColorVH below 100%.
---@field TargetColorVH util.color Color applied to the target icon when target has 60% - 80% health. Mixes with TargetColorH below 80%.
---@field TargetColorH util.color Color applied to the target icon when target has 40% - 60% health. Mixes with TargetColorW below 60%.
---@field TargetColorW util.color Color applied to the target icon when target has 20% - 40% health. Mixes with TargetColorVW below 40%.
---@field TargetColorVW util.color Color applied to the target icon when target has 0% - 20% health. Mixes with TargetColorD below 20%.
---@field TargetColorD util.color Color applied to the target icon when target has <= 0% health.
local LockOnManager = require 'Scripts.SW4.helper.protectedTable' ('SettingsGlobal' .. ModInfo.name .. 'LockOnGroup',
    ModInfo)

LockOnManager.state = {
    targetObject = nil,
    targetHealth = nil,
    lockOnMarker = nil,
    currentTexture = nil,
}

---@alias MarkerTransform util.vector3 info about the marker; z element is distance from camera, xy are normalized screenpos of target

---@class MarkerUpdateInfo
---@field doUpdate boolean? whether to redraw or not
---@field transform MarkerTransform Onscreen position to place the marker at

function LockOnManager.getLockOnFileName(baseName)
    return ('textures/sw4/crosshair/%s.dds'):format(baseName)
end

---@param markerUpdateData MarkerUpdateInfo
function LockOnManager:updateMarker(markerUpdateData)
    local element = self.getLockOnMarker()
    assert(element, 'LockOnManager: Failed to locate lock on marker to set its position!')

    -- print(self:getIconColor())
    local elementSize = self:getIconSize(markerUpdateData.transform.z)
    element.layout.props.size = util.vector2(elementSize, elementSize)
    element.layout.props.color = self:getIconColor()
    element.layout.props.relativePosition = markerUpdateData.transform.xy

    if LockOnManager.TargetLockIcon ~= LockOnManager.state.currentTexture then
        LockOnManager.state.currentTexture = LockOnManager.getLockOnFileName(LockOnManager.TargetLockIcon)
        element.layout.props.resource = ui.texture { path = LockOnManager.state.currentTexture }
    end

    if markerUpdateData.doUpdate ~= true then return end
    element:update()
end

function LockOnManager.getLockOnMarker()
    return LockOnManager.state.lockOnMarker
end

function LockOnManager.getTargetObject()
    return LockOnManager.state.targetObject
end

--- Returns false if the target doesn't exist, or isn't an NPC/Creature
---@return boolean isActor
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

    return visibility
end

--- Depending on whether it already exists or not, creates the lock on marker
--- or simply toggles its visibility
---@return nil
function LockOnManager.toggleLockOnMarkerDisplay()
    local marker = LockOnManager.getLockOnMarker()

    if not marker then
        LockOnManager.state.currentTexture = LockOnManager.getLockOnFileName(LockOnManager.TargetLockIcon)
        LockOnManager.state.lockOnMarker = ui.create {
            layer = 'HUD',
            type = ui.TYPE.Image,
            props = {
                anchor = CenterVector2,
                relativePosition = ZeroVector2,
                size = ZeroVector2,
                resource = ui.texture { path = LockOnManager.state.currentTexture },
                visible = false,
            },
        }
    else
        LockOnManager.setMarkerVisibility(false)
    end
end

--- Responds to the 'SW4_TargetLock' action, engaging or disengaging target locking as appropriate
--- Toggle type action, but, maybe we could make it a hold??
function LockOnManager.lockOnHandler(state)
    if not state then return end

    if LockOnManager.state.targetObject then
        LockOnManager.state.targetObject = nil
        LockOnManager.state.targetHealth = nil
        LockOnManager.toggleLockOnMarkerDisplay()
        return
    end

    local camTransform = CamHelper.getCameraTransform()
    local castToPos = camTransform.position + camTransform.rotation * CamForwardCastVector

    local result = nearby.castRay(camTransform.position, castToPos, { ignore = { gameSelf.object, } })

    if not result.hit or not result.hitObject then return end
    local isActor = types.Actor.objectIsInstance(result.hitObject)
    if isActor and types.Actor.isDead(result.hitObject) then return end

    LockOnManager.state.targetObject = result.hitObject

    if isActor then
        LockOnManager.state.targetHealth = result.hitObject.type.stats.dynamic.health(result.hitObject)
    end
end

--- sets marker visibility. Always triggers a redraw
---@param state boolean whether or not the marker should be visible
---@return boolean? changed whether or not the state actually updated (due to the marker not existing)
function LockOnManager.setMarkerVisibility(state)
    local marker = LockOnManager.getLockOnMarker()
    if not marker then return end
    assert(CameraManager)

    marker.layout.props.visible = state
    CameraManager.getState().isLockedOn = state
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
        LockOnManager.state.targetObject = nil
        return true
    end
end

--- Given both the old and new ranges, map a numeric value from one to the other and round it.
---@param inputValue number
---@param oldRange util.vector2
---@param newRange util.vector2
local function remapFromRange(inputValue, oldRange, newRange)
    return util.round(
        math.max(
            math.min(
                util.remap(
                    inputValue,
                    oldRange.x,
                    oldRange.y,
                    newRange.x,
                    newRange.y
                ),
                newRange.y
            ),
            newRange.x
        )
    )
end

---@param distanceFromCamera number distance in todd units from targeted object to the camera
---@return number iconSize rounded icon size, remapped from the camera distance range to the size range
function LockOnManager:getIconSize(distanceFromCamera)
    local markerSizeRange = util.vector2(self.TargetMinSize, self.TargetMaxSize)
    local markerDistanceRange = util.vector2(self.TargetMinDistance, self.TargetMaxDistance)
    return remapFromRange(distanceFromCamera, markerDistanceRange, markerSizeRange)
end

function LockOnManager:getIconColor()
    --- Figure out which of the existing log functions is most appropriate to use when this happens, as it shouldn't
    if self.state.targetHealth == nil then
        return self.TargetColorD
    end

    local normalizedHealth = self.state.targetHealth.current / self.state.targetHealth.base

    if normalizedHealth >= 1.0 then
        return self.TargetColorF
    elseif normalizedHealth < 0.0 then
        return self.TargetColorD
    end

    local targetColorMin, targetColorMax

    if normalizedHealth < 1.0 and normalizedHealth >= 0.8 then
        targetColorMin = self.TargetColorVH:asRgb()
        targetColorMax = self.TargetColorF:asRgb()
    elseif normalizedHealth < 0.8 and normalizedHealth >= 0.6 then
        targetColorMin = self.TargetColorH:asRgb()
        targetColorMax = self.TargetColorVH:asRgb()
    elseif normalizedHealth < 0.6 and normalizedHealth >= 0.4 then
        targetColorMin = self.TargetColorW:asRgb()
        targetColorMax = self.TargetColorH:asRgb()
    elseif normalizedHealth < 0.4 and normalizedHealth >= 0.2 then
        targetColorMin = self.TargetColorVW:asRgb()
        targetColorMax = self.TargetColorW:asRgb()
    elseif normalizedHealth < 0.2 and normalizedHealth >= 0.0 then
        targetColorMin = self.TargetColorD:asRgb()
        targetColorMax = self.TargetColorVW:asRgb()
    end

    local colorMix = {}
    colorMix[#colorMix + 1] = util.remap(normalizedHealth, 0.0, 1.0, targetColorMin.x, targetColorMax.x)
    colorMix[#colorMix + 1] = util.remap(normalizedHealth, 0.0, 1.0, targetColorMin.y, targetColorMax.y)
    colorMix[#colorMix + 1] = util.remap(normalizedHealth, 0.0, 1.0, targetColorMin.z, targetColorMax.z)

    return util.color.rgb(colorMix[1], colorMix[2], colorMix[3])
end

---@param dt number deltaTime
---@param managers table<string, any> direct access to all SW4 subsystems
function LockOnManager.onFrame(dt, managers)
    local targetIsActor = LockOnManager.targetIsActor()
    LockOnManager.checkForDeadTarget(targetIsActor)

    if not CameraManager then CameraManager = managers.Camera end

    local targetObject = LockOnManager.getTargetObject()
    local camState = CameraManager.getState()

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
            CameraManager:trackTargetUsingViewport(targetObject, normalizedPos)
            LockOnManager:updateMarker {
                transform = normalizedPos,
                doUpdate = true,
            }
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
