# compile warning about unused variable
# f = fn a -> 1 end

# %CompileError{file: "tryout.exs", line: 0, description: "cannot compile file (errors have been logged)"}
# a

# %MatchError{term: 3}
# 1 = 3

# %BadArityError{function: #Function<42.81571850/1 in :erl_eval.expr/6>, args: []}
# f.()
use Applet.Api

Api.eval("#{Api.name()}/#{Api.file()}")
