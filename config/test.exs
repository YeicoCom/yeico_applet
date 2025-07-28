import Config

config :applet, Applet.Server, port: 3998
config :applet, Applet.Store, table: "store_test.dets"
config :applet, Applet.Api.Ddb, table: "api_test.dets"
