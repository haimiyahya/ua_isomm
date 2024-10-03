defmodule UA.TxnHandler do
  @callback handle_txn(tpdu :: term, mti :: term, proc_code :: term, request :: term) ::
              {:ok, rtpdu :: term, rmti :: term, rproc_code :: term, txn_data :: term}
              | {:error, reason :: term}

  @spec __using__(any) :: Macro.t()
  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour UA.TxnHandler

      use GenServer, restart: :temporary

      defoverridable UA.TxnHandler

      @spec start_link({handler_options :: term(), GenServer.options()}) :: GenServer.on_start()
      def start_link({handler_options, genserver_options}) do
        GenServer.start_link(__MODULE__, handler_options, genserver_options)
      end

      @impl GenServer
      def init(handler_options) do
        Process.flag(:trap_exit, true)
        {:ok, {nil, handler_options}}
      end

      @impl GenServer
      def handle_call({:req_txn, tpdu, mti, proc_code, txn_data}, _from, state) do

        response_tuple = __MODULE__.handle_txn(tpdu, mti, proc_code, txn_data)

        # the format of response tuple is like this {:ok, rtpdu, rmti, rproc_code, rtxn_data}

        {:reply, response_tuple, state}
      end

      @impl GenServer
      def handle_call(:exit_txn_handler_process, _from, state) do
        {:stop, :normal, state}
      end

    end
  end
end
