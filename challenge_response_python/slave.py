#Lock
import secrets

from cryptomodule import digest
from message import Message_Type, Message
from communication import CommunicationInterface, QueueSimulatedSpi, SocketSimulatedSpi, Spi

RANDOM_BYTES_COUNT : int = 32

com : CommunicationInterface = QueueSimulatedSpi("slave")

def spi_slave():
    response : Message
    expected_result : bytes = rng()
    while True:
        request = com.receive()

        match request.type:
            case Message_Type.REQUEST_OPEN:
                random = rng()
                response = Message(Message_Type.CHALLENGE, random)
                expected_result = digest(random)
            case Message_Type.CHALLENGE_ANSWER:
                if expected_result == request.content:
                    open()
                    response = Message(Message_Type.GRANT_ACCESS)
                    expected_result = rng()
                else:
                    deny()
                    response = Message(Message_Type.DENY_ACCESS)
            case invalidPacket:
                print(f"received invalid packet {invalidPacket}")
                response = Message(Message_Type.ERROR)

        com.send(response)

def rng() -> bytes:
    return secrets.token_bytes(RANDOM_BYTES_COUNT)

def rng_int() -> int:
    return secrets.randbits(RANDOM_BYTES_COUNT * 8)

def open() -> None:
    print("the door granted access")

def deny() -> None:
    print("the door denied being opened")

if __name__ == "__main__":
    spi_slave()
    