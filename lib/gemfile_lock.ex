defmodule DependencyTracker.GemfileLock do
  alias DependencyTracker.GemfileLock.Parser
  alias DependencyTracker.GemfileLock.Remote

  defstruct [remotes: []]

  # Given a Gemfile.lock block, parses it and returns a new GemfileLock struct.
  # It achieves this by parsing the block using NimbleParsec and then reducing
  # the result into a struct containing a map of remote URL as keys and GemfileLock.Remote
  # structs as values. It is assumed that remote URLs are unique and won't need
  # to be deduplicated.
  #
  # Returns {:ok, GemfileLock} or {:error, reason}
  def parse_block(block) do
    case Parser.parse(block) do
      {:ok, [remote], "", _, _, _} -> {:ok, %__MODULE__{remotes: %{ remote.url => Remote.new(remote)}}}
      {:error, reason, _rest, _, _, _} -> {:error, reason}
    end
  end

  # Given the Gemfile.lock path, reads the file and returns a new GemfileLock
  # struct. It achieves this by splitting the file into blocks split on empty
  # lines and passing each block to the new/1 function. It then proceeds to
  # print any errors that occur within a block and only returns the GemfileLock
  # struct with the successful blocks.
  #
  # Returns {:ok, GemfileLock} or {:error, reason}
  def parse(path) do
    case File.read(path) do
      {:ok, contents} ->
        contents
        |> String.split("\n\n")
        |> Enum.filter(fn block -> valid_block?(block) end)
        |> Enum.reduce({:ok, %__MODULE__{remotes: %{}}}, fn block, {:ok, gemfile_lock} ->
          case parse_block(block) do
            {:ok, new_block} -> {:ok, merge(new_block, gemfile_lock)}
            {:error, reason} ->
              IO.puts("Error parsing Gemfile.lock block: #{reason}")
              {:ok, gemfile_lock}
          end
        end)
      {:error, reason} -> {:error, reason}
    end
  end

  # Given a GemfileLock struct, returns a list of all the remotes within it.
  def remotes(%__MODULE__{remotes: remotes}) do
    Map.keys(remotes)
  end

  # Given a GemfileLock struct and a remote URL, returns a list of all the gems
  # belonging to that remote.
  #
  # Returns {:ok, gems} or {:error, reason}
  def gems(%__MODULE__{remotes: remotes}, remote_url) do
    case Map.fetch(remotes, remote_url) do
      {:ok, remote} -> {:ok, Remote.gems(remote)}
      :error -> {:error, :remote_not_found}
    end
  end

  # Given a GemfileLock struct, a remote URL and a gem, finds whether the gem
  # exists in the remote. If the remote doesn't exist, it returns {:error, :remote_not_found}.
  #
  # Returns {:ok, boolean} or {:error, :remote_not_found}
  def has_gem?(%__MODULE__{remotes: remotes}, remote_url, gem) do
    case Map.fetch(remotes, remote_url) do
      {:ok, remote} -> {:ok, Remote.has_gem?(remote, gem)}
      :error -> {:error, :remote_not_found}
    end
  end

  # Given a block of text, returns true when a block start with GEM or GIT
  # and false otherwise.
  defp valid_block?(block) do
    String.starts_with?(block, "GEM") or String.starts_with?(block, "GIT")
  end

  # Given two GemfileLock structs with format %{remotes: %{remote_url => remote, ...}},
  # merges the remotes of both structs into a new GemfileLock struct. It assumes remote_urls
  # are unique and won't need to be deduplicated.
  #
  # Example:
  #   merge(%{remotes: %{"https://rubygems.org/" => remote}}, %{remotes: %{"https://npm.org/" => remote}})
  #     => %{remotes: %{"https://rubygems.org/" => remote, "https://npm.org/" => remote}}
  #
  # Returns GemfileLock
  defp merge(%__MODULE__{remotes: remotes1}, %__MODULE__{remotes: remotes2}) do
    %__MODULE__{remotes: Map.merge(remotes1, remotes2)}
  end
end
