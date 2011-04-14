SUMMARY
=======

LotoProxy is a simple TCP multiplexing proxy for Loto.
It connects with single connection to server and waits for clients.
Data received from a client is transfered to server without any modification.
Data received from a server is broadcasted to all clients.

## Requirements
* Ruby (any version)
* RubyGems
* EventMachine gem

USAGE
=====

        lotoproxy.rb [listen_ip]:listen_port connect_to_ip:connect_to_port


Simple test case
----------------

1. Clone the git repo

        git clone git://github.com/slayer/lotoproxy.git

2. Run fake server

        while sleep 1; do echo "---server restart---"; nc -l 1111; done

3. Run several fake clients

        while sleep 1; do echo "---connecting---"; nc 127.0.0.1 2222; done

3. Run proxy

        ruby lotoproxy.rb 127.0.0.1:2222 127.0.0.1:1111

5. Enjoy

