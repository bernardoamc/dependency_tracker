# DependencyTracker

This is a small project with the goal of identifying third party dependencies being loaded from an untrusted source. The process is split in three phases:

**1. Identifying where dependencies are currently being loaded from:**

The code will parse any given `Gemfile.lock` and `yarn.lock` files in order to build data structures based on the metadata from each file.

**2. Provide a specification of where dependencies should be loaded from:**

Right now this is a manual step. See examples in the `usage` section.

**3. Run metadata fetched from lock files against specification:**

If any dependencies are not respecting the specification they will be flagged.

## Setup

1. Clone this repository
2. Run `mix deps.get` in order to install dependencies

## Usage

In order to experiment with the application load it with `iex -S mix`.

We will mostly interact with the `DependencyTracker` module to detect issues between a specification (our own rules)
and a package definition (what gets parsed from Gemfile.lock or yarn.lock). Then we will use specific modules from each
language in order to parse the package definition and create our specification. They are:

- DependencyTracker.Ruby.PackageDefinition
- DependencyTracker.Ruby.Specification
- DependencyTracker.Javascript.PackageDefinition
- DependencyTracker.Javascript.Specification

Let's see this in action:

#### Ruby

```elixir
iex(1)> {:ok, package_definition} = DependencyTracker.Ruby.PackageDefinition.parse("test/fixtures/ruby/Gemfile.lock")
{:ok, %DependencyTracker.Ruby.PackageDefinition{
  #...
}}

iex(2)> specification = DependencyTracker.Ruby.Specification.new(["aasm"], "https://acme.io/basic/gems/ruby/")
%DependencyTracker.Ruby.Specification{
  constraints: %{"aasm" => "https://acme.io/basic/gems/ruby/"}
}

iex(3)> DependencyTracker.detect_ruby_issues(specification, package_definition)
[
  %{
    expected_url: "https://acme.io/basic/gems/ruby/",
    dependency: "aasm",
    request_url: "https://rubygems.org/"
  }
]
```

#### Javascript

```elixir
iex(1)> {:ok, package_definition} = DependencyTracker.Javascript.PackageDefinition.parse("test/fixtures/javascript/yarn.lock")
{:ok, %DependencyTracker.Javascript.PackageDefinition{
  #...
}}

iex(2)> specification = DependencyTracker.Javascript.Specification.new("babel", ["yallist"])
%DependencyTracker.Javascript.Specification{
  constraints: %{"yallist" => "babel"}
}

iex(3)> DependencyTracker.detect_javascript_issues(specification, package_definition)
[
  %{
    dependency: "yallist",
    expected_org: "babel",
    requested_org: "public_npm"
  }
]
```
