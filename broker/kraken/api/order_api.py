"""
Kraken broker — Order management stub.

Kraken REST endpoints:
  Place order:   POST /0/private/AddOrder
  Cancel order:  POST /0/private/CancelOrder
  Modify order:  POST /0/private/EditOrder  (futures only; spot requires cancel+replace)
  Order info:    POST /0/private/QueryOrders
  Open orders:   GET  /0/private/OpenOrders

Docs: https://docs.kraken.com/rest/#tag/Trading
Reference: broker/zerodha/api/order_api.py
"""


def place_order(order_data: dict, auth_token: str) -> dict:
    """
    Place a new order on Kraken.

    Args:
        order_data: OpenAlgo-normalised order dict (see mapping/order_data.py)
        auth_token: authenticated session / API credentials

    Must return:
        {'status': 'success', 'orderid': str}
        {'status': 'error',   'message': str}

    Implementation notes:
    - Translate OpenAlgo order schema → Kraken params via mapping/order_data.py
    - Use SpotClient.create_order() from python-kraken-sdk
    - Kraken uses 'txid' as the order reference ID
    - For paper/sandbox mode, Kraken does not offer a sandbox REST API;
      implement a local mock or use TRADING_MODE env var to skip real calls
    """
    raise NotImplementedError(
        "Kraken order_api.place_order() not yet implemented. "
        "See broker/zerodha/api/order_api.py for the expected interface."
    )


def cancel_order(order_id: str, auth_token: str) -> dict:
    """
    Cancel an open order by Kraken txid.

    Must return:
        {'status': 'success'}
        {'status': 'error', 'message': str}
    """
    raise NotImplementedError(
        "Kraken order_api.cancel_order() not yet implemented."
    )


def modify_order(order_data: dict, auth_token: str) -> dict:
    """
    Modify an existing open order.

    Implementation notes:
    - Kraken spot does not support in-place order edits
    - Implement as cancel + re-place (atomic from the caller's perspective)
    - Kraken Futures supports EditOrder natively if that path is needed
    """
    raise NotImplementedError(
        "Kraken order_api.modify_order() not yet implemented. "
        "Kraken spot requires cancel + re-place; see the Kraken REST docs."
    )


def get_order_book(order_id: str, auth_token: str) -> dict:
    """
    Fetch details for a specific order by txid.

    Must return the OpenAlgo order status schema.
    Use POST /0/private/QueryOrders.
    """
    raise NotImplementedError(
        "Kraken order_api.get_order_book() not yet implemented."
    )


def get_open_orders(auth_token: str) -> dict:
    """
    Return all currently open orders.

    Use GET /0/private/OpenOrders.
    Normalise via mapping/transform_data.py before returning.
    """
    raise NotImplementedError(
        "Kraken order_api.get_open_orders() not yet implemented."
    )


def get_order_history(auth_token: str) -> dict:
    """
    Return completed/cancelled order history.

    Use GET /0/private/ClosedOrders.
    """
    raise NotImplementedError(
        "Kraken order_api.get_order_history() not yet implemented."
    )
