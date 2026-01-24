from enum import Enum
from typing import Literal
import ascon

BYTE_ORDER : Literal["little", "big"] = "big"
SECRET_KEY : int = 0b1010101010101010101010101010101010101010101010101010101010101010
SECRET_KEY_BYTES : bytes = SECRET_KEY.to_bytes(16, byteorder=BYTE_ORDER)

def hash(message : bytes) -> bytes:
    return ascon.hash(message)

def kmac(key : bytes, message : bytes) -> bytes:
    """128 bit key, n bit message, 256bit output"""
    return ascon.mac(key, message) # placeholder

def challenge_result(message : bytes) -> bytes:
    return hash(kmac(SECRET_KEY_BYTES, message))

class Packet_Type(Enum):
    REQUEST_OPEN = 1
    CHALLENGE = 2
    CHALLENGE_ANSWER = 3
    GRANT_ACCESS = 4
    DENY_ACCESS = 5
    ERROR = 6

class Packet:
    def __init__(self, type : Packet_Type, content : bytes = bytes()):
        self.type = type
        self.content = content

    def __repr__(self):
        return f"Packet(type='{self.type}', content={int.from_bytes(self.content, byteorder=BYTE_ORDER)})"
    