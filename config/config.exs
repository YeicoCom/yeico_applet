import Config

config :applet, path: Path.absname("applets")
config :applet, store: Path.absname("store.dets")

import_config "#{config_env()}.exs"
