defmodule DependencyTracker.Specification do
  defstruct [rules: %{}]

  @moduledoc """
  This module is responsible for declaring a Specification.

  A Specification is a set of rules that define a set of dependencies and their
  expected remote URLs. It is used to validate whether a dependency declared within
  one of our PackageDefinition structs is valid or not.
  """

  @doc """
  Creates a new Specification struct with an empty map of dependencies.
  """
  def new() do
    %__MODULE__{}
  end

  @doc """
  Creates a new Specification struct from a remote URL and a List of
  dependencies. The dependencies are stored in a map with the dependency
  name as the key and the remote URL as the value.

  Returns Specification
  """
  def new(dependencies, remote_url) when is_list(dependencies) do
    %__MODULE__{rules: Enum.reduce(dependencies, %{}, fn dependency, acc ->
      Map.put(acc, dependency, remote_url)
    end)}
  end

  @doc """
  Given a Specification struct, a remote URL and a dependency, adds the dependency
  to the rule's map if it doesn't exist. If the dependency already exists, it returns
  an error.

  Returns {:ok, specification} or {:error, reason}
  """
  def add_dependency(%__MODULE__{rules: rules}, dependency, remote_url) do
    case Map.has_key?(rules, dependency) do
      true -> {:error, :dependency_already_exists}
      false -> {:ok, %__MODULE__{rules: Map.put(rules, dependency, remote_url)}}
    end
  end

  @doc """
  Given a Specification struct, a dependency and a remote URL, finds whether
  the dependency provided is valid.

  A dependency can be valid in two scenarios:
    1. when it exists in the Specification struct and the
       remote URL provided matches the remote URL of the dependency.
    2. when it doesn't exist in the Specification struct.

  Returns {:ok, :valid_dependency}, {:ok, :not_found} or {:error, expected_remote_url}
  """
  def valid_dependency?(%__MODULE__{rules: rules}, dependency, remote_url) do
    case Map.fetch(rules, dependency) do
      {:ok, expected_url} ->
        case expected_url == remote_url do
          true -> {:ok, :valid_dependency}
          false -> {:error, expected_url}
        end
      :error -> {:ok, :not_found}
    end
  end
end
