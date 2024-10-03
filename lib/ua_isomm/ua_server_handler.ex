defmodule UA.ServerHandler do
  @callback disassemble_msg(msg :: term) ::
    {:ok, tpdu :: term, mti :: term, proc_code :: term, body :: term}
    | {:error, reason :: term}

  @callback assemble_msg(tpdu :: term, mti :: term, proc_code :: term, body :: term) ::
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
          %{prev_message: prev_message, txn_handler_module: txn_handler_module} = state) do

        {list_of_messages, extra_data} = get_message(prev_message <> data, [])
        Enum.each(list_of_messages,
          fn msg -> handle_info_tcp(msg, socket, txn_handler_module) end)

        {:continue, %{state | prev_message: extra_data} }
      end

      @impl ThousandIsland.Handler
      def handle_close(_socket, state) do
        {:continue, state}
      end

      def handle_info_tcp(raw_message, socket, txn_handler_module) do

        <<_header::size(16), data::binary>> = raw_message
        {:ok, tpdu, mti, proc_code, txn_data} = __MODULE__.disassemble_msg(data)

        child_spec = {txn_handler_module,{[],[]}}
        {:ok, pid2} = DynamicSupervisor.start_child(:super, child_spec)

        resp_tuple = GenServer.call(pid2, {:req_txn, tpdu, mti, proc_code, txn_data})

        {:ok, rtpdu, rmti, rproc_code, rtxn_data} = resp_tuple

        GenServer.call(pid2, :exit_txn_handler_process)

        {:ok, msg} = __MODULE__.assemble_msg(rtpdu, rmti, rproc_code, rtxn_data)

        msg = add_msg_header(msg)

        ThousandIsland.Socket.send(socket, msg)

      end

      def add_msg_header(msg_bytes) do
        msg_size = byte_size(msg_bytes)
        <<msg_size::size(16)>> <> msg_bytes
      end

      def handle_info({:forward_msg, msg}, {socket, state}) do

        ThousandIsland.Socket.send(socket, msg)

        {:noreply, {socket, state}}

      end

      def handle_info(:exit_txn_handler_process, state) do

        {:stop, "normal exit", state}

      end

    end
  end
end
