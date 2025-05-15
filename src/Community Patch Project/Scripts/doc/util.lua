---@module 'openmw.util'
local util = {}

---@class openmw.util
---@field vector2 util.vector2
---@field vector3 util.vector3
---@field remap fun(value: number, oldMin: number, oldMax: number, newMin: number, newMax: number) remap a value from one range into another
---@field round fun(value: number): number rounds a number to the nearest whole integer

return util