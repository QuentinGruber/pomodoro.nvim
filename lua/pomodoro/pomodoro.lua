local UI = require("pomodoro.ui")
local constants = require("pomodoro.constants")
local uv = require("pomodoro.uv")
local MIN_IN_MS = constants.MIN_IN_MS
local Phases = constants.Phases

---@class Pomodoro
---@field work_duration number
---@field break_duration number
---@field timer_duration number
---@field start_at_launch boolean
---@field timer uv_timer_t
---@field phase integer
local pomodoro = {}

-- Work duration in ms
pomodoro.work_duration = 25 * MIN_IN_MS
-- Break duration in ms
pomodoro.break_duration = 5 * MIN_IN_MS
-- Delay duration in ms
pomodoro.delay_duration = 1 * MIN_IN_MS
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

---@return boolean

function pomodoro.displayPomodoroUI()
    if pomodoro.phase == Phases.NOT_RUNNING or pomodoro.phase == nil then
        vim.notify("Can't display pomodoro ui when pomodoro isn't running")
        return
    end
    if UI.isWinOpen() ~= true then
        if UI.ui_update_timer:is_active() ~= true then
            UI.updateUi(pomodoro)
        end
        UI.win = vim.api.nvim_open_win(UI.buffer, true, UI.buffer_opts)
    end
end
function pomodoro.closePomodoroUi()
    UI.close()
end

function pomodoro.delayBreak()
    pomodoro.startTimer(MIN_IN_MS, pomodoro.startBreak)
end
function pomodoro.startBreak()
    vim.notify(
        "Break of " .. pomodoro.break_duration / MIN_IN_MS .. "m started!"
    )
    pomodoro.phase = Phases.BREAK
    vim.schedule(pomodoro.displayPomodoroUI)
    pomodoro.startTimer(pomodoro.break_duration, pomodoro.endBreak)
end
function pomodoro.endBreak()
    vim.schedule(pomodoro.closePomodoroUi)
    pomodoro.phase = Phases.RUNNING
    pomodoro.start()
end

function pomodoro.start()
    vim.notify(
        "Pomodoro of " .. pomodoro.work_duration / MIN_IN_MS .. "m started!"
    )
    pomodoro.phase = Phases.RUNNING
    pomodoro.startTimer(pomodoro.work_duration, pomodoro.startBreak)
end

function pomodoro.delayBreak()
    if pomodoro.phase == Phases.BREAK then
        pomodoro.phase = Phases.RUNNING
        pomodoro.closePomodoroUi()
        pomodoro.startTimer(MIN_IN_MS, pomodoro.startBreak)
    end
end

function pomodoro.stop()
    pomodoro.timer:stop()
    UI.ui_update_timer:stop()
    pomodoro.closePomodoroUi()
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
---@field delay_duration? number
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
        if opts.delay_duration ~= nil then
            pomodoro.delay_duration = opts.delay_duration * MIN_IN_MS
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
