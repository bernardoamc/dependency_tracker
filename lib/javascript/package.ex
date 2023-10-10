defmodule DependencyTracker.Javascript.Package do
  defstruct [:full_name, :org, :name, :version, :url, resolution_url: "", dependencies: [], optional_dependencies: [], integrity: ""]

  @moduledoc """
  Represents a single package and its dependencies from a Yarn package definition.
  """

  @doc """
  Parses a map into a Package struct.

  Returns a Package struct.
  """
  def new(metadata) do
    package = struct(__MODULE__, metadata)

    normalized_url = package.url
      |> String.split(package.name, parts: 2)
      |> List.first()

    normalized_url = [normalized_url, package.name] |> Enum.join("")

    %__MODULE__{package | url: normalized_url, resolution_url: package.url}
  end
end
