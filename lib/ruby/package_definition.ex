defmodule DependencyTracker.Ruby.PackageDefinition do
  alias DependencyTracker.Ruby.Parser
  alias DependencyTracker.Ruby.Remote

  defstruct [remotes: %{}]

  @moduledoc """
  This module is responsible for handling a Gemfile.lock file metadata.

  Currently it only supports GEM and GIT blocks.
  """

  @doc """
    Creates a new PackageDefinition struct.

    Example:
      iex> DependencyTracker.Ruby.PackageDefinition.new()
      %DependencyTracker.Ruby.PackageDefinition{remotes: %{}}
  """
  def new() do
    struct(__MODULE__)
  end

  @doc """
  Given a Gemfile.lock block, parses it and returns a new PackageDefinition struct.

  It achieves this by parsing the block using NimbleParsec and then reducing
  the result into a struct containing a map of remote URL as keys and PackageDefinition.Remote
  structs as values. It is assumed that remote URLs are unique and won't need
  to be deduplicated.

  Returns {:ok, PackageDefinition} or {:error, reason}
  """
  def parse_block(block) do
    case Parser.parse(block) do
      {:ok, [remote], "", _, _, _} -> {:ok, %__MODULE__{remotes: %{ remote.url => Remote.new(remote)}}}
      {:error, reason, _rest, _, _, _} -> {:error, reason}
    end
  end

  @doc """
  Given the Gemfile.lock path, reads the file and returns a new PackageDefinition
  struct.

  It achieves this by splitting the file into blocks split on empty
  lines and passing each block to the parse_block/1 function. It then proceeds to
  output any errors that occur within a block and only returns the PackageDefinition
  struct with successfully parsed blocks.

  Returns {:ok, PackageDefinition} or {:error, reason}
  """
  def parse(path) do
    case File.read(path) do
      {:ok, contents} ->
        contents
        |> String.split("\n\n")
        |> Enum.filter(fn block -> valid_block?(block) end)
        |> Enum.reduce({:ok, %__MODULE__{remotes: %{}}}, fn block, {:ok, package_definition} ->
          case parse_block(block) do
            {:ok, new_block} -> {:ok, merge(new_block, package_definition)}
            {:error, reason} ->
              IO.puts("Error parsing Gemfile.lock block: #{reason}")
              {:ok, package_definition}
          end
        end)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Given a PackageDefinition struct, returns a list of remote URLs.
  """
  def remote_urls(%__MODULE__{remotes: remotes}) do
    Map.keys(remotes)
  end

  @doc """
  Given a PackageDefinition struct and a remote URL, returns a list of all the gems
  belonging to that remote.

  Returns {:ok, gems} or {:error, reason}
  """
  def gems(%__MODULE__{remotes: remotes}, remote_url) do
    case Map.fetch(remotes, remote_url) do
      {:ok, remote} -> {:ok, Remote.gems(remote)}
      :error -> {:error, :remote_not_found}
    end
  end

  # Given a block of text, returns true when a block start with GEM or GIT
  # and false otherwise.
  defp valid_block?(block) do
    String.starts_with?(block, "GEM") or String.starts_with?(block, "GIT")
  end

  # Given two PackageDefinition structs with format %{remotes: %{remote_url => remote, ...}},
  # merges the remotes of both structs into a new PackageDefinition struct. It assumes remote_urls
  # are unique and won't need to be deduplicated.
  #
  # Example:
  #   merge(%{remotes: %{"https://rubygems.org/" => remote}}, %{remotes: %{"https://npm.org/" => remote}})
  #     => %{remotes: %{"https://rubygems.org/" => remote, "https://npm.org/" => remote}}
  #
  # Returns PackageDefinition
  defp merge(%__MODULE__{remotes: remotes1}, %__MODULE__{remotes: remotes2}) do
    %__MODULE__{remotes: Map.merge(remotes1, remotes2)}
  end
end
