import Config

# HOME works for production
# File.cwd! works for both
config :applet, Applet, path: "#{File.cwd!()}/applets"
config :applet, Applet.Store, table: "store.dets"
config :applet, Applet.Api.Ddb, table: "api.dets"

# see colors.exs
config :applet, Applet.Server,
  port: 5999,
  colors: [
    trace: IO.ANSI.light_black(),
    debug: IO.ANSI.light_cyan(),
    info: IO.ANSI.blue(),
    warn: IO.ANSI.yellow(),
    error: IO.ANSI.light_red()
  ]

import_config "#{config_env()}.exs"
