"""
Kraken broker — Account funds / balance stub.

Kraken REST endpoint: GET /0/private/Balance
Extended balance:     GET /0/private/BalanceEx  (includes holds)
Trade balance:        GET /0/private/TradeBalance

Docs: https://docs.kraken.com/rest/#tag/Account-Data/operation/getAccountBalance
Reference: broker/zerodha/api/funds.py
"""


def get_margin_data(auth_token: str) -> dict:
    """
    Return available funds and margin details.

    Must return a dict matching the OpenAlgo funds schema:
        {
            'availablecash':   float,
            'collateral':      float,
            'utiliseddebits':  float,
        }

    Implementation notes:
    - Call GET /0/private/TradeBalance to get margin information
    - Kraken balances are per-asset (e.g. ZUSD, XXBT); map to a base
      currency (USD) before returning
    - Use python-kraken-sdk: SpotClient(key=..., secret=...).retrieve_account_balance()
    """
    raise NotImplementedError(
        "Kraken funds.get_margin_data() not yet implemented. "
        "See broker/zerodha/api/funds.py for the expected return schema."
    )
