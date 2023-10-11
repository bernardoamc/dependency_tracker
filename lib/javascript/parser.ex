defmodule DependencyTracker.Javascript.Parser do
  @moduledoc """
  Module responsible for parsing a dependency block from a String
  following a yarn.lock format.
  """

  import NimbleParsec

  # Define a module for a dependency block
  defmodule Dependency do
    defstruct full_name: "", org: "", name: "", version: "", url: "", integrity: "", dependencies: [], optional_dependencies: []
  end

  # In order to extract a package name from a dependency block
  # we reverse the String and split it by @ annd making sure
  # we have at most 3 parts.
  #
  # Examples:
  #   This package has two parts, so it will match our extract_name with an List of 2 elements
  #   - hello@^1.0.0
  #    ["0.0.1^", "olleh"]
  #   - hello
  #
  #   This package has three parts, so it will match our extract_name with an List of 3 elements
  #   ["0.0.7^", "slitu-nigulp-repleh/lebab", ""]
  #   - @babel/helper-plugin-utils@^7.0.0
  #   - @babel/helper-plugin-utils
  #
  #   This package has three parts, so it will match our extract_name with an List of 3 elements
  #   [":0.1.1", "snoisnetxe-iu-ssc/emca", ":mpn@1v-snoisnetxe-iu-ssc/emca@"]
  #   - @acme/css-ui-extensions-v1@npm:@acme/css-ui-extensions@1.1.0:
  #   - @acme/css-ui-extensions
  def extract_package_name([_version, name]) do
    name |> String.reverse()
  end

  def extract_package_name([_version, name, _alias]) do
    name = name |> String.reverse()
    "@" <> name
  end

  def split_package_namespace(["@" <> org, name]), do: [org, name]
  def split_package_namespace([name]), do: ["public_npm", name]

  def aggregate_package([name, version]) do
    full_name = name
      |> String.split(", ")
      |> Enum.take(-1)
      |> List.first()
      |> String.trim("\"")
      |> String.reverse()
      |> String.split("@", parts: 3)
      |> extract_package_name()

    [org, name] = full_name
      |> String.split("/", parts: 2)
      |> split_package_namespace()

    %{ full_name: full_name, org: org, name: name, version: String.trim(version, "\"") }
  end

  def aggregate_package_dep([name, version]) do
    %{ name: String.trim(name, "\""), version: String.replace(version, ~r/["\s]/, "", global: true)}
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
