import Config

config :applet, path: Path.expand("applets")
config :applet, store: Path.expand("store.dets")

import_config "#{config_env()}.exs"
