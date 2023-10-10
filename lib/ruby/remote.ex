defmodule DependencyTracker.Ruby.Remote do
  defstruct [:type, :url, :dependencies, branch: "", revision: "", ref: "", tag: "", glob: "", submodules: false]

  @moduledoc """
  Represents a single remote and its dependencies from a Ruby package definition.

  A remote is a source of packages. For example, RubyGems.org is a remote.
  """

  @doc """
  Parses a map into a Remote struct.

  Returns a Remote struct.
  """
  def new(remote) do
    struct(__MODULE__, remote)
  end

  @doc """
  Fetch gems belonging to the remote.

  Returns a list of gem names.
  """
  def packages(%__MODULE__{dependencies: dependencies}) do
    Map.keys(dependencies)
  end
end
