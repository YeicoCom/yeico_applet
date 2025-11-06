# Yeico Applet

- Yeico Terminal needs to run production ready RAD scripted apps.
- Yeico Terminal needs to run scripts comming from Yeico Central over the link.
- Yeico Central needs to run scripts pushed from the cli to customize terminal handling.

## Howto

```bash
mkdir yeico_applet && cd yeico_applet
mix new --app applet --sup .
iex --sname applet@localhost --cookie cookie -S mix app.start
iex --sname remote@localhost --cookie cookie --remsh applet@localhost
# check colors
mix run exs/colors.exs
```

```elixir
# from iex
# runs ${PWD}/applets/tryout.exs
Applet.run!("tryout.exs")
# runs ${PWD}/applets/tryout/tryout.exs
Applet.run!("tryout/tryout.exs")
# type INTRO to stop logging
```

## Fixme

- [ ] app shutdowns from time to time on recompile from eix

## Roadmap

- [ ] Thorough testing
- [ ] Module de-clutter and cleanup
- [-] Fully disk based multi-file applets
  - Currently only entry file gets persisted
- [-] WONTFIX Configurable applets parent folder
- [x] Shorted database names
- [x] run and trace from server
- [x] reboot, restart, and clean tasks
- [x] run! with log: <level> opts
- [x] rename saved to stored
- [-] WONTFIX command serializer
- [-] WONTFIX log from iex
