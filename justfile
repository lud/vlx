start-vlc:
  vlc -I telnet --telnet-password dev --telnet-port 5555

iex:
  iex --no-pry -S mix phx.server