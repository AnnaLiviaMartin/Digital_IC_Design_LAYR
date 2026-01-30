import threading

import master, slave

master_thread = threading.Thread(target=master.spi_master)
slave_thread = threading.Thread(target=slave.spi_slave)

slave_thread.start()
master_thread.start()

master_thread.join()
