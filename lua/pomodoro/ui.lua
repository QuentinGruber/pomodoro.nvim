local UI = {}

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

-- Disable a keymap for a given buffer
---@param buffer integer --
---@param mode string --
---@param key string --
function UI.disable_key(buffer, mode, key)
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
function UI.set_exit_key(buffer, mode, key)
    vim.api.nvim_buf_set_keymap(
        buffer,
        mode,
        key,
        "<Cmd>bd!<CR>",
        { noremap = true, silent = true }
    )
end

-- Apply custom keymaps to a buffer
---@param buffer integer --
function UI.apply_buffer_keymaps(buffer)
    UI.set_exit_key(buffer, "n", "q")
    UI.set_exit_key(buffer, "n", "<C-h>")
    UI.set_exit_key(buffer, "n", "<C-l>")
    UI.disable_key(buffer, "n", "d")
    UI.disable_key(buffer, "n", "i")
    UI.disable_key(buffer, "n", "v")
    UI.disable_key(buffer, "n", "r")
    UI.disable_key(buffer, "n", "u")
    UI.disable_key(buffer, "n", "<C-r>")
end

return UI
