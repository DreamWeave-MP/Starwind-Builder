local storage = require('openmw.storage')
local types = require('openmw.types')
local Player = types.Player

local World, Self, ui, nearby
local isGlobal, result = pcall(function() require('openmw.world') end)

local ModInfo = require('scripts.sw4.modinfo')

if isGlobal then
    World = result
else
    Self = require('openmw.self')

    if Player.objectIsInstance(Self) then
        ui = require('openmw.ui')
    else
        nearby = require('openmw.nearby')
    end
end

local CoreSettings = storage.globalSection('SettingsGlobal' .. ModInfo.name .. 'CoreGroup')

--- Prints a message to the console, directly using the console OR to nearby players if the attached object isn't a player
---@param messageString string The message to print to the console
local function LogMessage(messageString)
    if not CoreSettings:get('DebugEnable') then
        return
    end

    if isGlobal then
        assert(World, "World is not available")

        for _, player in pairs(World.players) do
            player:sendEvent('SW4_LogMessage', ModInfo.logPrefix .. messageString)
        end
    else
        if ui then
            ui.printToConsole(ModInfo.logPrefix .. messageString, ui.CONSOLE_COLOR.Success)
        else
            for _, player in pairs(nearby.players) do
                player:sendEvent('SW4_LogMessage', ModInfo.logPrefix .. messageString)
            end
        end
    end
end

return LogMessage