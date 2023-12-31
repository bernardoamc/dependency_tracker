defmodule DependencyTracker.Ruby.Parser do
  @moduledoc """
  Module responsible for parsing GEM and GIT blocks from a String.
  """

  import NimbleParsec

  line = utf8_string([not: ?\n, not: ?\r], min: 1)
  gem_name = utf8_string([not: ?\s], min: 1)
  gem_version = utf8_string([not: ?)], min: 1)
  eol = choice([string("\r\n"), string("\n")])

  # Gems can be specified with or without a version. Let's see both cases:
  #   - concurrent-ruby (~> 1.0)
  #   - concurrent-ruby
  #
  # We want to aggregate the gem name and version in a map. If the version is
  # not specified, we want to set it to an empty string.
  def aggregate_gem_info([gem, version]), do: %{name: gem, version: version}
  def aggregate_gem_info([gem]), do: %{name: String.trim_trailing(gem, "\n"), version: ""}

  # Gems can have sub-dependencies.
  def aggregate_gem([gem | dependencies]), do: %{gem: gem, dependencies: dependencies}

  # Aggregate the remote URL and its dependencies into a map.
  def aggregate_remote(result, type) do
    Enum.into([type | result], %{})
    |> Map.update(:submodules, false, &(&1 == "true"))
    |> Map.update(:dependencies, [], &parse_dependencies(&1))
  end

  # Given a list of dependencies from our Parser, returns a Map containing
  # the gem name as the key and a map with the version and subdependencies
  # as the value.
  #
  # Returns a Map with the format %{name: %{version: version, dependencies: dependencies}, ...}
  defp parse_dependencies(dependencies) do
    dependencies
    |> Enum.reduce(%{}, fn dependency, acc ->
      %{name: name, version: version} = dependency[:gem]
      Map.put(acc, name, %{version: version, dependencies: dependency[:dependencies]})
    end)
  end

  #############################################################################
  # GEM Block Parser
  #############################################################################
  gem_name_version =
    gem_name
    |> ignore(string(" ("))
    |> concat(gem_version)
    |> ignore(string(")"))
    |> optional(ignore(eol))

  gem_sub_dependencies =
    ignore(string("      "))
    |> concat(choice([gem_name_version, gem_name]))
    |> reduce({:aggregate_gem_info, []})

  gem =
    ignore(string("    "))
    |> concat(choice([gem_name_version, gem_name]))
    |> reduce({:aggregate_gem_info, []})

  remote =
    ignore(string("  remote: "))
    |> concat(line)
    |> unwrap_and_tag(:url)
    |> ignore(eol)

  specs =
    ignore(string("  specs:"))
    |> ignore(eol)
    |> repeat(
      gem
      |> repeat(gem_sub_dependencies)
      |> reduce({:aggregate_gem, []})
    )
    |> tag(:dependencies)

  gem_block =
    ignore(string("GEM"))
    |> ignore(eol)
    |> concat(remote)
    |> concat(specs)
    |> reduce({:aggregate_remote, [{:type, :gem}]})

  #############################################################################
  # GIT Block Parser
  #############################################################################

  revision =
    ignore(string("  revision: "))
    |> concat(line)
    |> unwrap_and_tag(:revision)
    |> ignore(eol)

  ref =
    ignore(string("  ref: "))
    |> concat(line)
    |> unwrap_and_tag(:ref)
    |> ignore(eol)

  branch =
    ignore(string("  branch: "))
    |> concat(line)
    |> unwrap_and_tag(:branch)
    |> ignore(eol)

  tag =
    ignore(string("  tag: "))
    |> concat(line)
    |> unwrap_and_tag(:tag)
    |> ignore(eol)

  glob =
    ignore(string("  glob: "))
    |> concat(line)
    |> unwrap_and_tag(:glob)
    |> ignore(eol)

  submodules =
    ignore(string("  submodules: "))
    |> concat(line)
    |> unwrap_and_tag(:submodules)
    |> ignore(eol)

  git_block =
    ignore(string("GIT"))
    |> ignore(eol)
    |> concat(remote)
    |> concat(revision)
    |> concat(optional(choice([ref, branch, tag])))
    |> concat(optional(submodules))
    |> concat(optional(glob))
    |> concat(specs)
    |> reduce({:aggregate_remote, [{:type, :git}]})

  defparsec(:parse, choice([gem_block, git_block]))
end
