#!/usr/bin/env ruby

require 'rubygems'
require 'logger'
require 'eventmachine'

LOGGER = Logger.new STDERR
LOGGER.level = Logger::DEBUG

class LotoProxy

  # Server: Listens for Loto Clients
  class ClientConnection < EM::Connection
    attr_accessor :client

    def post_init
      @client = Socket.unpack_sockaddr_in(get_peername).reverse.join(":")
      LOGGER.info "accepting client connection from #{@client}"
      $clients << self
    end

    def unbind
      LOGGER.debug "client #{@client} disconnected"
      $clients.delete(self)
    end


    def receive_data(data)
      LOGGER.debug "[server]: received '#{data}' from client #{@client}"
      $server_channel.push data
    end

    def send data
      LOGGER.debug "[server]: sending '#{data}' to client #{@client}"
      send_data data
    end

  end

  # Client: Connection to Main LotoServer
  class ServerConnection < EM::Connection

    def post_init
      LOGGER.debug "[client]: connected to server"
      $server = self
    end

    def receive_data data
      LOGGER.debug "[client]: received from server '#{data}'"
      $clients_channel.push data
    end

    def send data
      LOGGER.debug "[client]: sending to server '#{data}'"
      send_data data
    end
  end

  # Start Reactor!
  def self.start args
    unless args.size == 2
      LOGGER.error "Usage: #{__FILE__} <listen_ip>:<listen_port> <connect_ip>:<connect_port>"
      exit 1
    end
    loop do
      begin
        GC.start
        EM.epoll if EM.epoll?
        EM.run do
          $server = nil
          $clients = []
          $clients_channel  = EM::Channel.new
          $server_channel   = EM::Channel.new

          listen_ip, listen_port = args.first.split(":")
          listen_ip = "0.0.0.0" if listen_ip.size == 0
          listen_port = 3333    if listen_port.size == 0

          connect_ip, connect_port = args.last.split(":")
          LOGGER.info "Starting LotoProxy: listenting on #{listen_ip}:#{listen_port}, connecting to #{connect_ip}:#{connect_port}"
          EM.start_server listen_ip, listen_port.to_i, ClientConnection

          EM::connect connect_ip, connect_port.to_i, ServerConnection

          $clients_channel.subscribe do |msg|
            $clients.each{|client| client.send(msg) }
          end

          $server_channel.subscribe do |msg|
            $server.send(msg) if $server
          end

        end
      rescue Interrupt
        LOGGER.info "Shuting down..."
        exit
      rescue
        LOGGER.error $!.message
        LOGGER.error "\t" + $!.backtrace.join("\n\t")
      end
    end

  end
end

if $0 == __FILE__
  LotoProxy.start ARGV
end


