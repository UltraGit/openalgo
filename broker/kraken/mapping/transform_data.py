"""
Kraken broker — Response normalisation stub.

Transforms raw Kraken API responses into the OpenAlgo canonical format
for positions, holdings, order book, and trade history.

Reference: broker/zerodha/mapping/transform_data.py
"""


def map_position_data(positions: list, open_orders: list) -> list:
    """
    Normalise Kraken open positions (GET /0/private/OpenPositions) into
    the OpenAlgo positions schema.

    OpenAlgo position schema:
        {
            'symbol':       str,
            'quantity':     float,
            'average_price':float,
            'ltp':          float,
            'pnl':          float,
            'product':      str,
        }
    """
    raise NotImplementedError(
        "Kraken transform_data.map_position_data() not yet implemented. "
        "See broker/zerodha/mapping/transform_data.py for the output schema."
    )


def map_portfolio_data(holdings: list) -> list:
    """
    Normalise Kraken account balances (GET /0/private/Balance) into
    an OpenAlgo holdings list.

    For a crypto broker, 'holdings' are equivalent to spot balances
    (assets held in the account).
    """
    raise NotImplementedError(
        "Kraken transform_data.map_portfolio_data() not yet implemented."
    )


def map_order_data(orders: list) -> list:
    """
    Normalise a list of Kraken order dicts (from OpenOrders or ClosedOrders)
    into the OpenAlgo order book schema.
    """
    raise NotImplementedError(
        "Kraken transform_data.map_order_data() not yet implemented."
    )


def map_trade_data(trades: list) -> list:
    """
    Normalise Kraken trade history (GET /0/private/TradesHistory) into
    the OpenAlgo trade history schema.
    """
    raise NotImplementedError(
        "Kraken transform_data.map_trade_data() not yet implemented."
    )
