local core = require('openmw.core')
local self = require('openmw.self')
local ui = require('openmw.ui')

local I = require('openmw.interfaces')

local ModInfo = require('scripts.sw4.modinfo')
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

I.AnimationController.addTextKeyHandler('', function(group, key)
end)

return {
  interfaceName = ModInfo.name .. "_Player",
  interface = {
    MountFunctions = MountFunctions,
  },
  engineHandlers = {
    onFrame = function(dt)
      ShootManager.onFrame(dt)
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
