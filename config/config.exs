import Config

config :applet, Applet, path: Path.absname("applets")
config :applet, Applet.Store, table: Path.absname("store.dets")

import_config "#{config_env()}.exs"
