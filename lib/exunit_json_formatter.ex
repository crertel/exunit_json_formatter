defmodule ExUnitJsonFormatter do
  @moduledoc """
  Documentation for `ExUnitJsonFormatter`.

  For another approach that inspired some of this work, see [junit_formatter](https://github.com/victorolinasc/junit-formatter).
  """
  require Record
  use GenServer

  Record.defrecord(:jsonformat,
    modules: [],
    seed: nil,
    run_time_usecs: nil,
    async_time_usecs: nil,
    load_time_usecs: nil,
    sync_time_usecs: nil,
    total_time_usecs: nil
  )

  @type jsonformat ::
          record(:jsonformat,
            modules: [ExUnit.TestModule.t()],
            seed: any,
            run_time_usecs: non_neg_integer,
            async_time_usecs: non_neg_integer,
            load_time_usecs: non_neg_integer,
            sync_time_usecs: non_neg_integer,
            total_time_usecs: non_neg_integer
          )

  @impl true
  def init(opts) do
    {:ok, jsonformat(seed: opts[:seed])}
  end

  @impl true
  def handle_cast({:suite_started, _opts}, state) do
    # IO.inspect("Suite started")
    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:suite_finished,
         %{
           run: run_time_usecs,
           async: async_time_usecs,
           load: load_time_usecs
         }},
        state
      ) do
    # IO.inspect("Suite finished, elapsed usecs #{total_time_usecs}")
    sync_time_usecs = run_time_usecs - (async_time_usecs || 0)
    total_time_usecs = run_time_usecs + (load_time_usecs || 0)

    out_state =
      jsonformat(state,
        run_time_usecs: run_time_usecs,
        async_time_usecs: async_time_usecs,
        load_time_usecs: load_time_usecs,
        sync_time_usecs: sync_time_usecs,
        total_time_usecs: total_time_usecs
      )

    out_state
    |> state_to_map()
    |> Jason.encode!(pretty: true)
    |> IO.puts()

    {:noreply, out_state}
  end

  @impl true
  def handle_cast({:module_started, %ExUnit.TestModule{} = _test_module}, state) do
    # IO.inspect("Module started, #{test_module.name}")
    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:module_finished, %ExUnit.TestModule{} = test_module},
        jsonformat(modules: modules)
      ) do
    # IO.inspect("Module finished, #{test_module.name}")
    {:noreply, jsonformat(modules: [test_module | modules])}
  end

  def handle_cast({:test_started, %ExUnit.Test{state: nil} = _test}, config) do
    # IO.inspect("Test started, #{test.module} #{test.name}")
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: nil} = _test}, config) do
    # IO.inspect("Test finished, #{test.module} #{test.name}")
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:skip, _}} = _test}, config) do
    # IO.inspect("Test skipped, #{test.module} #{test.name}")
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:excluded, _}} = _test}, config) do
    # IO.inspect("Test excluded, #{test.module} #{test.name}")
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:failed, _failed}} = _test}, config) do
    # IO.inspect("Test failed, #{test.module} #{test.name}")
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:invalid, _module}} = _test}, config) do
    # IO.inspect("Test invalid, #{test.module} #{test.name}")
    {:noreply, config}
  end

  def handle_cast({:sigquit, _}, state), do: {:noreply, state}

  # per docs, we support these but ignore them
  def handle_cast({:case_started, _test_module}, state), do: {:noreply, state}
  def handle_cast({:case_finished, _test_module}, state), do: {:noreply, state}

  def state_to_map(
        jsonformat(
          modules: modules,
          seed: seed,
          run_time_usecs: run_time_usecs,
          async_time_usecs: async_time_usecs,
          load_time_usecs: load_time_usecs,
          sync_time_usecs: sync_time_usecs,
          total_time_usecs: total_time_usecs
        )
      ) do
    summarized_modules = Enum.map(modules, &summarize_test_module/1)

    %{
      seed: seed,
      run_time_usecs: run_time_usecs,
      async_time_usecs: async_time_usecs,
      load_time_usecs: load_time_usecs,
      sync_time_usecs: sync_time_usecs,
      total_time_usecs: total_time_usecs,
      modules: summarized_modules
    }
  end

  def summarize_test_module(%ExUnit.TestModule{} = test_module) do
    module_state = decode_test_status(test_module.state)

    summarized_tests = Enum.map(test_module.tests, &summarize_test_case/1)

    %{
      name: test_module.name,
      state: module_state,
      file: test_module.file,
      test: summarized_tests
    }
  end

  def summarize_test_case(%ExUnit.Test{} = test) do
    test_state = decode_test_status(test.state)
    line = test.tags.line
    file = test.tags.file

    %{
      name: test.name,
      module: test.module,
      state: test_state,
      time: test.time,
      file: file,
      line: line,
      tags: test.tags
    }
  end

  def decode_test_status(status) do
    case status do
      nil -> :passed
      {:excluded, _} -> :skipped
      {:failed, _} -> :failed
      {:invalid, _} -> :invalid
      {:skipped, _} -> :excluded
    end
  end
end
