"""
Kraken broker — Symbol / asset list stub.

Kraken REST endpoints:
  All tradeable asset pairs: GET /0/public/AssetPairs
  Single pair info:          GET /0/public/AssetPairs?pair=XBTUSD

Docs: https://docs.kraken.com/rest/#tag/Market-Data/operation/getTradableAssetPairs
Reference: broker/zerodha/database/master_contract_db.py
"""


def download_master_contract(exchange: str) -> None:
    """
    Fetch the full list of tradeable asset pairs from Kraken and populate
    the local master contract database.

    Args:
        exchange: typically 'KRAKEN' — used to namespace symbols

    Implementation notes:
    - Call GET /0/public/AssetPairs (no auth required)
    - Parse 'altname', 'base', 'quote', 'lot_decimals', 'pair_decimals'
    - Insert into the OpenAlgo master contract table via SQLAlchemy
    - This is a public endpoint — no credentials needed
    - Kraken uses non-standard asset names (e.g. XXBT for Bitcoin, ZUSD
      for USD); map these to conventional tickers if required
    """
    raise NotImplementedError(
        "Kraken master_contract_db.download_master_contract() not yet implemented. "
        "See broker/zerodha/database/master_contract_db.py for the DB schema."
    )


def search_symbols(query: str, exchange: str) -> list:
    """
    Search the local master contract table for symbols matching the query.

    Must return a list of dicts with at minimum:
        [{'symbol': str, 'name': str, 'exchange': str}, ...]
    """
    raise NotImplementedError(
        "Kraken master_contract_db.search_symbols() not yet implemented."
    )
