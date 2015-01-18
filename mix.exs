defmodule YAR.Mixfile do
  use Mix.Project

  def project do
    [app: :yar,
     version: "0.1.0",
     elixir: "~> 1.0",
     description: "Yet Another Redis client (implemented in pure elixir)",
     package: package,
     deps: deps]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [{:socket, "~>0.2"},
     {:dialyze, "~>0.1.3", only: :dev},
     {:ex_doc, "~> 0.6", only: :dev}]
  end

  defp package do
    [
        files: [
                "LICENSE.txt",
                "mix.exs",
                "README.md",
                "lib"
            ],
        contributors: ["Dan Swain"],
        links: %{"github" => "https://github.com/dantswain/yar"},
        licenses: ["MIT"]
    ]
  end
end
