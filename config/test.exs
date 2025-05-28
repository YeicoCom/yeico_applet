import Config

config :applet, Applet.Server, port: 3998
config :applet, Applet.Store, table: "db_applet_store_test.dets"
config :applet, Applet.Api.Ddb, table: "db_applet_api_test.dets"
