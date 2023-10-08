defmodule DependencyTracker.GemfileLock.Remote do
  defstruct [:type, :url, :dependencies, branch: "", revision: "", ref: "", tag: "", glob: "", submodules: false]

  # Given a map with our struct fields, return a struct.
  def new(remote) do
    struct(__MODULE__, remote)
  end

  # Fetch gems belonging to the remote
  def gems(%__MODULE__{dependencies: dependencies}) do
    Map.keys(dependencies)
  end
end
