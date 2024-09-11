local log = {}

local p = "[pomodoro.nvim] "

function log.info(txt)
    vim.notify(p .. txt)
end

function log.error(txt)
    vim.notify(p .. txt)
end
return log
