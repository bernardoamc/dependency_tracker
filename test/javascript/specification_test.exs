defmodule DependencyTracker.Javascript.SpecificationTest do
  use ExUnit.Case
  doctest DependencyTracker.Javascript.Specification

  alias DependencyTracker.Javascript.Specification

  import ExUnit.CaptureIO

  test "new with no arguments creates an empty Specification" do
    assert Specification.new() == %Specification{constraints: %{}}
  end

  test "new with dependencies and an organization creates coinstraints for each dependency" do
    assert Specification.new("babel", ["compat-data", "core"]) ==
      %Specification{
        constraints: %{
          "compat-data" => "babel",
          "core" => "babel"
        }
      }
  end

  test "add_constraints adds new dependencies to a Specification" do
    specification = Specification.new("babel", ["compat-data", "core"])

    assert Specification.add_constraints(specification, "ampproject", ["remapping"]) ==
      %Specification{
        constraints: %{
          "compat-data" => "babel",
          "core" => "babel",
          "remapping" => "ampproject"
        }
      }
  end

  test "add_constraints overrides existing dependencies and logs warning" do
    specification = Specification.new("babel", ["compat-data", "core"])

    assert with_io(fn -> Specification.add_constraints(specification, "acme", ["core"]) end) ==
      {
        %Specification{
          constraints: %{
            "compat-data" => "babel",
            "core" => "acme",
          }
        },
        "Dependency core overridden\n"
      }
  end

  test "valid_dependency? returns :valid_dependency when dependency exists and organization matches" do
    specification = Specification.new("babel", ["compat-data", "core"])

    assert Specification.valid_dependency?(specification, "babel", "compat-data") ==
      {:ok, :valid_dependency}
  end

  test "valid_dependency? returns :not_found when dependency does not exist" do
    specification = Specification.new("babel", ["compat-data", "core"])

    assert Specification.valid_dependency?(specification, "ampproject", "remapping") ==
      {:ok, :not_found}
  end

  test "valid_dependency? returns {:error, expected_url} when dependency exists and organization does not match" do
    specification = Specification.new("babel", ["compat-data", "core"])

    assert Specification.valid_dependency?(specification, "acme", "compat-data") ==
      {:error, "babel"}
  end
end
