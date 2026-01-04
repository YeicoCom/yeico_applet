import Config

config :applet, path: Path.expand("applets")
config :applet, store: Path.expand("store.cubdb")

import_config "#{config_env()}.exs"
