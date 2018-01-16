defmodule EventBus.Topic do
  @moduledoc false

  ###########################################################################
  # Topic manager
  ###########################################################################

  use GenServer

  @backend Application.get_env(:event_bus, :topic_backend,
    EventBus.Service.Topic)

  @doc false
  def start_link,
    do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc """
  Register a topic
  """
  @spec register(String.t | atom()) :: no_return()
  def register(topic),
    do: GenServer.cast(__MODULE__, {:register, topic})

  @doc """
  Unregister a topic
  """
  @spec unregister(String.t | atom()) :: no_return()
  def unregister(topic),
    do: GenServer.cast(__MODULE__, {:unregister, topic})

  ###########################################################################
  # DELEGATIONS
  ###########################################################################

  @doc """
  List all registered topics
  """
  @spec all() :: list(atom())
  defdelegate all,
    to: @backend, as: :all

  @doc """
  Check if the topic exists?
  """
  @spec exist?(String.t | atom()) :: boolean()
  defdelegate exist?(topic),
    to: @backend, as: :exist?

  @doc """
  Register all topics from config
  """
  @spec register_from_config() :: no_return()
  defdelegate register_from_config,
    to: @backend, as: :register_from_config

  ###########################################################################
  # PRIVATE API
  ###########################################################################

  @doc false
  @spec handle_cast({:register, String.t | atom()}, nil) :: no_return()
  def handle_cast({:register, topic}, state) do
    @backend.register(topic)
    {:noreply, state}
  end
  @spec handle_cast({:unregister, String.t | atom()}, nil) :: no_return()
  def handle_cast({:unregister, topic}, state) do
    @backend.unregister(topic)
    {:noreply, state}
  end
end
