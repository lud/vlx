start-vlc:
  vlc --extraintf telnet --telnet-password dev --telnet-port 5555

run: (iex)
iex:
  iex --no-pry -S mix phx.server