defmodule DependencyTracker.Ruby.Specification do
  defstruct [constraints: %{}]

  @moduledoc """
  This module is responsible for declaring a Ruby Specification.

  A Specification in Ruby contains constraints, which is a map holding dependency names as keys
  and their remotes as values.

  This module can also be used to validate a PackageDefinition struct based on a Specification.
  """

  @doc """
  Creates a new Specification struct with an empty map of constraints
  for Ruby.

  Returns Specification
  """
  def new() do
    %__MODULE__{}
  end

  @doc """
  Creates a new Specification struct from a remote URL and a list of
  dependencies. Each dependency is stored in a map with the dependency
  name as the key and the remote URL as the value.

  Returns Specification
  """
  def new(dependencies, remote_url) when is_list(dependencies) do
    %__MODULE__{constraints: Enum.reduce(dependencies, %{}, fn dependency, acc ->
      Map.put(acc, dependency, remote_url)
    end)}
  end


  @doc """
  Given a Specification struct, dependencies and a remote URL, adds each dependency
  to the constraints.

  If the dependency already exists, a warning is emitted and
  the dependency is overridden.

  Returns Specification
  """
  def add_constraints(%__MODULE__{constraints: constraints} = specification, dependencies, remote_url) when is_list(dependencies) do
    updated_constraints = Enum.reduce(dependencies, constraints, fn dependency, acc ->
      if Map.has_key?(acc, dependency) do
        IO.puts "Dependency #{dependency} overridden"
      end

      Map.put(acc, dependency, remote_url)
    end)

    Map.put(specification, :constraints, updated_constraints)
  end

  @doc """
  Given a Specification struct, a dependency and its remote URL, finds whether
  the dependency provided is valid against the Specification.

  A dependency can be valid in two scenarios:
    1. when it exists in the Specification struct and the
       remote URL provided matches the remote URL of the dependency.
    2. when it doesn't exist in the Specification struct.

  Returns {:ok, :valid_dependency}, {:ok, :not_found} or {:error, expected_remote_url}
  """
  def valid_dependency?(%__MODULE__{constraints: constraints}, remote_url, gem) do
    case Map.fetch(constraints, gem) do
      {:ok, expected_url} ->
        case expected_url == remote_url do
          true -> {:ok, :valid_dependency}
          false -> {:error, expected_url}
        end
      :error -> {:ok, :not_found}
    end
  end
end
