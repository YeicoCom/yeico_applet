import Config

config :applet, Applet.Server, port: 3999

import_config "#{config_env()}.exs"
