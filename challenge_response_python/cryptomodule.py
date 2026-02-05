import custom_ascon.custom_ascon as custom_ascon
import ascon
from Crypto.Hash import KMAC128

from message import BYTE_ORDER

SECRET_KEY : int = 0b1010101010101010101010101010101010101010101010101010101010101010
SECRET_KEY_BYTES : bytes = SECRET_KEY.to_bytes(16, byteorder=BYTE_ORDER)


def custom_asconHash256(message : bytes) -> bytes:
    return custom_ascon.ascon_hash(message)

def asconHash256(message : bytes) -> bytes:
    return ascon.hash(message)

def kmac128(key : bytes, message : bytes) -> bytes:
    kmac = KMAC128.new(key=key, data=message, mac_len=32)
    return kmac.digest()

def digest(nonce : bytes, custom : bool = False) -> bytes:
    return (
        custom_asconHash256(kmac128(SECRET_KEY_BYTES, nonce))
        if custom
        else asconHash256(kmac128(SECRET_KEY_BYTES, nonce))
    )

if __name__ == "__main__":
    print("Custom Ascon Hash of 'Hello, World!':", custom_asconHash256(message=b"Hello, World!").hex())
    print("Ascon Hash of 'Hello, World!':", asconHash256(message=b"Hello, World!").hex())
    print("KMAC of 'Hello, World!':", digest(nonce=b"Hello, World!").hex())
