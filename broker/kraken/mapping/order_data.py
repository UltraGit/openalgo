"""
Kraken broker — Order schema mapping stub.

Translates an OpenAlgo order dict into the params expected by
Kraken's POST /0/private/AddOrder endpoint.

OpenAlgo order schema (input):
    {
        'symbol':      str,   # e.g. 'XBTUSD'
        'action':      str,   # 'BUY' | 'SELL'
        'quantity':    float,
        'price':       float, # 0 for market orders
        'order_type':  str,   # 'MARKET' | 'LIMIT' | 'STOPLOSS' | ...
        'product':     str,   # 'MIS' | 'CNC' | 'NRML' (map to Kraken leverage)
        'exchange':    str,   # always 'KRAKEN' for this broker
    }

Kraken AddOrder params (output):
    {
        'pair':      str,   # asset pair e.g. 'XBTUSD'
        'type':      str,   # 'buy' | 'sell'
        'ordertype': str,   # 'market' | 'limit' | 'stop-loss' | ...
        'price':     str,   # limit price (omit for market)
        'volume':    str,   # order quantity
        'leverage':  str,   # optional — e.g. '2:1'
    }

Docs: https://docs.kraken.com/rest/#tag/Trading/operation/addOrder
Reference: broker/zerodha/mapping/order_data.py
"""

ORDER_TYPE_MAP = {
    'MARKET':   'market',
    'LIMIT':    'limit',
    'STOPLOSS': 'stop-loss',
    'SL-M':     'stop-loss',
}

SIDE_MAP = {
    'BUY':  'buy',
    'SELL': 'sell',
}


def map_order_data(order: dict) -> dict:
    """
    Convert an OpenAlgo order dict to Kraken AddOrder parameters.

    Raises NotImplementedError until fully implemented.
    """
    raise NotImplementedError(
        "Kraken mapping/order_data.map_order_data() not yet implemented. "
        "Use ORDER_TYPE_MAP and SIDE_MAP above as a starting point."
    )


def reverse_map_order_data(kraken_order: dict) -> dict:
    """
    Convert a Kraken order response back to the OpenAlgo order schema.
    Used when fetching order details from the broker.
    """
    raise NotImplementedError(
        "Kraken mapping/order_data.reverse_map_order_data() not yet implemented."
    )
