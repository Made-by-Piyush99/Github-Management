"""
Secure GitHub credential management using the OS Secure Credential Store (Keyring)
and AES-256-GCM Cryptographic Vault.
Never stores tokens in plaintext in SQLite, configuration files, logs, or source code.
"""

import logging
from typing import Optional, Dict, Any
from ..security.crypto_vault import CryptoVault

logger = logging.getLogger("DevSync.Auth")

SERVICE_NAME = "DevSyncStudio_GitHub"
ACCOUNT_NAME = "default_token"


class KeyringAuth:
    """Manages GitHub Personal Access Token securely using OS keyring + AES-256-GCM vault."""

    def __init__(self, service: str = SERVICE_NAME, account: str = ACCOUNT_NAME):
        self.service = service
        self.account = account
        self.vault = CryptoVault()
        self._in_memory_override: Optional[str] = None
        self._keyring_available = True

        try:
            import keyring
            self._keyring = keyring
        except Exception as e:
            logger.warning("Keyring module error: %s. Using encrypted vault.", e)
            self._keyring = None
            self._keyring_available = False

    def get_token(self) -> Optional[str]:
        """Retrieves the token from the secure credential store or encrypted vault."""
        if self._in_memory_override is not None:
            return self._in_memory_override

        # Check OS keyring first
        if self._keyring_available and self._keyring:
            try:
                token = self._keyring.get_password(self.service, self.account)
                if token and token.strip():
                    return token.strip()
            except Exception as e:
                logger.debug("Keyring retrieval fallback: %s", e)

        # Fallback to AES-256-GCM vault
        return self.vault.load_secret("github_token")

    def set_token(self, token: str) -> bool:
        """Saves the token securely into the OS credential store and AES-256-GCM vault."""
        clean = token.strip() if token else ""
        if not clean:
            return self.delete_token()

        saved = False
        if self._keyring_available and self._keyring:
            try:
                self._keyring.set_password(self.service, self.account, clean)
                logger.info("GitHub token saved securely in Windows Credential Vault.")
                saved = True
            except Exception as e:
                logger.error("Failed to save token to keyring: %s", e)

        # Always save encrypted in AES-256-GCM vault as well
        vault_saved = self.vault.save_secret("github_token", clean)
        if vault_saved:
            saved = True

        if not saved:
            self._in_memory_override = clean

        return True

    def delete_token(self) -> bool:
        """Deletes the stored token from all encrypted stores."""
        self._in_memory_override = None
        if self._keyring_available and self._keyring:
            try:
                self._keyring.delete_password(self.service, self.account)
                logger.info("GitHub token deleted from OS credential store.")
            except Exception:
                pass

        self.vault.delete_secret("github_token")
        return True

    def has_token(self) -> bool:
        """Checks if a token is configured without exposing its contents."""
        token = self.get_token()
        return bool(token)

    def get_encryption_info(self) -> Dict[str, Any]:
        """Returns diagnostic encryption metadata without secrets."""
        v_status = self.vault.get_status()
        v_status["keyring_backend"] = "Windows Credential Manager (WinVault)" if self._keyring_available else "Encrypted Vault"
        return v_status
