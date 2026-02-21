from __future__ import annotations
from enum import Enum
from typing import Literal

BYTE_ORDER : Literal["little", "big"] = "big"

class Message_Type(Enum):
    REQUEST_OPEN = 1
    CHALLENGE = 2
    CHALLENGE_ANSWER = 3
    GRANT_ACCESS = 4
    DENY_ACCESS = 5
    ERROR = 6

class Message:

    MAX_LENGTH_BYTES : int = 33

    def __init__(self, type : Message_Type, content : bytes = bytes()):
        self.type = type
        if self.type in (Message_Type.CHALLENGE, Message_Type.CHALLENGE_ANSWER):
            if len(content) > 32:
                raise ValueError("too many bytes")
            elif len(content) < 32:
                self.content = content.ljust(32, b'\0')
            else:
                self.content = content
        else:
            self.content = content

    def __repr__(self):
        return f"Message(type='{self.type}', content={self.content})"
    
    def serialize(self) -> bytes:
        result : bytes = self.type.value.to_bytes(1, BYTE_ORDER)
        if self.type in (Message_Type.CHALLENGE, Message_Type.CHALLENGE_ANSWER):
            result = result + self.content
            if (len(result) > 33):
                raise ValueError("too many bytes")
            elif (len(result) < 33):
                raise ValueError("not enough bytes")
        return result

    @staticmethod
    def deserialize(data : bytes) -> Message:
        type : Message_Type = Message_Type(data[0])
        data_bytes : bytes = data[1 : 33]
        result = Message(type, data_bytes)
        return result
    
    def __eq__(self, value: object) -> bool:
        if not isinstance(value, Message):
            return False
        return (self.type == value.type and
                self.content == value.content)
