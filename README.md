# pomodoro.nvim

Display time spent on projects / files

- install using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
  {
    "quentingruber/pomodoro.nvim",
    lazy = false, -- needed so the pomodoro can start at launch
    opts = {
      start_at_launch = true,
      work_duration = 25,
      break_duration = 5,
      snooze_duration = 1, -- The additionnal work time you get when you delay a break
    },
  },

```

## Usage

| Command               | Description |
| --------------------- | ----------- |
| `:PomodoroStart`      | Start the Pomodoro timer. |
| `:PomodoroStop`       | Stop the Pomodoro timer. |
| `:PomodoroUI`         | Display the Pomodoro UI. |
| `:PomodoroSkipBreak`  | Skip the current break and start the next work session. |
| `:PomodoroForceBreak` | Forcefully start a break. |
| `:PomodoroSnooze`     | Delay the current break by a snooze duration. |
