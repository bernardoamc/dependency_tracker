defmodule DependencyTracker.GemfileLock.Remote do
  defstruct [:remote, :dependencies]

  def new(%{url: url, dependencies: dependencies}) do
    %__MODULE__{remote: url, dependencies: dependencies}
  end

  # Fetch the remote URL
  def url(%__MODULE__{remote: url}) do
    url
  end

  # Fetch gems belonging to the remote
  def gems(%__MODULE__{dependencies: dependencies}) do
    dependencies
    |> Enum.map(fn %{gem: %{name: name, version: _version}} -> name end)
  end

  # Fetch dependencies from a specific gem based on its name.
  #
  # Returns {:ok, dependencies} or {:error, :not_found}
  def dependencies(%__MODULE__{dependencies: dependencies}, gem) do
    case Enum.find(dependencies, fn %{gem: %{name: name}} -> name == gem end) do
      nil -> {:error, :not_found}
      %{dependencies: dependencies} -> {:ok, dependencies}
    end
  end
end
