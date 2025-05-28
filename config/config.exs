import Config

config :applet, Applet.Server, port: 3999
config :applet, Applet.Store, table: "db_applet_store.dets"
config :applet, Applet.Api.Ddb, table: "db_applet_api.dets"

import_config "#{config_env()}.exs"
