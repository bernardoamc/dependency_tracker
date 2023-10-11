defmodule DependencyTracker.Javascript.Specification do
  defstruct [constraints: %{}]

  @moduledoc """
  This module is responsible for declaring a JavaScript Specification.

  A Specification in JavaScript contains constraints, which is a map holding dependency names
  as keys and its respective organization name as values.

  This module can also be used to validate a PackageDefinition struct based on a Specification.
  """

  @doc """
  Creates a new Specification struct with an empty map of constraints
  for JavaScript.

  Returns Specification
  """
  def new() do
    %__MODULE__{}
  end

  @doc """
  Creates a new Specification struct from an organization name and a list of
  dependencies.

  Each constraint is stored under a constraints key containing a map of
  dependencies as keys and organization names as values.

  Returns Specification
  """
  def new(organization, dependencies) when is_list(dependencies) do
    dependencies = Enum.reduce(dependencies, %{}, fn dependency, acc ->
      Map.put(acc, dependency, organization)
    end)

    %__MODULE__{constraints: dependencies}
  end


  @doc """
  Given a Specification struct, an organization and dependencies, adds each dependency
  to the constraints. When a dependency already exists a warning is emitted and
  the dependency is overridden.

  Returns Specification
  """
  def add_constraints(%__MODULE__{constraints: constraints} = specification, organization, dependencies) when is_list(dependencies) do
    updated_constraints = Enum.reduce(dependencies, constraints, fn dependency, acc ->
      if Map.has_key?(acc, dependency) do
        IO.puts "Dependency #{dependency} overridden"
      end

      Map.put(acc, dependency, organization)
    end)

    Map.put(specification, :constraints, updated_constraints)
  end

  @doc """
  Given a Specification struct, a dependency and an organization, finds whether
  the dependency provided is valid.

  A dependency can be valid in two scenarios:
    1. when it exists in the Specification struct and the
       organization provided matches the organization of the dependency.
    2. when it doesn't exist in the Specification struct.

  Returns {:ok, :valid_dependency}, {:ok, :not_found} or {:error, expected_organization}
  """
  def valid_dependency?(%__MODULE__{constraints: constraints}, organization, package) do
    case Map.fetch(constraints, package) do
      {:ok, expected_organization} ->
        case expected_organization == organization do
          true -> {:ok, :valid_dependency}
          false -> {:error, expected_organization}
        end
      :error -> {:ok, :not_found}
    end
  end
end
