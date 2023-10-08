defmodule DependencyTracker do
  alias DependencyTracker.Specification
  alias DependencyTracker.GemfileLock

  @moduledoc """
  Documentation for `DependencyTracker`.
  """

  @doc """
  Given a Specification struct and a GemfileLock struct, returns a list of
  issues. An issue is detected when the remote URL of a dependency in the Specification
  struct does not match the URL of the same dependency in the GemfileLock struct.

  If the remote URL of a dependency in the Specification struct does not exist in
  the GemfileLock struct, it is ignored.

  When an issue is detected, a map is returned containing the dependency name,
  the URL of the dependency in the GemfileLock struct and the URL of the
  dependency in the Specification struct.

  When no issues are detected, an empty list is returned.

  ## Examples

      iex> DependencyTracker.issues(specification, gemfile_lock)
      [
        %{
          dependency: "concurrent-ruby",
          gemfile_lock_url: "https://rubygems.org/",
          specification_url: "https://acme.io/basic/gems/ruby/"
        }
      ]
  """
  def issues(specification, gemfile_lock) do
    GemfileLock.remote_urls(gemfile_lock)
    |> Enum.reduce([], fn remote_url, acc ->
      {:ok, gems} = GemfileLock.gems(gemfile_lock, remote_url)

      Enum.reduce(gems, acc, fn gem, acc ->
        case Specification.valid_dependency?(specification, gem, remote_url) do
          {:ok, _} -> acc
          {:error, expected_url} -> [create_issue(gem, remote_url, expected_url) | acc]
        end
      end)
    end)
  end

  defp create_issue(gem, remote_url, specification_url) do
    %{
      dependency: gem,
      gemfile_lock_url: remote_url,
      specification_url: specification_url
    }
  end
end
