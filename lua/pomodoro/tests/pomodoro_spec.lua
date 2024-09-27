local pomodoro
describe("useless tests", function()
    before_each(function()
        pomodoro = require("pomodoro")
    end)
    it("setup", function()
        local opts = {}
        local MIN_IN_MS = 60000
        opts.work_duration = 10
        opts.break_duration = 10
        opts.delay_duration = 10
        opts.long_break_duration = 15
        opts.breaks_before_long = 4
        opts.start_at_launch = false
        pomodoro.setup(opts)
        assert(
            pomodoro.work_duration == opts.work_duration * MIN_IN_MS,
            "Opt work_duration"
        )
        assert(
            pomodoro.break_duration == opts.break_duration * MIN_IN_MS,
            "Opt break_duration"
        )
        assert(
            pomodoro.breaks_before_long == opts.breaks_before_long,
            "Opt breaks_before_long"
        )
        assert(
            pomodoro.long_break_duration == opts.long_break_duration * MIN_IN_MS,
            "Opt long_break_duration"
        )
        assert(
            pomodoro.delay_duration == opts.delay_duration * MIN_IN_MS,
            "Opt delay_duration"
        )
        assert(
            pomodoro.start_at_launch == opts.start_at_launch,
            "Opt start_at_launch"
        )
    end)
    --TODO: tests
end)
