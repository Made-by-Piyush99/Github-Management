"""
Unit tests for AES-256-GCM + Windows DPAPI CryptoVault.
Verifies encryption, decryption, and secure secret storage.
"""

import os
import tempfile
import shutil
import pytest

from backend.security.crypto_vault import CryptoVault
from backend.github.keyring_auth import KeyringAuth


@pytest.fixture
def temp_vault_dir():
    d = tempfile.mkdtemp(prefix="devsync_vault_")
    yield d
    try:
        shutil.rmtree(d, ignore_errors=True)
    except Exception:
        pass


def test_crypto_vault_encryption(temp_vault_dir):
    vault = CryptoVault(vault_dir=temp_vault_dir)
    secret = "ghp_SuperSecretGitHubToken1234567890!@#"

    # Encrypt
    encrypted = vault.encrypt(secret)
    assert encrypted != secret
    assert len(encrypted) > 20

    # Decrypt
    decrypted = vault.decrypt(encrypted)
    assert decrypted == secret


def test_crypto_vault_storage(temp_vault_dir):
    vault = CryptoVault(vault_dir=temp_vault_dir)
    key = "test_key"
    val = "token_value_abc_xyz"

    # Save
    assert vault.save_secret(key, val)

    # Load
    loaded = vault.load_secret(key)
    assert loaded == val

    # Verify file on disk is encrypted (doesn't contain plaintext secret)
    with open(vault.vault_file, "r") as f:
        raw_file = f.read()
    assert val not in raw_file

    # Delete
    assert vault.delete_secret(key)
    assert vault.load_secret(key) is None


def test_keyring_auth_encryption_status():
    auth = KeyringAuth()
    info = auth.get_encryption_info()
    assert info["enabled"] is True
    assert "AES-256-GCM" in info["algorithms"]
