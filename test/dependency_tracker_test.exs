defmodule DependencyTrackerTest do
  use ExUnit.Case
  doctest DependencyTracker

  alias DependencyTracker.Ruby
  alias DependencyTracker.Javascript

  test "detect_ruby_issues returns the list of issues between Specification and PackageDefinition" do
    {:ok, package_definition} = Ruby.PackageDefinition.parse("test/fixtures/ruby/Gemfile.lock")
    specification = Ruby.Specification.new(["aasm"], "https://acme.io/basic/gems/ruby/")

    expected_issues = [
      %{
        dependency: "aasm",
        expected_url: "https://acme.io/basic/gems/ruby/",
        request_url: "https://rubygems.org/"
      }
    ]

    assert DependencyTracker.detect_ruby_issues(specification, package_definition) == expected_issues
  end

  test "detect_ruby_issues returns empty list of issues when Specification is empty" do
    {:ok, package_definition} = Ruby.PackageDefinition.parse("test/fixtures/ruby/Gemfile.lock")
    specification = Ruby.Specification.new()

    assert DependencyTracker.detect_ruby_issues(specification, package_definition) == []
  end

  test "detect_ruby_issues returns empty list of issues when specifications are met" do
    {:ok, package_definition} = Ruby.PackageDefinition.parse("test/fixtures/ruby/Gemfile.lock")
    specification = Ruby.Specification.new(["aasm"], "https://rubygems.org/")

    assert DependencyTracker.detect_ruby_issues(specification, package_definition) == []
  end

  test "detect_javascript_issues returns the list of issues between Specification and PackageDefinition" do
    {:ok, package_definition} = Javascript.PackageDefinition.parse("test/fixtures/javascript/yarn.lock")
    specification = Javascript.Specification.new("acme", ["compat-data"])

    expected_issues = [
      %{
        dependency: "compat-data",
        expected_org: "acme",
        requested_org: "babel"
      }
    ]

    assert DependencyTracker.detect_javascript_issues(specification, package_definition) == expected_issues
  end

  test "detect_javascript_issues returns empty list of issues when Specification is empty" do
    {:ok, package_definition} = Javascript.PackageDefinition.parse("test/fixtures/javascript/yarn.lock")
    specification = Javascript.Specification.new()

    assert DependencyTracker.detect_javascript_issues(specification, package_definition) == []
  end

  test "detect_javascript_issues returns empty list of issues when specifications are met" do
    {:ok, package_definition} = Javascript.PackageDefinition.parse("test/fixtures/javascript/yarn.lock")
    specification = Javascript.Specification.new("babel", ["compat-data"])

    assert DependencyTracker.detect_javascript_issues(specification, package_definition) == []
  end
end
