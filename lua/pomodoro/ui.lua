local constants = require("pomodoro.constants")
local MIN_IN_MS = constants.MIN_IN_MS
local Phases = constants.Phases

-- Disable a keymap for a given buffer
---@param buffer integer --
---@param mode string --
---@param key string --
local function disable_key(buffer, mode, key)
    vim.api.nvim_buf_set_keymap(
        buffer,
        mode,
        key,
        "",
        { noremap = true, silent = true }
    )
end

-- Set an exit key for a buffer
---@param buffer integer --
---@param mode string --
---@param key string --
local function set_exit_key(buffer, mode, key)
    vim.api.nvim_buf_set_keymap(
        buffer,
        mode,
        key,
        "<Cmd>bd!<CR>",
        { noremap = true, silent = true }
    )
end
-- Set an exit key for a buffer
---@param buffer integer --
---@param mode string --
---@param key string --
local function set_command_key(buffer, mode, key, command)
    vim.api.nvim_buf_set_keymap(
        buffer,
        mode,
        key,
        string.format(":%s<CR>", command),
        { noremap = true, silent = true }
    )
end
-- Apply custom keymaps to a buffer
---@param buffer integer --
local function apply_buffer_keymaps(buffer)
    set_exit_key(buffer, "n", "q")
    set_exit_key(buffer, "n", "<C-h>")
    set_exit_key(buffer, "n", "<C-l>")
    disable_key(buffer, "n", "d")
    disable_key(buffer, "n", "i")
    disable_key(buffer, "n", "v")
    disable_key(buffer, "n", "r")
    disable_key(buffer, "n", "u")
    disable_key(buffer, "n", "<C-r>")
    set_command_key(buffer, "n", "<C-q>", "PomodoroStop")
    set_command_key(buffer, "n", "<C-s>", "PomodoroSkipBreak")
    -- TODO:
    set_command_key(buffer, "n", "<C-y>", "PomodoroAddTime")
end
---@return integer
local function createBufferUi()
    local buffer = vim.api.nvim_create_buf(false, true) -- Create a new buffer, not listed, scratch buffer
    apply_buffer_keymaps(buffer)
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

---@class PomodoroUI
---@field ui_update_timer uv_timer_t
---@field buffer integer
---@field buffer_opts table
---@field win? integer
local UI = {}
UI.buffer = createBufferUi()
UI.buffer_opts = createBufferOpts()
UI.ui_update_timer = vim.uv.new_timer()
UI.win = nil

---@param pomodoro Pomodoro
function UI.get_buffer_data(pomodoro)
    local time_left = pomodoro.getTimeLeftPhase()
    local time_left_string
    if time_left > MIN_IN_MS then
        time_left_string = "Time left : "
            .. math.floor(time_left / MIN_IN_MS)
            .. "min"
    else
        time_left_string = "Time left : "
            .. math.floor(time_left / 1000)
            .. "sec"
    end
    local data = {}
    if pomodoro.phase == Phases.RUNNING then
        table.insert(data, "Time to work !")
    end
    if pomodoro.phase == Phases.BREAK then
        table.insert(data, "Time to take a break !")
    end
    table.insert(data, time_left_string)
    return data
end
function UI.isWinOpen()
    if UI.win == nil then
        return false
    end
    return vim.api.nvim_win_is_valid(UI.win)
end
-- update the UI time and in which phase we are
---@param pomodoro Pomodoro
function UI.updateUi(pomodoro)
    vim.schedule(function()
        if UI.isWinOpen() then
            local data = UI.get_buffer_data(pomodoro)
            vim.api.nvim_buf_set_lines(UI.buffer, 0, -1, false, data)
            UI.startRenderingTimer(pomodoro)
        end
    end)
end
---@param pomodoro Pomodoro
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
