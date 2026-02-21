#Door Opener
from cryptomodule import digest
from message import Message_Type, Message
from communication import CommunicationInterface, QueueSimulatedSpi, SocketSimulatedSpi, Spi

com : CommunicationInterface = QueueSimulatedSpi("master")

def spi_master():
    request = Message(Message_Type.REQUEST_OPEN)
    
    com.send(request)
    response = com.receive()

    if response.type != Message_Type.CHALLENGE:
        exit(-1)
        
    result = digest(response.content)
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
