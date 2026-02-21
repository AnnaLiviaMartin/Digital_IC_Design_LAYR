from abc import ABC, abstractmethod
from typing import Any, Literal

import queue
import time

import socket

import spidev

from message import Message, Message_Type

#SPI simulation queues
MISO_QUEUE : queue.Queue[bytes] = queue.Queue()
MOSI_QUEUE : queue.Queue[bytes] = queue.Queue()

#Socket
SLAVE_LISTEN : str = "0.0.0.0"
MASTER_CONNECT : str = "127.0.0.1"
PORT : int = 31717

class CommunicationInterface(ABC):
    def __init__(self):
        self.name : Literal["slave", "master"]

    @abstractmethod
    def send(self, data : Message) -> None:
        pass

    @abstractmethod
    def receive(self) -> Message:
        pass

# undefined behaviour on same process
class SocketSimulatedSpi(CommunicationInterface):
    
    def __init__(self, name : Literal["slave", "master"], sleep_seconds_after_send : float = 1):
        self.name = name
        self.sleepSeconds : float = sleep_seconds_after_send
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        if name == "slave":
            s.bind((SLAVE_LISTEN, PORT))
            s.listen()
            self.socket : socket.socket = s
            s = s.accept()[0]
        else:
            for _ in range(8):
                try:
                    s.connect((MASTER_CONNECT, PORT))
                    break
                except ConnectionRefusedError:
                    time.sleep(0.25)
        self.conn : socket.socket = s

    def send(self, data : Message):
        self.conn.send(data.serialize())
        print_send(self, data)
        time.sleep(self.sleepSeconds)
        if self.name == "slave" and (data.type == Message_Type.GRANT_ACCESS or data.type == Message_Type.DENY_ACCESS):
            self.conn = self.socket.accept()[0]

    def receive(self):
        received = Message.deserialize(self.conn.recv(Message.MAX_LENGTH_BYTES))
        print_receive(self, received)
        return received
    
class QueueSimulatedSpi(CommunicationInterface):
    def __init__(self, name : Literal["slave", "master"], sleep_seconds_after_send : float = 1):
        self.name = name
        self.sleepSeconds : float = sleep_seconds_after_send
        self.input : queue.Queue[bytes] = (MOSI_QUEUE if name == "slave" else MISO_QUEUE)
        self.out : queue.Queue[bytes] = (MISO_QUEUE if name == "slave" else MOSI_QUEUE)

    def send(self, data : Message):
        self.input.put(data.serialize())
        print_send(self, data)
        time.sleep(self.sleepSeconds)

    def receive(self):
        received = Message.deserialize(self.out.get())
        print_receive(self, received)
        return received

class Spi(CommunicationInterface):
    def __init__(self, name : Literal["slave", "master"], bus : int = 0, device_cs : int = 0, max_speed_hz : int = 250_000, mode : int = 0b00):
        self.name = name
        spi : Any = spidev.SpiDev(0, 0)
        spi.open(bus, device_cs)
        spi.max_speed_hz = max_speed_hz
        spi.mode = mode
        self.spi : Any = spi
        self.lastResponse : bytes
    
    def send(self, data : Message):
        request : bytes = data.serialize()
        self.lastResponse = self.spi.xfer2(request)
        print_send(self, data)

    def receive(self):
        received : Message = Message.deserialize(self.lastResponse)
        print_receive(self, received)
        return received

def print_receive(com : CommunicationInterface, data : Message) -> None:
    print(f"{com.name} receives {data}")

def print_send(com : CommunicationInterface, data : Message) -> None:
    print(f"{com.name} sends {data}")

