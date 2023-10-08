defmodule DependencyTrackerTest do
  use ExUnit.Case
  doctest DependencyTracker

  test "detects issues between Specification and GemfileLock" do
    {:ok, gemfile_lock} = DependencyTracker.GemfileLock.parse("test/fixtures/ruby/Gemfile.lock")
    specification = DependencyTracker.Specification.new(["aasm"], "https://acme.io/basic/gems/ruby/")

    expected_issues = [
      %{
        specification_url: "https://acme.io/basic/gems/ruby/",
        dependency: "aasm",
        gemfile_lock_url: "https://rubygems.org/"
      }
    ]

    assert DependencyTracker.issues(specification, gemfile_lock) == expected_issues
  end

  test "returns empty list of issues when Specification is empty" do
    {:ok, gemfile_lock} = DependencyTracker.GemfileLock.parse("test/fixtures/ruby/Gemfile.lock")
    specification = DependencyTracker.Specification.new()

    assert DependencyTracker.issues(specification, gemfile_lock) == []
  end

  test "returns empty list of issues when specifications are met" do
    {:ok, gemfile_lock} = DependencyTracker.GemfileLock.parse("test/fixtures/ruby/Gemfile.lock")
    specification = DependencyTracker.Specification.new(["aasm"], "https://rubygems.org/")

    assert DependencyTracker.issues(specification, gemfile_lock) == []
  end
end
