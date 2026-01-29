import ascon

from message import BYTE_ORDER

SECRET_KEY : int = 0b1010101010101010101010101010101010101010101010101010101010101010
SECRET_KEY_BYTES : bytes = SECRET_KEY.to_bytes(16, byteorder=BYTE_ORDER)

def hash(message : bytes) -> bytes:
    return ascon.hash(message)

def kmac(key : bytes, message : bytes) -> bytes:
    """128 bit key, n bit message, 256bit output"""
    return ascon.mac(key, message) # placeholder

def challenge_result(message : bytes) -> bytes:
    return hash(kmac(SECRET_KEY_BYTES, message))
