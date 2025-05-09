local animation = require('openmw.animation')
local input = require('openmw.input')
local self = require('openmw.self')

local I = require('openmw.interfaces')

local forceAttack = false
local forceRelease = false
local BlasterSpeedMult = 25.0
local LogMessage = require('scripts.sw4.helper.logmessage')

--- Handles animation text keys and shoot overrides for the player
--- Allows automatic shooting of blasters
---@class ShootManager
---@field onFrame fun(dt: number): nil If signalled by the animation handlers, will force the player to engage or release an attack
---@field textKeyHandler fun(_: string, key: string): nil Signals the onFrame handler to start/release an attack depending on animation state
local ShootManager = {
  DefaultSpeedMult = 25.0,
  onFrame = function(dt)
    if forceAttack then
      self.controls.use = 1
    elseif forceRelease then
      self.controls.use = 0
      forceRelease = false
    end
  end,
  textKeyHandler = function(_, key)
    if key == 'shoot start' or key == 'shoot follow start' then
      LogMessage("Crowssbow Handler: Increasing shoot speed!")
      animation.setSpeed(self, 'crossbow', BlasterSpeedMult)
    elseif key == 'shoot min hit' then
      if self.controls.use == 1 or input.getBooleanActionValue('Use') then
        LogMessage('Crossbow Handler: Releasing shot!')
        forceRelease = true
      end
    elseif key == 'follow stop' then
      forceAttack = input.getBooleanActionValue('Use')
    end
  end,
}

I.AnimationController.addTextKeyHandler('crossbow', ShootManager.textKeyHandler)

return ShootManager