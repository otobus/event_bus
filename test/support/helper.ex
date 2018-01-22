defmodule EventBus.Support.Helper do
  alias EventBus.Model.Event

  defmodule InputLogger do
    @moduledoc """
    I am the logger
    """

    require Logger

    @doc false
    def process({config, topic, id}) do
      event = EventBus.fetch_event({topic, id})
      Logger.info(fn -> "Event log for #{inspect(event)}" end)
      EventBus.mark_as_completed({{__MODULE__, config}, topic, id})
    end
  end

  defmodule Calculator do
    @moduledoc """
    Brand new fun calculator
    """

    require Logger

    @doc false
    def process({config, :metrics_received, id}) do
      event = EventBus.fetch_event({:metrics_received, id})
      inputs = event.data
      # handle an event
      sum = Enum.reduce(inputs, 0, &(&1 + &2))
      # create a new event if necessary
      new_event = %Event{
        id: "E123",
        transaction_id: event.transaction_id,
        topic: :metrics_summed,
        data: {sum, inputs},
        source: "Logger"
      }

      EventBus.notify(new_event)
      EventBus.mark_as_completed({{__MODULE__, config}, :metrics_received, id})
    end

    @doc false
    def process({config, topic, id}) do
      EventBus.mark_as_skipped({{__MODULE__, config}, topic, id})
    end
  end

  defmodule AnotherCalculator do
    @moduledoc """
    Crazy calculation service
    """

    require Logger

    @doc false
    def process({:metrics_received, id}) do
      event = EventBus.fetch_event({:metrics_received, id})
      inputs = event.data
      # handle an event
      sum = Enum.reduce(inputs, 0, &(&1 + &2))
      # create a new event if necessary
      new_event = %Event{
        id: "E123",
        transaction_id: event.transaction_id,
        topic: :metrics_summed,
        data: {sum, inputs},
        source: "AnotherCalculator"
      }

      EventBus.notify(new_event)
      EventBus.mark_as_completed({__MODULE__, :metrics_received, id})
    end

    @doc false
    def process({topic, id}) do
      EventBus.mark_as_skipped({__MODULE__, topic, id})
    end
  end

  defmodule MemoryLeakerOne do
    @moduledoc """
    Adds all sums to a list without caring memory (bad one)
    """

    use GenServer

    @doc false
    def start_link do
      GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    @doc false
    def init(args) do
      {:ok, args}
    end

    @doc false
    def process({config, :metrics_summed, id}) do
      GenServer.cast(__MODULE__, {config, :metrics_summed, id})
    end

    @doc false
    def process({config, topic, id}) do
      EventBus.mark_as_skipped({{__MODULE__, config}, topic, id})
    end

    @doc false
    def handle_cast({config, :metrics_summed, id}, state) do
      event = EventBus.fetch_event({:metrics_summed, id})
      new_state = [event | state]
      EventBus.mark_as_completed({{__MODULE__, config}, :metrics_summed, id})
      {:noreply, new_state}
    end
  end

  defmodule BadOne do
    @moduledoc """
    A bad listener implementation
    """

    @doc false
    def process(_, _) do
      throw("bad")
    end
  end
end
