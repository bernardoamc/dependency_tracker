defmodule DependencyTracker.GemfileLock.Parser do
  @moduledoc false

  import NimbleParsec

  remote_url = utf8_string([not: ?\n, not: ?\r], min: 1)
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
  def aggregate_remote(result), do: Enum.into(result, %{})

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
    |> concat(remote_url)
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
    |> reduce({:aggregate_remote, []})

  #############################################################################
  # GIT Block Parser
  #############################################################################

  defparsec(:parse, gem_block)
end
