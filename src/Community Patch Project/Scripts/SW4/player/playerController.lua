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
local CameraManager = require 'Scripts.SW4.player.cameraManager' ()
local LockOnManager = require 'Scripts.SW4.player.lockOnManager' ()
local MountFunctions = require('scripts.sw4.player.mountfunctions')
local ShootManager = require('scripts.sw4.player.shootHandler')

local ShowMessage = ui.showMessage

I.AnimationController.addTextKeyHandler("", function(group, key)
  -- print(group, key)
end)

I.AnimationController.addTextKeyHandler("spellcast", function(group, key)
  for _, spellcastHandler in ipairs { MountFunctions.handleMountCast, } do
    if spellcastHandler(group, key) then break end
  end
end)

return {
  interfaceName = ModInfo.name .. "_PlayerController",
  interface = {
    CamHelper = CamHelper,
    CameraManager = CameraManager,
    LockOnManager = LockOnManager,
    MountFunctions = MountFunctions,
    ShootManager = ShootManager,
  },
  engineHandlers = {
    -- onKeyPress = function(key)
    -- end,
    onFrame = function(dt)
      CameraManager.onFrameBegin(dt)

      ShootManager.onFrame(dt)

      LockOnManager.onFrame(dt, CameraManager.isWielding)

      CameraManager.onFrameEnd(dt, LockOnManager.getTargetObject())
    end,
    onUpdate = function(dt)
      MountFunctions.onUpdate(dt)
    end,
    onTeleported = function()
      core.sendGlobalEvent('SW4_PlayerCellChanged', { player = self.object, prevCell = self.cell.name })
    end,
    onSave = function()
      return {
        mountState = {
          prevGauntlet = MountFunctions.SavedState.prevGauntlet,
          prevSpellOrEnchantedItem = MountFunctions.SavedState.prevSpellOrEnchantedItem,
          currentMountSpell = MountFunctions.SavedState.currentMountSpell,
          equipState = MountFunctions.SavedState.equipState,
        },
        mountActionQueue = MountFunctions.ActionQueue,
      }
    end,
    onLoad = function(data)
      MountFunctions.ActionQueue = data.mountActionQueue or {}

      if data.mountState then
        MountFunctions.SavedState.prevGauntlet = data.mountState.prevGauntlet
        MountFunctions.SavedState.prevSpellOrEnchantedItem = data.mountState.prevSpellOrEnchantedItem
        MountFunctions.SavedState.currentMountSpell = data.mountState.currentMountSpell
        MountFunctions.SavedState.equipState = data.mountState.equipState
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
