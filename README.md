# Yeico Applet

## Howto

```bash
mkdir yeico_applet && cd yeico_applet
mix new --app applet --sup .
iex --sname applet@localhost --cookie cookie -S mix app.start
iex --sname remote@localhost --cookie cookie --remsh applet@localhost
# check colors
elixir colors.exs
```

```elixir
# from iex

# runs code from ${PWD}/applets/tryout.exs
# type INTRO to stop logging
Applet.run!("tryout.exs")

# runs code as ${PWD}/applets/tryout.exs
Applet.start!("tryout.exs", code: """
  use Applet.Api
  f = fn f -> 
    Api.trace(:ok)
    Api.sleep(500)
    f.(f)
  end
  Api.async(fn -> f.(f) end)
""")
# type INTRO to stop logging
Applet.log("tryout.exs")
```

## Fixme

- [ ] app shutdowns from time to time on recompile from iex
- [ ] thorough testing
