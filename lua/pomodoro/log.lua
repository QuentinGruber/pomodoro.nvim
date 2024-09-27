local log = {}

local p = "[pomodoro.nvim] "

function log.info(txt)
    vim.schedule(function()
        vim.notify(p .. txt)
    end)
end

function log.error(txt)
    vim.schedule(function()
        vim.notify(p .. txt)
    end)
end

return log
