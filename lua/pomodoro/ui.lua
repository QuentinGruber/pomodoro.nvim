local constants = require("pomodoro.constants")
local uv = require("pomodoro.uv")
local MIN_IN_MS = constants.MIN_IN_MS
local Phases = constants.Phases

local function disable_key(buffer, mode, key)
    vim.api.nvim_buf_set_keymap(
        buffer,
        mode,
        key,
        "",
        { noremap = true, silent = true }
    )
end

local function set_command_key(buffer, mode, key, command)
    vim.api.nvim_buf_set_keymap(
        buffer,
        mode,
        key,
        string.format(":%s<CR>", command),
        { noremap = true, silent = true }
    )
end

local function apply_buffer_keymaps(buffer)
    disable_key(buffer, "n", "d")
    disable_key(buffer, "n", "i")
    disable_key(buffer, "n", "v")
    disable_key(buffer, "n", "r")
    disable_key(buffer, "n", "u")
    disable_key(buffer, "n", "<C-r>")
    set_command_key(buffer, "n", "Q", "PomodoroStop")
    set_command_key(buffer, "n", "W", "PomodoroSkipBreak")
    set_command_key(buffer, "n", "B", "PomodoroForceBreak")
    set_command_key(buffer, "n", "D", "PomodoroDelayBreak")
end

local function createBufferUi()
    local buffer = vim.api.nvim_create_buf(false, true)
    apply_buffer_keymaps(buffer)
    return buffer
end

local function createBufferOpts()
    local win_width = 40
    local win_height = 8
    local row = math.floor((vim.o.lines - win_height) / 2)
    local col = math.floor((vim.o.columns - win_width) / 2)

    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        border = "rounded",
    }
    return opts
end

local UI = {}
UI.buffer = createBufferUi()
UI.buffer_opts = createBufferOpts()
UI.ui_update_timer = uv.new_timer()
UI.win = nil

local function center(str, width)
    local padding = width - #str
    return string.rep(" ", math.floor(padding / 2)) .. str
end

local function progress_bar(current, total, width)
    local filled = math.floor(current / total * width)
    return "["
        .. string.rep("=", filled)
        .. string.rep(" ", width - filled)
        .. "]"
end

function UI.get_buffer_data(pomodoro)
    local time_pass = uv.now() - pomodoro.started_timer_time
    local time_left = pomodoro.timer_duration - time_pass
    local minutes = math.floor(time_left / MIN_IN_MS)
    local seconds = math.floor((time_left % MIN_IN_MS) / 1000)
    local time_left_string = string.format("%02d:%02d", minutes, seconds)

    local data = {}
    local width = UI.buffer_opts.width - 2 -- Account for borders

    if pomodoro.phase == Phases.RUNNING then
        table.insert(data, center("🍅 POMODORO", width))
        table.insert(data, center(time_left_string, width))
        table.insert(
            data,
            progress_bar(time_pass, pomodoro.timer_duration, width)
        )
        table.insert(data, "")
        table.insert(data, center("Time to work!", width))
        table.insert(data, "")
        table.insert(data, center("[B]reak  [Q]uit", width))
    elseif pomodoro.phase == Phases.BREAK then
        table.insert(data, center("☕ BREAK TIME", width))
        table.insert(data, center(time_left_string, width))
        table.insert(
            data,
            progress_bar(time_pass, pomodoro.timer_duration, width)
        )
        table.insert(data, "")
        table.insert(data, center("Time to relax!", width))
        table.insert(data, "")
        table.insert(data, center("[W]ork  [Q]uit  [D]elay", width))
    end

    return data
end

function UI.isWinOpen()
    if UI.win == nil then
        return false
    end
    return vim.api.nvim_win_is_valid(UI.win)
end

function UI.updateUi(pomodoro)
    vim.schedule(function()
        if UI.isWinOpen() then
            local data = UI.get_buffer_data(pomodoro)
            vim.api.nvim_buf_set_lines(UI.buffer, 0, -1, false, data)
            UI.startRenderingTimer(pomodoro)
        else
            if pomodoro.phase == Phases.BREAK then
                pomodoro.delayBreak()
            end
        end
    end)
end

function UI.startRenderingTimer(pomodoro)
    UI.ui_update_timer:stop()
    UI.ui_update_timer:start(1000, 0, function()
        UI.updateUi(pomodoro)
    end)
end

function UI.close()
    if UI.isWinOpen() then
        vim.api.nvim_win_close(UI.win, true)
        UI.win = nil
    end
    UI.ui_update_timer:stop()
end

return UI
