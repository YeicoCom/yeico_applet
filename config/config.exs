import Config

config :applet, Applet.Store, table: "db_applet_store.dets"
config :applet, Applet.Api.Ddb, table: "db_applet_api.dets"

# see exs/colors.exs
config :applet, Applet.Server,
  port: 3999,
  colors: [
    trace: IO.ANSI.light_black(),
    debug: IO.ANSI.light_cyan(),
    info: IO.ANSI.blue(),
    warn: IO.ANSI.yellow(),
    error: IO.ANSI.light_red()
  ]

import_config "#{config_env()}.exs"
