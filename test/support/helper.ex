defmodule Helper do
  defmodule InputLogger do
    require Logger

    def process({event_type, inputs}) do
      Logger.info(fn -> "Event log '#{event_type}' for #{inspect(inputs)}" end)
    end
  end

  defmodule Calculator do
    require Logger

    def process({:metrics_received, inputs}) do
      # handle an event
      sum = Enum.reduce(inputs, 0, &(&1 + &2))
      # create a new event if necessary
      EventBus.notify({:metrics_summed, {sum, inputs}})
    end
    def process({_, _}),
      do: nil
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

    def process({:metrics_summed, event_data}) do
      GenServer.cast(__MODULE__, {:metrics_summed, event_data})
    end
    def process({_, _}),
      do: nil

    def handle_cast({:metrics_summed, event_data}, state) do
      {:noreply, [event_data | state]}
    end
  end

  defmodule BadOne do
    def process(_, _) do
      throw "bad"
    end
  end
end
