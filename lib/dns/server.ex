defmodule DNS.Server do
  require Logger

  @moduledoc """
  TODO: docs
  TODO: convert this to a `GenServer` and do proper cleanup
  """

  @callback handle(DNS.Record.t, {:inet.ip, :inet.port}) :: DNS.Record.t

  @doc """
  TODO: docs
  """
  @spec accept(:inet.port, DNS.Server) :: no_return
  def accept(port, handler) do
    socket = Socket.UDP.open!(port)
    Logger.info "DNS Server listening at #{port}"

    accept_udp_loop(socket, handler)
  end

  @spec accept(:inet.port, DNS.Server) :: no_return
  def accept_tcp(port, handler) do
    socket = Socket.TCP.listen!(port, as: :binary, packet: 2, backlog: 10)
    Logger.info "TCP DNS Server listening at #{port}"

    accept_tcp_loop(socket, handler)
  end

  defp accept_udp_loop(socket, handler) do
    {data, client} = Socket.Datagram.recv!(socket)

    record = DNS.Record.decode(data)
    response = handler.handle(record, client)
    Socket.Datagram.send!(socket, DNS.Record.encode(response), client)

    accept_udp_loop(socket, handler)
  end

  defp accept_tcp_loop(server, handler) do
    client = Socket.TCP.accept!(server)

    spawn fn ->
      {:ok, data} = Socket.Stream.recv(client)
      record = DNS.Record.decode(data)
      response = handler.handle(record, client)
      Socket.Stream.send(client, DNS.Record.encode(response))
      Socket.Stream.close(client)
    end

    accept_tcp_loop(server, handler)
  end
end
