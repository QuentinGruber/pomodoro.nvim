---@class PhasesEnum
---@field  NOT_RUNNING integer
---@field  RUNNING integer
---@field  BREAK integer
local Phases = {
    NOT_RUNNING = 0,
    RUNNING = 1,
    BREAK = 2,
}
local constants = {
    MIN_IN_MS = 60000,
    Phases = Phases,
}

return constants
