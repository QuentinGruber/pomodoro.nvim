local UI = require("pomodoro.ui")

---@class PhasesEnum
---@field  NOT_RUNNING integer
---@field  RUNNING integer
---@field  BREAK integer
Phases = {
    NOT_RUNNING = 0,
    RUNNING = 1,
    BREAK = 2,
}

---@class Pomodoro
---@field work_duration number
---@field break_duration number
---@field start_at_launch boolean
---@field timer uv_timer_t
---@field started_timer_time integer
---@field ui_update_timer uv_timer_t
---@field buffer integer
---@field buffer_opts table
---@field phase integer
---@field win? integer
local pomodoro = {}

MIN_IN_MS = 60000

---@return integer
local function createBufferUi()
    local buffer = vim.api.nvim_create_buf(false, true) -- Create a new buffer, not listed, scratch buffer
    UI.apply_buffer_keymaps(buffer)
    return buffer
end
---@return table
local function createBufferOpts()
    local win_width = 100
    local win_height = 20
    local row = math.floor((vim.o.lines - win_height) / 2)
    local col = math.floor((vim.o.columns - win_width) / 2)

    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        border = "single",
    }
    return opts
end
-- Work duration in ms
pomodoro.work_duration = 25 * MIN_IN_MS
-- Break duration in ms
pomodoro.break_duration = 5 * MIN_IN_MS
pomodoro.start_at_launch = true
pomodoro.timer = vim.uv.new_timer()
pomodoro.started_timer_time = vim.uv.now()
pomodoro.ui_update_timer = vim.uv.new_timer()
pomodoro.buffer = createBufferUi()
pomodoro.buffer_opts = createBufferOpts()
pomodoro.phase = Phases.NOT_RUNNING
pomodoro.win = nil

---@param time number
---@param fn function
function pomodoro.startTimer(time, fn)
    pomodoro.timer:stop()
    pomodoro.started_timer_time = vim.uv.now()
    pomodoro.timer:start(time, 0, fn)
end

function pomodoro.startRenderingTimer()
    pomodoro.ui_update_timer:stop()
    pomodoro.ui_update_timer:start(1000, 0, pomodoro.updateUi)
end

---@return number
function pomodoro.getTimeLeftPhase()
    local time_pass = vim.uv.now() - pomodoro.started_timer_time
    if pomodoro.phase == Phases.RUNNING then
        return pomodoro.work_duration - time_pass
    end
    if pomodoro.phase == Phases.BREAK then
        return pomodoro.break_duration - time_pass
    end
    return 0
end
---@return boolean
function pomodoro.isWinOpen()
    if pomodoro.win == nil then
        return false
    end
    return vim.api.nvim_win_is_valid(pomodoro.win)
end

-- update the UI time and in which phase we are
function pomodoro.updateUi()
    vim.schedule(function()
        if pomodoro.isWinOpen() then
            local data = UI.get_buffer_data(pomodoro)
            vim.api.nvim_buf_set_lines(pomodoro.buffer, 0, -1, false, data)
            pomodoro.startRenderingTimer()
        end
    end)
end

function pomodoro.displayPomodoroUI()
    if pomodoro.phase == Phases.NOT_RUNNING or pomodoro.phase == nil then
        vim.notify("Can't display pomodoro ui when pomodoro isn't running")
        return
    end
    if pomodoro.isWinOpen() ~= true then
        if pomodoro.ui_update_timer:is_active() ~= true then
            pomodoro.updateUi()
            pomodoro.startRenderingTimer()
        end
        pomodoro.win =
            vim.api.nvim_open_win(pomodoro.buffer, true, pomodoro.buffer_opts)
    end
end
function pomodoro.closePomodoroUi()
    if pomodoro.isWinOpen() then
        vim.api.nvim_win_close(pomodoro.win, true)
        pomodoro.win = nil
    end
    pomodoro.ui_update_timer:stop()
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

function pomodoro.stop()
    pomodoro.timer:stop()
    pomodoro.ui_update_timer:stop()
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
        "PomodoroUI",
        pomodoro.displayPomodoroUI,
        {}
    )
end

---@class PomodoroOpts
---@field work_duration? number
---@field break_duration? number
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
