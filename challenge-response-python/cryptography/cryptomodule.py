import sys
from pathlib import Path
from pyascon.ascon import ascon_hash
from Crypto.Hash import KMAC128

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))
from message import BYTE_ORDER

SECRET_KEY : int = 0b1010101010101010101010101010101010101010101010101010101010101010
SECRET_KEY_BYTES : bytes = SECRET_KEY.to_bytes(16, byteorder=BYTE_ORDER)

def hash256(variant = "Ascon-Hash256", hashlength = 32, message = b"example", customization = b"") -> bytes:
    """Calculates the Ascon hash 256 of the given message."""
    return ascon_hash(message, variant, hashlength, customization)

def kmac128(key : bytes, message : bytes, outputlength = 64, customization=b"") -> bytes:
    """128 bit key, n bit message, 256bit output"""
    kmac = KMAC128.new(key=key, data=message, mac_len=outputlength, custom=customization)
    kmac.update(message)
    return kmac.digest()

def digest(key : bytes, message : bytes) -> bytes:
    kmac_result  = kmac128(key=key, message=message)
    return hash256(message=kmac_result )

if __name__ == "__main__":
    # Example Ascon usage
    print("Ascon Hash of 'Hello, World!':", hash256(message=b"Hello, World!").hex())
    # Example KMAC usage
    print("KMAC of 'Hello, World!':", digest(key=SECRET_KEY_BYTES, message=b"Hello, World!").hex())