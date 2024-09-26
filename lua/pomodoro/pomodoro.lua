local UI = require("pomodoro.ui")
local constants = require("pomodoro.constants")
local uv = require("pomodoro.uv")
local log = require("pomodoro.log")
local info = log.info
local MIN_IN_MS = constants.MIN_IN_MS
local Phases = constants.Phases

---@class Pomodoro
---@field work_duration number
---@field break_duration number
---@field long_break_duration number
---@field breaks_before_long number
---@field break_count number
---@field timer_duration number
---@field start_at_launch boolean
---@field timer uv_timer_t
---@field phase integer
local pomodoro = {}

-- Work duration in ms
pomodoro.work_duration = 25 * MIN_IN_MS
-- Break duration in ms
pomodoro.break_duration = 5 * MIN_IN_MS
-- Break duration in ms
pomodoro.long_break_duration = 15 * MIN_IN_MS
-- Delay duration in ms
pomodoro.delay_duration = 1 * MIN_IN_MS
pomodoro.break_count = 0
pomodoro.breaks_before_long = 4
pomodoro.timer_duration = 0
pomodoro.start_at_launch = true
pomodoro.timer = uv.new_timer()
pomodoro.started_timer_time = uv.now()
pomodoro.phase = Phases.NOT_RUNNING

---@param time number
---@param fn function
function pomodoro.startTimer(time, fn)
    pomodoro.timer:stop()
    pomodoro.timer_duration = time
    pomodoro.started_timer_time = uv.now()
    pomodoro.timer:start(time, 0, fn)
end

function pomodoro.displayPomodoroUI()
    if pomodoro.phase == Phases.NOT_RUNNING or pomodoro.phase == nil then
        pomodoro.start()
    end
    if UI.isWinOpen() ~= true then
        if UI.ui_update_timer:is_active() ~= true then
            UI.updateUi(pomodoro)
        end
        UI.win = vim.api.nvim_open_win(UI.buffer, true, UI.buffer_opts)
    else
        if pomodoro.phase ~= Phases.BREAK then
            UI.close()
        end
    end
end

function pomodoro.closePomodoroUi()
    UI.close()
end

---@return boolean
function pomodoro.isInLongBreak()
    return pomodoro.break_count % (pomodoro.breaks_before_long + 1) == 0
        and pomodoro.phase == Phases.BREAK
end

function pomodoro.startBreak()
    pomodoro.phase = Phases.BREAK
    pomodoro.break_count = pomodoro.break_count + 1
    local break_duration
    if pomodoro.isInLongBreak() then
        break_duration = pomodoro.long_break_duration
    else
        break_duration = pomodoro.break_duration
    end

    info("Break of " .. break_duration / MIN_IN_MS .. "m started!")
    vim.schedule(pomodoro.displayPomodoroUI)
    pomodoro.startTimer(break_duration, pomodoro.endBreak)
end

function pomodoro.endBreak()
    vim.schedule(pomodoro.closePomodoroUi)
    pomodoro.phase = Phases.RUNNING
    pomodoro.start()
end

function pomodoro.start()
    info(
        "Work session of " .. pomodoro.work_duration / MIN_IN_MS .. "m started!"
    )
    pomodoro.phase = Phases.RUNNING
    pomodoro.startTimer(pomodoro.work_duration, pomodoro.startBreak)
end

function pomodoro.delayBreak()
    if pomodoro.phase == Phases.BREAK then
        info("Break delayed")
        pomodoro.phase = Phases.RUNNING
        -- So if a long break is delayed the next break is still a long one
        pomodoro.break_count = pomodoro.break_count - 1
        pomodoro.closePomodoroUi()
        pomodoro.startTimer(MIN_IN_MS, pomodoro.startBreak)
    end
end

function pomodoro.stop()
    pomodoro.phase = Phases.NOT_RUNNING
    pomodoro.timer:stop()
    UI.ui_update_timer:stop()
    pomodoro.closePomodoroUi()
    info("Stopped")
end

function pomodoro.registerCmds()
    vim.api.nvim_create_user_command(
        "PomodoroForceBreak",
        pomodoro.startBreak,
        {}
    )
    vim.api.nvim_create_user_command("PomodoroSkipBreak", pomodoro.endBreak, {})
    vim.api.nvim_create_user_command("PomodoroStart", pomodoro.start, {})
    vim.api.nvim_create_user_command("PomodoroStop", pomodoro.stop, {})
    vim.api.nvim_create_user_command(
        "PomodoroDelayBreak",
        pomodoro.delayBreak,
        {}
    )
    vim.api.nvim_create_user_command(
        "PomodoroUI",
        pomodoro.displayPomodoroUI,
        {}
    )
end

---@class PomodoroOpts
---@field work_duration? number
---@field break_duration? number
---@field long_break_duration? number
---@field delay_duration? number
---@field breaks_before_long? number
---@field start_at_launch? boolean

---@param opts PomodoroOpts
function pomodoro.setup(opts)
    if opts then
        if opts.work_duration ~= nil then
            pomodoro.work_duration = opts.work_duration * MIN_IN_MS
        end
        if opts.break_duration ~= nil then
            pomodoro.break_duration = opts.break_duration * MIN_IN_MS
        end
        if opts.long_break_duration ~= nil then
            pomodoro.long_break_duration = opts.long_break_duration * MIN_IN_MS
        end
        if opts.delay_duration ~= nil then
            pomodoro.delay_duration = opts.delay_duration * MIN_IN_MS
        end
        if opts.breaks_before_long ~= nil then
            pomodoro.breaks_before_long = opts.breaks_before_long
        end
        if opts.start_at_launch ~= nil then
            pomodoro.start_at_launch = opts.start_at_launch
        end
    end

    pomodoro.registerCmds()

    if pomodoro.start_at_launch then
        pomodoro.start()
    end
end

return pomodoro
