from abc import ABC, abstractmethod
from typing import Any, Literal

import queue
import time

import spidev
import pickle

from cryptomodule import Packet

#SPI simulation queues
MISO_QUEUE : queue.Queue[Packet] = queue.Queue()
MOSI_QUEUE : queue.Queue[Packet] = queue.Queue()

class CommunicationInterface(ABC):
    def __init__(self):
        self.name : str

    @abstractmethod
    def send(self, data : Packet) -> None:
        pass

    @abstractmethod
    def receive(self) -> Packet:
        pass

class SimulatedSpi(CommunicationInterface):
    def __init__(self, name : Literal["slave", "master"], sleep_seconds_after_send : float = 5):
        self.name = name
        self.sleepSeconds = sleep_seconds_after_send
        self.input : queue.Queue[Packet] = (MOSI_QUEUE if name == "slave" else MISO_QUEUE)
        self.out : queue.Queue[Packet] = (MISO_QUEUE if name == "slave" else MOSI_QUEUE)

    def send(self, data : Packet):
        self.input.put(data)
        print_send(self, data)
        time.sleep(self.sleepSeconds)

    def receive(self):
        received = self.out.get()
        print_receive(self, received)
        return received

class Spi(CommunicationInterface):
    def __init__(self, name : str, bus : int = 0, device_cs : int = 0, max_speed_hz : int = 500_000, mode : int = 0):
        self.name = name
        spi : Any = spidev.SpiDev()
        spi.open(bus, device_cs)
        spi.max_speed_hz = max_speed_hz
        spi.mode = mode
        self.spi : Any = spi
        self.lastResponse : bytes
    
    def send(self, data : Packet):
        request = pickle.dumps(data)
        self.lastResponse = self.spi.xfer2(request)
        print_send(self, data)

    def receive(self):
        received = pickle.loads(self.lastResponse)
        print_receive(self, received)
        return received

def print_receive(com : CommunicationInterface, data : Packet) -> None:
    print(f"{com.name} receives {data}")

def print_send(com : CommunicationInterface, data : Packet) -> None:
    print(f"{com.name} sends {data}")
