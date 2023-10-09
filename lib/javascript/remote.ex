defmodule DependencyTracker.Javascript.Remote do
  defstruct [:name, :full_name, :version, :url, resolution_url: "", dependencies: [], optional_dependencies: [], integrity: ""]

  @moduledoc """
  Represents a single remote and its dependencies from a Yarn package definition.
  """

  @doc """
  Parses a map into a Remote struct.

  Returns a Remote struct.
  """
  def new(remote) do
    remote = struct(__MODULE__, remote)

    normalized_url = remote.url
      |> String.split(remote.name)
      |> List.first()

    normalized_url = [normalized_url, remote.name] |> Enum.join("")

    %__MODULE__{remote | url: normalized_url, resolution_url: remote.url}
  end

  @doc """
  Fetch gems belonging to the remote.

  Returns a list of library names.
  """
  def packages(%__MODULE__{dependencies: dependencies}) do
    Map.keys(dependencies)
  end
end
