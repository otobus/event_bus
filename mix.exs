defmodule EventBus.Mixfile do
  use Mix.Project

  def project do
    [app: :event_bus,
     version: "1.0.0-beta1",
     elixir: "~> 1.5",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps(),
     dialyzer: [plt_add_deps: :transitive],
     test_coverage: [tool: ExCoveralls],
     docs: [extras: ["README.md"]]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     mod: {EventBus.Application, []}]
  end

  defp elixirc_paths(:test),
    do: ["lib", "test/support"]
  defp elixirc_paths(_),
    do: ["lib"]

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:credo, "~> 0.8.10", only: [:dev]},
      {:dialyxir, "~> 0.5.1", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.7", only: [:test]},
      {:ex_doc, "~> 0.16.2", only: [:dev]}
    ]
  end

  defp description do
    """
    Simple event bus with ETS as an event store
    """
  end

  defp package do
    [name: :event_bus,
     files: ["lib", "mix.exs", "README.md"],
     maintainers: ["Mustafa Turan"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/mustafaturan/event_bus"}]
  end
end
