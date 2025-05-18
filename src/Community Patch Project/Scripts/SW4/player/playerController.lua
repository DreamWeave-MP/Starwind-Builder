local camera = require('openmw.camera')
local core = require('openmw.core')
local input = require 'openmw.input'
local self = require('openmw.self')
local ui = require('openmw.ui')

require 'Scripts.SW4.input.actionRegistrations'

local I = require('openmw.interfaces')

local CamHelper = require 'Scripts.SW4.helper.cameraHelper'
local ModInfo = require('scripts.sw4.modinfo')

--- System handlers added by SW4
---@class ManagementStore
local Managers = {
  MountFunctions = require('scripts.sw4.player.mountfunctions'),
}

---@type CameraManager
Managers.Camera = require 'Scripts.SW4.player.cameraManager' (Managers)
---@type LockOnManager
Managers.LockOn = require 'Scripts.SW4.player.lockOnManager' (Managers)
---@type ShootManager
Managers.Shoot = require 'scripts.sw4.player.shootHandler' (Managers)
---@type InputManager
Managers.Input = require 'Scripts.SW4.player.inputController' (Managers)

local ShowMessage = ui.showMessage

I.AnimationController.addTextKeyHandler("", function(group, key)
  -- print(group, key)
end)

I.AnimationController.addTextKeyHandler("spellcast", function(group, key)
  for _, spellcastHandler in ipairs { Managers.MountFunctions.handleMountCast, } do
    if spellcastHandler(group, key) then break end
  end
end)

local util = require 'openmw.util'
local CursorController = {}
CursorController.state = {
  cursorPos = util.vector2(0, 0),
}

function CursorController:onFrameBegin(dt)
  self.state.cursorPos = self.state.cursorPos + util.vector2(input.getMouseMoveX(), input.getMouseMoveY())
  -- print(self.state.cursorPos)
end

local OnFrameExecutionOrder = {
  CursorController,
  Managers.Camera,
  Managers.Input,
  Managers.Shoot,
  Managers.LockOn
}

---@enum FrameHandlerType
local FrameHandlerType = {
  Begin = 'onFrameBegin',
  Middle = 'onFrame',
  End = 'onFrameEnd',
}

---@param frameHandlerType FrameHandlerType
local function onFrameSubsystems(frameHandlerType, dt)
  for _, subsystem in ipairs(OnFrameExecutionOrder) do
    if subsystem[frameHandlerType] then
      subsystem[frameHandlerType](subsystem, dt)
    end
  end
end

return {
  interfaceName = ModInfo.name .. "_PlayerController",
  interface = {
    CamHelper = CamHelper,
    CameraManager = Managers.Camera,
    LockOnManager = Managers.LockOn,
    MountFunctions = Managers.MountFunctions,
    ShootManager = Managers.Shoot,
  },
  engineHandlers = {
    onFrame = function(dt)
      onFrameSubsystems(FrameHandlerType.Begin, dt)
      onFrameSubsystems(FrameHandlerType.Middle, dt)
      onFrameSubsystems(FrameHandlerType.End, dt)
    end,
    onUpdate = function(dt)
      Managers.MountFunctions.onUpdate(dt)
    end,
    onTeleported = function()
      core.sendGlobalEvent('SW4_PlayerCellChanged', { player = self.object, prevCell = self.cell.name })
    end,
    onSave = function()
      return {
        mountState = {
          prevGauntlet = Managers.MountFunctions.SavedState.prevGauntlet,
          prevSpellOrEnchantedItem = Managers.MountFunctions.SavedState.prevSpellOrEnchantedItem,
          currentMountSpell = Managers.MountFunctions.SavedState.currentMountSpell,
          equipState = Managers.MountFunctions.SavedState.equipState,
        },
        mountActionQueue = Managers.MountFunctions.ActionQueue,
      }
    end,
    onLoad = function(data)
      Managers.MountFunctions.ActionQueue = data.mountActionQueue or {}

      if data.mountState then
        Managers.MountFunctions.SavedState.prevGauntlet = data.mountState.prevGauntlet
        Managers.MountFunctions.SavedState.prevSpellOrEnchantedItem = data.mountState.prevSpellOrEnchantedItem
        Managers.MountFunctions.SavedState.currentMountSpell = data.mountState.currentMountSpell
        Managers.MountFunctions.SavedState.equipState = data.mountState.equipState
      end
    end,
  },
  eventHandlers = {
    --- Plays ambient sound records or arbitrary sound files from other contexts using provided options
    SW4_AmbientEvent = require('scripts.sw4.player.ambientevent'),
    SW4_UIMessage = ShowMessage,
    --- Logs a message to the console using the success color
    ---@param message string The message to log
    SW4_LogMessage = function(message)
      ui.printToConsole(message, ui.CONSOLE_COLOR.Success)
    end,
  }
}
