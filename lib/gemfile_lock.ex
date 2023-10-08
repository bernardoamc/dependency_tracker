defmodule DependencyTracker.GemfileLock do
  alias DependencyTracker.GemfileLock.Parser
  alias DependencyTracker.GemfileLock.Remote

  defstruct [remotes: []]

  # Given a Gemfile.lock block, parses it and returns a new GemfileLock struct.
  # It achieves this by parsing the block using NimbleParsec and then reducing
  # the result into a struct containing a list of GemfileLock.Remote structs.
  #
  # Returns {:ok, GemfileLock} or {:error, reason}
  def parse_block(block) do
    case Parser.parse(block) do
      {:ok, [remote], "", _, _, _} -> {:ok, %__MODULE__{remotes: [Remote.new(remote)]}}
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
        |> Enum.reduce({:ok, %__MODULE__{remotes: []}}, fn block, {:ok, gemfile_lock} ->
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
    remotes
    |> Enum.map(fn remote -> Remote.url(remote) end)
  end

  # Given a GemfileLock struct and a remote URL, returns a list of all the gems
  # belonging to that remote.
  #
  # Returns {:ok, gems} or {:error, reason}
  def gems(%__MODULE__{remotes: remotes}, remote_url) do
    case Enum.find(remotes, fn remote -> Remote.url(remote) == remote_url end) do
      nil -> {:error, :not_found}
      remote -> {:ok, Remote.gems(remote)}
    end
  end

  # Given a block of text, returns true when a block start with GEM or GIT
  # and false otherwise.
  defp valid_block?(block) do
    String.starts_with?(block, "GEM") or String.starts_with?(block, "GIT")
  end

  # Given two GemfileLock structs, merge them together assuming they are
  # always unique and won't need to be deduplicated.
  defp merge(%__MODULE__{remotes: remotes1}, %__MODULE__{remotes: remotes2}) do
    %__MODULE__{remotes: remotes1 ++ remotes2}
  end
end
