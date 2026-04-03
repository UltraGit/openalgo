# Kraken Broker Plugin (Work in Progress)

This is a stub implementation of the Kraken broker plugin for OpenAlgo.
All methods raise `NotImplementedError` — nothing will execute against real Kraken APIs until implemented.

## Status

`plugin.json` has `"enabled": false` — this plugin will not be loaded by OpenAlgo until that flag is set to `true` and `kraken` is added to `VALID_BROKERS` in `.env`.

## Structure

```
broker/kraken/
├── plugin.json              ← Broker metadata (set enabled=true when ready)
├── api/
│   ├── auth_api.py          ← API key validation against Kraken REST
│   ├── funds.py             ← Account balance and margin
│   └── order_api.py         ← Place, cancel, modify orders
├── database/
│   └── master_contract_db.py ← Asset pair list from GET /0/public/AssetPairs
├── mapping/
│   ├── order_data.py        ← OpenAlgo order schema → Kraken AddOrder params
│   └── transform_data.py    ← Kraken responses → OpenAlgo canonical format
└── streaming/
    └── __init__.py          ← WebSocket adapter stub (wss://ws.kraken.com/v2)
```

## References

- **Kraken REST API docs**: https://docs.kraken.com/rest/
- **Kraken WebSocket v2 docs**: https://docs.kraken.com/api/docs/websocket-v2/subscribe
- **Recommended SDK**: [`python-kraken-sdk`](https://github.com/btschwertfeger/python-kraken-sdk)
- **Reference OpenAlgo broker**: [`broker/zerodha/`](../zerodha/) — follow its patterns for auth, order flow, and DB schema

## Notes on Kraken vs Indian Brokers

| Topic | Indian brokers (e.g. Zerodha) | Kraken |
|---|---|---|
| Auth | OAuth2 redirect | API key + secret (generated on Kraken website) |
| Session tokens | Short-lived, need daily refresh | Long-lived API keys |
| Sandbox | N/A | No official REST sandbox — use paper mode locally |
| Order modify | Native EditOrder | Spot: cancel + re-place; Futures: native EditOrder |
| Symbol format | `NFO:NIFTY25JAN24000CE` | `XBTUSD`, `ETHUSD` (non-standard asset names) |

## Enabling the Plugin

1. Implement all `raise NotImplementedError` methods
2. Set `"enabled": true` in `plugin.json`
3. Add `kraken` to `VALID_BROKERS` in `.env`
4. Add `KRAKEN_API_KEY` and `KRAKEN_API_SECRET` to `.env`
5. Run `download_master_contract('KRAKEN')` to populate symbol data
