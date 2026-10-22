"""
Secure GitHub credential management using the OS Secure Credential Store (Keyring).
Never stores tokens in plaintext in SQLite, configuration files, logs, or source code.
"""

import logging
from typing import Optional

logger = logging.getLogger("DevSync.Auth")

SERVICE_NAME = "DevSyncStudio_GitHub"
ACCOUNT_NAME = "default_token"


class KeyringAuth:
    """Manages GitHub Personal Access Token securely using the system keyring."""

    def __init__(self, service: str = SERVICE_NAME, account: str = ACCOUNT_NAME):
        self.service = service
        self.account = account
        self._in_memory_override: Optional[str] = None
        self._keyring_available = True

        try:
            import keyring
            self._keyring = keyring
        except Exception as e:
            logger.warning("Keyring module error: %s. Using in-memory fallback.", e)
            self._keyring = None
            self._keyring_available = False

    def get_token(self) -> Optional[str]:
        """Retrieves the token from the secure credential store."""
        if self._in_memory_override is not None:
            return self._in_memory_override

        if not self._keyring_available or not self._keyring:
            return None

        try:
            token = self._keyring.get_password(self.service, self.account)
            return token.strip() if token else None
        except Exception as e:
            logger.error("Failed to retrieve token from system credential store: %s", e)
            return None

    def set_token(self, token: str) -> bool:
        """Saves the token securely into the OS credential store."""
        clean = token.strip() if token else ""
        if not clean:
            return self.delete_token()

        if self._keyring_available and self._keyring:
            try:
                self._keyring.set_password(self.service, self.account, clean)
                logger.info("GitHub token saved securely in OS credential store.")
                return True
            except Exception as e:
                logger.error("Failed to save token to system credential store: %s", e)
                # Fallback to in-memory session token if OS store fails
                self._in_memory_override = clean
                return True
        else:
            self._in_memory_override = clean
            return True

    def delete_token(self) -> bool:
        """Deletes the stored token from the OS credential store."""
        self._in_memory_override = None
        if self._keyring_available and self._keyring:
            try:
                self._keyring.delete_password(self.service, self.account)
                logger.info("GitHub token deleted from OS credential store.")
                return True
            except Exception:
                return True
        return True

    def has_token(self) -> bool:
        """Checks if a token is configured without exposing its contents."""
        token = self.get_token()
        return bool(token)
