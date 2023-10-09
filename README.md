# DependencyTracker

This is a small projec that aims to parse a Gemfile.lock and associate
dependencies with a remote.

## Setup

1. Clone this repository
2. Run `mix deps.get` in order to install dependencies

## Usage

1. Run `iex -S mix`

Now we can play with the application. The main module is `DependencyTracker`.

```elixir
iex(1)> {:ok, package_definition} = DependencyTracker.Ruby.PackageDefinition.parse("test/fixtures/ruby/Gemfile.lock")
{:ok, %DependencyTracker.Ruby.PackageDefinition{
  #...
}}

iex(2)> specification = DependencyTracker.Specification.new(["aasm"], "https://acme.io/basic/gems/ruby/")
%DependencyTracker.Specification{
  rules: %{"aasm" => "https://acme.io/basic/gems/ruby/"}
}

iex(3)> DependencyTracker.issues(specification, package_definition)
[
  %{
    specification_url: "https://acme.io/basic/gems/ruby/",
    dependency: "aasm",
    package_definition_url: "https://rubygems.org/"
  }
]
```
