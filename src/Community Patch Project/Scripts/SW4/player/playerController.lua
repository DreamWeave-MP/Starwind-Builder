local ambient = require('openmw.ambient')
local core = require('openmw.core')
local self = require('openmw.self')
local ui = require('openmw.ui')

local I = require('openmw.interfaces')

local ModInfo = require('scripts.sw4.modinfo')
local MountFunctions = require('scripts.sw4.player.mountfunctions')

---@class AmbientData
---@field soundFile string|nil VFS path to a sound file to play
---@field soundRecord string|nil string ID of a sound record to play

local ShowMessage = ui.showMessage

I.AnimationController.addTextKeyHandler("", function(group, key)
  print(group, key)
end)

I.AnimationController.addTextKeyHandler("spellcast", function(group, key)
  for _, spellcastHandler in ipairs { MountFunctions.handleMountCast, } do
    if spellcastHandler(group, key) then break end
  end
end)

return {
  interfaceName = ModInfo.name .. "_Player",
  interface = {
    MountFunctions = MountFunctions,
  },
  engineHandlers = {
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
    ---@param ambientData AmbientData
    SW4_AmbientEvent = function(ambientData)
      local soundFile = ambientData.soundFile
      local soundRecord = ambientData.soundRecord
      if soundFile then
        if ambient.isSoundFilePlaying(soundFile) then
          ambient.stopSoundFile(soundFile)
        end
        ambient.playSoundFile(soundFile, ambientData.options)
      elseif soundRecord then
        if ambient.isSoundPlaying(soundRecord) then
          ambient.stopSound(soundRecord)
        end
        ambient.playSound(soundRecord, ambientData.options)
      elseif not soundRecord and not soundFile then
        error("Invalid sound information provided to SW4_AmbientEvent!")
      end
    end,
    SW4_UIMessage = ShowMessage,
    --- Logs a message to the console using the success color
    ---@param message string The message to log
    SW4_LogMessage = function(message)
      ui.printToConsole(message, ui.CONSOLE_COLOR.Success)
    end,
  }
}
