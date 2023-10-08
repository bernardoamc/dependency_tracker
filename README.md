# DependencyTracker

This is a small projec that aims to parse a Gemfile.lock and associate
dependencies with a remote.

## Usage

1. Clone this repository
2. Run `mix deps.get` in order to install dependencies
3. Test with `iex -S mix`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `dependency_tracker` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dependency_tracker, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/dependency_tracker>.

