defmodule EventBus.Support.Helper do
  alias EventBus.Model.Event

  defmodule InputLogger do
    require Logger

    def process({topic, id}) do
      event = EventBus.fetch_event({topic, id})
      Logger.info(fn -> "Event log for #{inspect(event)}" end)
      EventBus.mark_as_completed({__MODULE__, topic, id})
    end
  end

  defmodule Calculator do
    require Logger

    def process({:metrics_received, id}) do
      event = EventBus.fetch_event({:metrics_received, id})
      inputs = event.data
      # handle an event
      sum = Enum.reduce(inputs, 0, &(&1 + &2))
      # create a new event if necessary
      new_event = %Event{id: "E123", transaction_id: event.transaction_id,
        topic: :metrics_summed, data: {sum, inputs}, source: "Logger"}
      EventBus.notify(new_event)
      EventBus.mark_as_completed({__MODULE__, :metrics_received, id})
    end
    def process({topic, id}) do
      EventBus.mark_as_skipped({__MODULE__, topic, id})
    end
  end

  defmodule MemoryLeakerOne do
    @moduledoc """
    Adds all sums to a list without caring memory
    """

    use GenServer

    @doc false
    def start_link do
      GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    def process({:metrics_summed, id}) do
      GenServer.cast(__MODULE__, {:metrics_summed, id})
    end
    def process({topic, id}) do
      EventBus.mark_as_skipped({__MODULE__, topic, id})
    end

    def handle_cast({:metrics_summed, id}, state) do
      event = EventBus.fetch_event({:metrics_summed, id})
      new_state = [event | state]
      EventBus.mark_as_completed({__MODULE__, :metrics_summed, id})
      {:noreply, new_state}
    end
  end

  defmodule BadOne do
    def process(_, _) do
      throw "bad"
    end
  end
end
