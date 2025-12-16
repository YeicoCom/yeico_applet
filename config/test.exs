import Config

config :applet, Applet.Store, table: "store_test.dets"
config :applet, Applet.Api.Ddb, table: "api_test.dets"
config :applet, Applet, path: "#{File.cwd!()}/test/applets"
