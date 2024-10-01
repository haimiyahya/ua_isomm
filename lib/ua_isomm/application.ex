defmodule UaIsomm.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    listening_port = Application.fetch_env!(:ua_isomm, :port)
    conn_handler_module  = Application.fetch_env!(:ua_isomm, :conn_handler_module)
    txn_handler_module  = Application.fetch_env!(:ua_isomm, :txn_handler_module)

    children = [
      {DynamicSupervisor, name: :super, strategy: :one_for_one},
      {ThousandIsland, port: listening_port, handler_module: conn_handler_module, handler_options: %{txn_handler_module: txn_handler_module}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: UaIsomm.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
