defmodule DependencyTracker.GemfileLock.Remote do
  defstruct [:type, :url, :dependencies, branch: "", revision: "", ref: "", tag: "", glob: "", submodules: false]

  # Given a map with our struct fields, return a struct.
  def new(remote) do
    struct(__MODULE__, remote)
  end

  # Fetch the remote URL
  def url(%__MODULE__{url: url}) do
    url
  end

  # Fetch gems belonging to the remote
  def gems(%__MODULE__{dependencies: dependencies}) do
    Map.keys(dependencies)
  end

  # Returns true when a gem exists in the remote and false otherwise.
  def has_gem?(%__MODULE__{dependencies: dependencies}, gem) do
    Map.has_key?(dependencies, gem)
  end

  # Fetch dependencies from a specific gem based on its name.
  #
  # Returns {:ok, dependencies} or {:error, :not_found}
  def dependencies(%__MODULE__{dependencies: dependencies}, gem) do
    case Map.fetch(dependencies, gem) do
      {:ok, %{dependencies: dependencies}} -> {:ok, dependencies}
      {:error, _} -> {:error, :not_found}
    end
  end

  # Given a Remote and a list of dependencies, returns a new List containing
  # the dependencies that are not part of the remote.
  #
  # Returns a List of the dependencies that were not found.
  def diff(%__MODULE__{dependencies: dependencies}, dependencies) do
    dependencies
    |> Enum.reject(fn dependency -> has_gem?(dependency, dependencies) end)
  end
end
