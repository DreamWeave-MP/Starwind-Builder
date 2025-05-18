local async = require 'openmw.async'
local camera = require 'openmw.camera'
local input = require 'openmw.input'
local util = require 'openmw.util'
local ui = require 'openmw.ui'

local ModInfo = require 'scripts.sw4.modinfo'

local I = require 'openmw.interfaces'

---@type ManagementStore
local GlobalManagement

---@class CursorController
---@field StartFromCenter boolean whether or not the cursor starts from the center of the screen each time it is brought back up
---@field TargetFlickThreshold number Length of continuous movement required to switch targets
---@field Sensitivity number input sensitivity (multiplier)
---@field CursorSize number integer size of the icon
---@field XAnchor number float X-axis anchor
---@field YAnchor number float Y-axis anchor
local CursorController = I.StarwindVersion4ProtectedTable.new {
    modName = ModInfo.name,
    logPrefix = ModInfo.logPrefix,
    inputGroupName = 'SettingsGlobal' .. ModInfo.name .. 'CursorGroup',
}

function CursorController:startPos()
    return ui.screenSize() / 2
end

CursorController.state = {
    cursorPos = CursorController:startPos(),
    changeThisFrame = util.vector2(0, 0),
    cumulativeXMove = 0,
    flickTriggered = false,
}

local Cursor = ui.create {
    layer = 'HUD',
    type = ui.TYPE.Image,
    props = {
        size = util.vector2(CursorController.CursorSize, CursorController.CursorSize),
        anchor = util.vector2(CursorController.XAnchor, CursorController.YAnchor),
        resource = ui.texture { path = 'textures/target.dds' },
        position = CursorController:startPos(),
        visible = false,
    }
}

function CursorController.getCursorIcon(baseName)
    return ('textures/sw4/cursor/%s.dds'):format(baseName)
end

function CursorController:getCursor()
    return Cursor
end

function CursorController:onFrameBegin(dt)
    local ScreenSize = ui.screenSize()

    local changeThisFrame = util.vector2(input.getMouseMoveX(), input.getMouseMoveY()) * self.Sensitivity
    local markerVisible = GlobalManagement.LockOn.getMarkerVisibility()

    self.state.changeThisFrame = changeThisFrame

    self.state.cursorPos = util.vector2(
        util.clamp(self.state.cursorPos.x + changeThisFrame.x, 0, ScreenSize.x),
        util.clamp(self.state.cursorPos.y + changeThisFrame.y, 0, ScreenSize.y)
    )

    self.state.cumulativeXMove = self.state.cumulativeXMove + changeThisFrame.x

    if math.abs(self.state.cumulativeXMove) >= (self.TargetFlickThreshold * self.Sensitivity) and not self.state.flickTriggered then
        if not I.UI.getMode() and markerVisible then
            GlobalManagement.LockOn:selectNearestTarget(self.state.cumulativeXMove < 0)
            self.state.flickTriggered = true
        end
    end

    if changeThisFrame:length() == 0 then
        self.state.cumulativeXMove = 0
        self.state.flickTriggered = false
    end

    local showCursor = input.getBooleanActionValue('Run') and not markerVisible

    camera.showCrosshair(not showCursor)
    I.Controls.overrideCombatControls(showCursor)
    self:setCursorPosition(self.state.cursorPos)

    Cursor.layout.props.size = util.vector2(CursorController.CursorSize, CursorController.CursorSize)
    Cursor.layout.props.anchor = util.vector2(CursorController.XAnchor, CursorController.YAnchor)

    self:setCursorVisible(showCursor)
end

input.bindAction('Use', async:callback(function()
        if CursorController:getCursorVisible() then return false end
        return input.isActionPressed(input.ACTION.Use)
    end),
    {})

function CursorController:onFrame(dt)
    if self.state.changeThisFrame:length() == 0 then return end
end

function CursorController:getCursorPosition()
    return self.state.cursorPos
end

function CursorController:getCursorVisible()
    return Cursor.layout.props.visible
end

function CursorController:setCursorVisible(state)
    if Cursor.layout.props.visible == state then return end

    Cursor.layout.props.visible = state
    Cursor:update()

    if not state and self.StartFromCenter then
        self:setCursorPosition(self:startPos())
    end
end

---@param newAnchor util.vector2 a normalized vector from which to position the cursor
function CursorController:setCursorAnchor(newAnchor)
    Cursor.layout.props.anchor = newAnchor

    if not Cursor.layout.props.visible then return end
    Cursor:update()
end

---@return util.vector2
function CursorController:getCursorSize()
    return Cursor.layout.props.size
end

---@param newSize util.vector2
function CursorController:setCursorSize(newSize)
    Cursor.layout.props.size = newSize

    if not Cursor.layout.props.visible then return end
    Cursor:update()
end

function CursorController:getNormalizedCursorPosition()
    return self.state.cursorPos:normalize()
end

function CursorController:getCursorMove()
    return input.getMouseMoveX(), input.getMouseMoveY()
end

local SelectRange = 1250
function CursorController:getObjectUnderMouse()
end

---@param newPos util.vector2
function CursorController:setCursorPosition(newPos)
    local ScreenSize = ui.screenSize()

    newPos = util.vector2(
        util.clamp(newPos.x, 0, ScreenSize.x),
        util.clamp(newPos.y, 0, ScreenSize.y)
    )

    self.state.cursorPos = newPos
    Cursor.layout.props.position = newPos

    if not Cursor.layout.props.visible then return end
    Cursor:update()
end

---@param globalManagement ManagementStore
---@return CursorController
return function(globalManagement)
    assert(globalManagement)
    GlobalManagement = globalManagement
    return CursorController
end
