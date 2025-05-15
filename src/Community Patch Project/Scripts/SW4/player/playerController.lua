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
local Managers = {
  ---@type CameraManager
  Camera = require 'Scripts.SW4.player.cameraManager' (),
  LockOn = require 'Scripts.SW4.player.lockOnManager' (),
  MountFunctions = require('scripts.sw4.player.mountfunctions'),
  Shoot = require('scripts.sw4.player.shootHandler'),
}

local ShowMessage = ui.showMessage

I.AnimationController.addTextKeyHandler("", function(group, key)
  -- print(group, key)
end)

I.AnimationController.addTextKeyHandler("spellcast", function(group, key)
  for _, spellcastHandler in ipairs { Managers.MountFunctions.handleMountCast, } do
    if spellcastHandler(group, key) then break end
  end
end)

local CursorController = {}

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
    -- onKeyPress = function(key)
    -- end,
    onFrame = function(dt)
      Managers.Camera:onFrameBegin(dt, Managers)

      Managers.Shoot.onFrame(dt, Managers)

      Managers.LockOn.onFrame(dt, Managers)

      Managers.Camera:onFrameEnd(dt, Managers)
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
