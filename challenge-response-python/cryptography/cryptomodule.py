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
    """
    Computes a cryptographic hash of the given message using the Ascon-Hash256 algorithm.
    
    :param variant: Hash algorithm variant to use (default: "Ascon-Hash256").
    :param hashlength: Desired output hash length in bytes (default: 32, i.e., 256-bit output).
    :param message: Input message to hash, provided as bytes.
    :param customization: Optional customization string for domain separation or personalization.
    :return: Hash output as a byte string of specified length.
    """
    return ascon_hash(message, variant, hashlength, customization)

def kmac128(key : bytes, message : bytes, outputlength = 64, customization=b"") -> bytes:
    """
    Computes a keyed message authentication code (MAC) using the KMAC128 algorithm.

    :param key: Secret key for the KMAC operation.
    :param message: Input data to be authenticated or hashed.
    :param outputlength: Desired output length of the MAC in bytes (default: 64).
    :param customization: Optional customization string for domain separation or context-specific usage.
    :return: Message authentication code (MAC) as a byte string.
    """
    kmac = KMAC128.new(key=key, data=message, mac_len=outputlength, custom=customization)
    kmac.update(message)
    return kmac.digest()

def digest(key : bytes, message : bytes) -> bytes:
    """
    Computes a combined cryptographic digest using KMAC128 followed by Ascon-Hash256.
    
    :param key: Secret key or nonce used as the KMAC128 key input.
    :param message: Input data to be hashed.
    :return: Final digest as a byte value resulting from the Ascon-Hash256 operation.
    """
    kmac_result  = kmac128(key=key, message=message)
    return hash256(message=kmac_result )

if __name__ == "__main__":
    # Example Ascon usage
    print("Ascon Hash of 'Hello, World!':", hash256(message=b"Hello, World!").hex())
    # Example KMAC usage
    print("KMAC of 'Hello, World!':", digest(key=SECRET_KEY_BYTES, message=b"Hello, World!").hex())