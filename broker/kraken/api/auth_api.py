"""
Kraken broker — Authentication API stub.

Kraken uses API key + private key (secret) authentication.
No OAuth2 redirect flow — keys are generated in the Kraken web UI:
  https://www.kraken.com/u/security/api

Recommended SDK: python-kraken-sdk
  https://github.com/btschwertfeger/python-kraken-sdk

Reference implementation: broker/zerodha/api/auth_api.py
"""


def authenticate(api_key: str, api_secret: str) -> dict:
    """
    Validate Kraken API credentials by making a lightweight authenticated
    request (e.g. GET /0/private/Balance).

    Must return:
        {'status': 'success', 'data': {...}}  on success
        {'status': 'error',   'message': str} on failure

    Implementation notes:
    - Use SpotClient from python-kraken-sdk for REST calls
    - Store validated session token / client object in Flask session or
      application context for reuse across requests
    - Kraken does not issue expiring session tokens; API keys are long-lived
    """
    raise NotImplementedError(
        "Kraken auth_api.authenticate() not yet implemented. "
        "See broker/zerodha/api/auth_api.py for the expected interface."
    )


def get_auth_url() -> str:
    """
    Return the OAuth redirect URL for browser-based auth flows.

    Kraken does NOT use OAuth — this stub exists to satisfy the OpenAlgo
    broker interface. Return a suitable message or raise if called.
    """
    raise NotImplementedError(
        "Kraken uses API key auth, not OAuth. "
        "No redirect URL is needed — users generate keys at "
        "https://www.kraken.com/u/security/api and paste them into .env."
    )


def logout() -> dict:
    """
    Invalidate the current session.

    For Kraken, this is a no-op (API keys do not have server-side sessions).
    Optionally revoke the key via Kraken's API management page.
    """
    raise NotImplementedError(
        "Kraken logout() not yet implemented. "
        "Kraken API keys do not expire automatically; "
        "revoke them manually at https://www.kraken.com/u/security/api."
    )
