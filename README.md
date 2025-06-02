# Yeico Applet

- Yeico Terminal needs to run scripts comming from Yeico Central over the link.
- Yeico Central needs to run scripts pushed from the cli to customize terminal handling.

## Howto

```bash
mkdir yeico_applet && cd yeico_applet
mix new --app applet --sup .
iex --sname applet@localhost --cookie cookie -S mix app.start
iex --sname remote@localhost --cookie cookie --remsh applet@localhost
#check colors
mix run exs/colors.exs
```
