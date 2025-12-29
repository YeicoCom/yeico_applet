import Config

config :applet, Applet.Store, table: Path.absname("store_test.dets")
config :applet, Applet, path: Path.absname("test/applets")
