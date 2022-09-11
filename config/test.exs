import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :vlx, VlxWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "M6FjgdgUZyES5RVgQPDhVMRO4SfS6iI6L/rqWzbOYZCR/5pHFazSs+p0kIUvSN7c",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
