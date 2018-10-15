defmodule EventBus.Manager.Topic do
  @moduledoc false

  ###########################################################################
  # Topic manager
  ###########################################################################

  use GenServer

  alias EventBus.Service.Topic, as: TopicService

  @typep topic :: EventBus.topic()
  @typep topics :: EventBus.topics()

  @backend TopicService

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  def init(args) do
    {:ok, args}
  end

  @doc """
  Check if the topic exists?
  It's important to keep this in blocking manner to prevent double creations in
  sub modules
  """
  @spec exist?(topic()) :: boolean()
  def exist?(topic) do
    GenServer.call(__MODULE__, {:exist?, topic})
  end

  @doc """
  Register a topic
  """
  @spec register(topic()) :: :ok
  def register(topic) do
    GenServer.call(__MODULE__, {:register, topic})
  end

  @doc """
  Unregister a topic
  """
  @spec unregister(topic()) :: :ok
  def unregister(topic) do
    GenServer.call(__MODULE__, {:unregister, topic})
  end

  ###########################################################################
  # DELEGATIONS
  ###########################################################################

  @doc """
  List all registered topics
  """
  @spec all() :: topics()
  defdelegate all,
    to: @backend,
    as: :all

  @doc """
  Register all topics from config
  """
  @spec register_from_config() :: :ok
  defdelegate register_from_config,
    to: @backend,
    as: :register_from_config

  ###########################################################################
  # PRIVATE API
  ###########################################################################

  @doc false
  @spec handle_call({:exist?, topic()}, any(), term())
    :: {:reply, boolean(), term()}
  def handle_call({:exist?, topic}, _from, state) do
    {:reply, @backend.exist?(topic), state}
  end

  @doc false
  @spec handle_call({:register, topic()}, any(), term()) :: {:reply, :ok, term()}
  def handle_call({:register, topic}, _from, state) do
    @backend.register(topic)
    {:reply, :ok, state}
  end

  @doc false
  @spec handle_call({:unregister, topic()}, any(), term())
    :: {:reply, :ok, term()}
  def handle_call({:unregister, topic}, _from, state) do
    @backend.unregister(topic)
    {:reply, :ok, state}
  end
end
