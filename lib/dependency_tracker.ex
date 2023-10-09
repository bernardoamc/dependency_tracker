defmodule DependencyTracker do
  alias DependencyTracker.Specification
  alias DependencyTracker.Ruby.PackageDefinition

  @moduledoc """
  This module is the entry point to the application. It provides a single function
  that takes a Specification struct and a PackageDefinition struct and returns a list
  of issues detected in the PackageDefinition struct given the Specification struct.
  """

  @doc """
  Given a Specification struct and a PackageDefinition struct, returns a list of
  issues. An issue is detected when the remote URL of a dependency in the Specification
  struct does not match the URL of the same dependency in the PackageDefinition struct.

  If the remote URL of a dependency in the Specification struct does not exist in
  the PackageDefinition struct, it is ignored.

  When an issue is detected, a map is returned containing the dependency name,
  the URL of the dependency in the PackageDefinition struct and the URL of the
  dependency in the Specification struct.

  Returns a list of issues or an empty list.

  ## Examples
      iex> {:ok, package_definition} = DependencyTracker.Ruby.PackageDefinition.parse("test/fixtures/ruby/Gemfile.lock")
      iex> specification = DependencyTracker.Specification.new(["aasm"], "https://acme.io/basic/gems/ruby/")
      iex> DependencyTracker.issues(specification, package_definition)
      [
        %{
          specification_url: "https://acme.io/basic/gems/ruby/",
          dependency: "aasm",
          package_definition_url: "https://rubygems.org/"
        }
      ]
  """
  def issues(specification, package_definition) do
    PackageDefinition.remote_urls(package_definition)
    |> Enum.reduce([], fn remote_url, acc ->
      {:ok, gems} = PackageDefinition.packages(package_definition, remote_url)

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
      package_definition_url: remote_url,
      specification_url: specification_url
    }
  end
end
