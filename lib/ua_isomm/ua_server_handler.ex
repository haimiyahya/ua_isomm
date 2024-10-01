defmodule UA.ServerHandler do
  @callback disassemble_msg(msg :: term) ::
    {:ok, tpdu :: term, mti :: term, body :: term}
    | {:error, reason :: term}

  @callback assemble_msg(tpdu :: term, mti :: term, body :: term) ::
    {:ok, msg :: term}
    | {:error, reason :: term}

  @spec __using__(any) :: Macro.t()
  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour UA.ServerHandler

      use ThousandIsland.Handler
      import MessageAccumulator

      defoverridable UA.ServerHandler

      @impl ThousandIsland.Handler
      def handle_connection(socket, state) do

        Process.register(self(), :server)
        state =
          state
          |> Map.put(:sock, socket)
          |> Map.put(:prev_message, <<>>)

        {:continue, state}
      end

      @impl ThousandIsland.Handler
      def handle_data(data, socket,
          %{prev_message: prev_message} = state) do

        {list_of_messages, extra_data} = get_message(prev_message <> data, [])
        Enum.each(list_of_messages,
          fn msg -> handle_info_tcp(msg, socket) end)

        {:continue, %{state | prev_message: extra_data} }
      end

      @impl ThousandIsland.Handler
      def handle_close(_socket, state) do
        {:continue, state}
      end

      def handle_info_tcp(raw_message, socket) do

        <<_header::size(16), data::binary>> = raw_message
        {:ok, tpdu, mti, body} = __MODULE__.disassemble_msg(data)

        txn_data = Map.put(body, :tpdu, tpdu)
        txn_data = Map.put(txn_data, :mti, mti)

        child_spec = {DMS.TxnHandler,{[],[]}}
        {:ok, pid2} = DynamicSupervisor.start_child(:super, child_spec)

        resp_data = GenServer.call(pid2, {:req_txn, txn_data})

        %{
          :tpdu => tpdu,
          :mti => mti,
          3 => resp_code
        } = resp_data

        __MODULE__.assemble_msg(tpdu, mti, resp_data)

      end

      def add_msg_header(msg_bytes) do
        msg_size = byte_size(msg_bytes)
        <<msg_size::size(16)>> <> msg_bytes
      end

      def handle_info({:forward_msg, msg}, {socket, state}) do

        ThousandIsland.Socket.send(socket, msg)

        {:noreply, {socket, state}}

      end

    end
  end
end
