"""
Kraken broker — WebSocket streaming stub.

Kraken provides two WebSocket endpoints:
  Public (no auth):  wss://ws.kraken.com/v2
  Private (auth):    wss://ws-auth.kraken.com/v2

Subscribable channels: ticker, trade, book, ohlc, executions (private)

Docs: https://docs.kraken.com/api/docs/websocket-v2/subscribe
Reference: broker/zerodha/streaming/ for the OpenAlgo adapter pattern
"""
