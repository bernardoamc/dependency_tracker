defmodule DependencyTracker do
  alias DependencyTracker.Ruby
  alias DependencyTracker.Javascript

  @moduledoc """
  This module is the entry point to the application. It provides a single function
  that takes a Specification struct and a PackageDefinition struct and returns a list
  of issues detected in the PackageDefinition struct given the Specification struct.
  """

  @doc """
  Given a Ruby.Specification struct and a Ruby.PackageDefinition struct, returns a list of
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
      iex> specification = DependencyTracker.Ruby.Specification.new(["aasm"], "https://acme.io/basic/gems/ruby/")
      iex> DependencyTracker.detect_ruby_issues(specification, package_definition)
      [
        %{
          dependency: "aasm",
          expected_url: "https://acme.io/basic/gems/ruby/",
          request_url: "https://rubygems.org/"
        }
      ]
  """
  def detect_ruby_issues(%Ruby.Specification{constraints: _ } = specification, package_definition) do
    Ruby.PackageDefinition.remote_urls(package_definition)
    |> Enum.reduce([], fn remote_url, acc ->
      {:ok, gems} = Ruby.PackageDefinition.packages(package_definition, remote_url)

      Enum.reduce(gems, acc, fn gem, acc ->
        case Ruby.Specification.valid_dependency?(specification, remote_url, gem) do
          {:ok, _} -> acc
          {:error, expected_url} -> [create_ruby_issue(gem, expected_url, remote_url) | acc]
        end
      end)
    end)
  end


  @doc """
  Given a Javascript.Specification struct and a Javascript.PackageDefinition struct,
  returns a list of issues. An issue is detected when the organization of a dependency
  in the Specification struct does not match the organization of the same dependency in
  the PackageDefinition struct.

  If the organization of a dependency in the Specification struct does not exist in
  the PackageDefinition struct, it is ignored.

  When an issue is detected, a map is returned containing the dependency name,
  the organization of the dependency in the PackageDefinition struct and the organizaion
  of the dependency in the Specification struct.

  Returns a list of issues or an empty list.

  ## Examples
      iex> {:ok, package_definition} = DependencyTracker.Javascript.PackageDefinition.parse("test/fixtures/javascript/yarn.lock")
      iex> specification = DependencyTracker.Javascript.Specification.new("babel", ["yallist"])
      iex> DependencyTracker.detect_javascript_issues(specification, package_definition)
      [
        %{
          dependency: "yallist",
          expected_org: "babel",
          requested_org: "public_npm"
        }
      ]
  """
  def detect_javascript_issues(%Javascript.Specification{constraints: _ } = specification, package_definition) do
    Javascript.PackageDefinition.orgs(package_definition)
    |> Enum.reduce([], fn org, acc ->
      {:ok, packages} = Javascript.PackageDefinition.packages(package_definition, org)

      Enum.reduce(packages, acc, fn package, acc ->
        case Javascript.Specification.valid_dependency?(specification, org, package.name) do
          {:ok, _} -> acc
          {:error, expected_org} -> [create_javascript_issue(package.name, expected_org, org) | acc]
        end
      end)
    end)
  end

  defp create_ruby_issue(gem, expected_url, requested_url) do
    %{
      dependency: gem,
      expected_url: expected_url,
      request_url: requested_url
    }
  end

  defp create_javascript_issue(package, expected_org, requested_org) do
    %{
      dependency: package,
      expected_org: expected_org,
      requested_org: requested_org
    }
  end
end
