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
iex(1)> {:ok, gemfile_lock} = DependencyTracker.GemfileLock.parse("test/fixtures/Gemfile.lock")
{:ok, %DependencyTracker.GemfileLock{
  #...
}}

iex(2)> specification = DependencyTracker.Specification.new(["aasm"], "https://acme.io/basic/gems/ruby/")
%DependencyTracker.Specification{
  rules: %{"aasm" => "https://acme.io/basic/gems/ruby/"}
}

iex(3)> DependencyTracker.issues(specification, gemfile_lock)
[
  %{
    specification_url: "https://acme.io/basic/gems/ruby/",
    dependency: "aasm",
    gemfile_lock_url: "https://rubygems.org/"
  }
]
```
