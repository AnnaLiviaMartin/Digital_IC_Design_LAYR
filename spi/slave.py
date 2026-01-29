#Lock
import secrets

from cryptomodule import Packet_Type, Packet, challenge_result
from communication import CommunicationInterface, SimulatedSpi, Spi

RANDOM_BYTES_COUNT = 32

com : CommunicationInterface = SimulatedSpi("slave")

def spi_slave():
    response : Packet
    expected_result : bytes = rng()
    while True:
        request = com.receive()

        if request.type == Packet_Type.REQUEST_OPEN:
            random = rng()
            response = Packet(Packet_Type.CHALLENGE, random)
            expected_result = challenge_result(random)
        elif request.type == Packet_Type.CHALLENGE_ANSWER:
            if expected_result == request.content:
                open()
                response = Packet(Packet_Type.GRANT_ACCESS)
                expected_result = rng()
            else:
                deny()
                response = Packet(Packet_Type.DENY_ACCESS)
        else:
            response = Packet(Packet_Type.ERROR)

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
    