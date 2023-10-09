defmodule DependencyTracker.Javascript.Parser do
  @moduledoc """
  Module responsible for parsing a dependency block from a String
  following a yarn.lock format.
  """

  import NimbleParsec

  # Define a module for a dependency block
  defmodule Dependency do
    defstruct name: "", full_name: "", version: "", url: "", integrity: "", dependencies: [], optional_dependencies: []
  end

  def aggregate_package([name, version]) do
    # Split name by ", " and take the last element
    # e.g. @babel/helper-plugin-utils, @babel/helper-plugin-utils@^7.0.0
    name = name |> String.split(", ") |> Enum.take(-1) |> List.first()

    # Strip out the version number from the name
    # by dropping everything after the last @ taking
    # into account that a name migjt have multiple @
    # e.g. @babel/helper-plugin-utils@^7.0.0
    segments = String.split(name, "@")

    if Enum.count(segments) >= 3 do
      full_name = segments |> Enum.drop(-1) |>Enum.join("@") |> String.trim("\"")
      [name] = full_name |> String.split("@") |>Enum.take(-1)

      %{ name: name, full_name: full_name, version: String.trim(version, "\"")}
    else
      [name, _] = segments

      %{ name: name, full_name: name, version: String.trim(version, "\"")}
    end
  end

  def aggregate_package_dep([name, version]) do
    %{ name: String.trim(name, "\""), version: String.trim(version, "\"")}
  end

  def aggregate_dependencies(dependencies), do: %{dependencies: dependencies}
  def aggregate_optional_dependencies(dependencies), do: %{optional_dependencies: dependencies}
  def aggregate_resolved([resolved]), do: %{url: String.trim(resolved, "\"")}
  def aggregate_integrity([integrity]), do: %{integrity: integrity}

  def aggregate_attributes(attributes) do
    Enum.reduce(attributes, %{}, fn attribute, acc ->
      Map.merge(acc, attribute)
    end)
  end

  line = utf8_string([not: ?\n, not: ?\r], min: 1)
  eol = choice([string("\r\n"), string("\n")])
  subdependency_name = utf8_string([not: ?\s], min: 1)

  name =
    ignore(string("  name "))
    |> concat(line)
    |> ignore(eol)

  dependency =
    line
    |> ignore(eol)
    |> concat(optional(ignore(name)))
    |> ignore(string("  version "))
    |> concat(line)
    |> ignore(eol)
    |> reduce({:aggregate_package, []})

  resolution =
    ignore(string("  resolved "))
    |> concat(line)
    |> optional(ignore(eol))
    |> reduce({:aggregate_resolved, []})

  integrity =
    ignore(string("  integrity "))
    |> concat(line)
    |> optional(ignore(eol))
    |> reduce({:aggregate_integrity, []})

  subdependency =
    ignore(string("    "))
    |> concat(subdependency_name)
    |> concat(line)
    |> optional(ignore(eol))
    |> reduce({:aggregate_package_dep, []})

  subdependencies =
    ignore(string("  dependencies:"))
    |> ignore(eol)
    |> repeat(subdependency)
    |> reduce({:aggregate_dependencies, []})

  optionalSubdependencies =
    ignore(string("  optionalDependencies:"))
    |> ignore(eol)
    |> repeat(subdependency)
    |> reduce({:aggregate_optional_dependencies, []})

  dependency_block =
    dependency
    |> concat(resolution)
    |> concat(integrity)
    |> concat(optional(subdependencies))
    |> concat(optional(optionalSubdependencies))
    |> reduce({:aggregate_attributes, []})

  defparsec(:parse, dependency_block)
end
