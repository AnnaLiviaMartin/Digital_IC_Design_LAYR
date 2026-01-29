#Door Opener
from cryptomodule import challenge_result
from message import Message_Type, Message
from communication import CommunicationInterface, SimulatedSpi, Spi

com : CommunicationInterface = SimulatedSpi("master")

def spi_master():
    request = Message(Message_Type.REQUEST_OPEN)
    
    com.send(request)
    response = com.receive()

    if response.type != Message_Type.CHALLENGE:
        exit(-1)
        
    result = challenge_result(response.content)
    request = Message(Message_Type.CHALLENGE_ANSWER, result)

    com.send(request)
    response = com.receive()

    if response.type == Message_Type.GRANT_ACCESS:
        print("the door opener knows it opened the door")
    elif response.type == Message_Type.DENY_ACCESS:
        print("the door opener knows it didn't open the door")
    else:
        exit(-2)

if __name__ == "__main__":
    spi_master()
