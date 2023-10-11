defmodule DependencyTracker.Ruby.SpecificationTest do
  use ExUnit.Case
  doctest DependencyTracker.Ruby.Specification

  alias DependencyTracker.Ruby.Specification

  import ExUnit.CaptureIO

  test "new with no arguments creates an empty Specification" do
    assert Specification.new() == %Specification{constraints: %{}}
  end

  test "new with dependencies and a remote URL creates coinstraints for each dependency" do
    assert Specification.new(["aasm", "sidekiq"], "https://rubygems.org/") ==
      %Specification{
        constraints: %{
          "aasm" => "https://rubygems.org/",
          "sidekiq" => "https://rubygems.org/"
        }
      }
  end

  test "add_constraints adds new dependencies to a Specification" do
    specification = Specification.new(["aasm"], "https://rubygems.org/")

    assert Specification.add_constraints(specification, ["sidekiq", "puma"], "https://rubygems.org/") ==
      %Specification{
        constraints: %{
          "aasm" => "https://rubygems.org/",
          "puma" => "https://rubygems.org/",
          "sidekiq" => "https://rubygems.org/"
        }
      }
  end

  test "add_constraints overrides existing dependencies and logs warning" do
    specification = Specification.new(["aasm"], "https://rubygems.org/")

    assert with_io(fn -> Specification.add_constraints(specification, ["aasm", "puma"], "https://private.org/") end) ==
      {
        %Specification{
          constraints: %{
            "aasm" => "https://private.org/",
            "puma" => "https://private.org/"
          }
        },
        "Dependency aasm overridden\n"
      }
  end

  test "valid_dependency? returns :valid_dependency when dependency exists and remote URL matches" do
    specification = Specification.new(["aasm"], "https://rubygems.org/")

    assert Specification.valid_dependency?(specification, "https://rubygems.org/", "aasm") ==
      {:ok, :valid_dependency}
  end

  test "valid_dependency? returns :not_found when dependency does not exist" do
    specification = Specification.new(["aasm"], "https://rubygems.org/")

    assert Specification.valid_dependency?(specification, "https://rubygems.org/", "faker") ==
      {:ok, :not_found}
  end

  test "valid_dependency? returns {:error, expected_url} when dependency exists and remote URL does not match" do
    specification = Specification.new(["aasm"], "https://rubygems.org/")

    assert Specification.valid_dependency?(specification, "https://acme.io/basic/gems/ruby/", "aasm") ==
      {:error, "https://rubygems.org/"}
  end
end
