defmodule DependencyTracker.Ruby.PackageDefinitionTest do
  use ExUnit.Case
  doctest DependencyTracker.Ruby.PackageDefinition

  alias DependencyTracker.Ruby.PackageDefinition
  alias DependencyTracker.Ruby.Remote

  test "parse_block accepts a String representing a GEM definition and returns a list of dependencies" do
    block = "GEM\n  remote: https://rubygems.org/\n  specs:\n    aasm (5.0.6)\n"
    expected_package_definition = {:ok, %PackageDefinition{
      remotes: %{"https://rubygems.org/" => %Remote{
        type: :gem,
        url: "https://rubygems.org/",
        dependencies: %{"aasm" => %{version: "5.0.6", dependencies: []}},
        branch: "",
        revision: "",
        ref: "",
        tag: "",
        glob: "",
        submodules: false
      }}}}

    assert PackageDefinition.parse_block(block) == expected_package_definition
  end

  test "parse_block accepts a String representing a GIT definition and returns a list of dependencies" do
    block = """
    GIT
      remote: https://github.com/acme/dl-queue.git
      revision: d5a3fd283cc43745213799637afb837582455d6a
      branch: anonymous/instrument-redis
      specs:
        dl-queue (0.34.0)
    """

    expected_package_definition = {:ok, %PackageDefinition{
      remotes: %{"https://github.com/acme/dl-queue.git" => %Remote{
        type: :git,
        url: "https://github.com/acme/dl-queue.git",
        dependencies: %{"dl-queue" => %{version: "0.34.0", dependencies: []}},
        branch: "anonymous/instrument-redis",
        revision: "d5a3fd283cc43745213799637afb837582455d6a",
        ref: "",
        tag: "",
        glob: "",
        submodules: false
      }}}}

    assert PackageDefinition.parse_block(block) == expected_package_definition
  end

  test "parse_block returns an error when the block cannot be parsed" do
    block_without_specs = "GEM\n  remote: https://rubygems.org/"

    {status, _} = PackageDefinition.parse_block(block_without_specs)

    assert :error == status
  end

  test "parse filters GEM and GIT blocks from file and collects parsed blocks into a PackageDefinition struct" do
    {:ok, package_definition} = PackageDefinition.parse("test/fixtures/ruby/Gemfile.lock")

    # Assert that remotes are not empty
    assert Enum.count(Map.values(package_definition.remotes)) > 0

    # Assert that there are no other types besides :gem and :git
    assert Enum.all?(Map.values(package_definition.remotes), fn remote -> remote.type == :gem or remote.type == :git end)
  end

  test "parse returns an error when the file cannot be read" do
    expected_package_definition = {:error, :enoent}

    assert PackageDefinition.parse("test/fixtures/ruby/Gemfile.lock.notfound") == expected_package_definition
  end

  test "remote_urls returns a list of all the remote URLs within a PackageDefinition struct" do
    package_definition = %PackageDefinition{
      remotes: %{
        "https://rubygems.org/" => %Remote{
          type: :gem, url: "https://rubygems.org/",
          dependencies: %{"aasm" => %{version: "5.0.6", dependencies: []}},
          branch: "", revision: "", ref: "", tag: "",
          glob: "",
          submodules: false
        },
        "https://acme.io/basic/gems/ruby/" => %Remote{
          type: :gem, url: "https://acme.io/basic/gems/ruby/",
          dependencies: %{"cusco" => %{version: "1.9.5", dependencies: []}},
          branch: "", revision: "", ref: "", tag: "",
          glob: "",
          submodules: false
        },
      }}

    expected_remotes = ["https://acme.io/basic/gems/ruby/", "https://rubygems.org/"]

    assert Enum.sort(PackageDefinition.remote_urls(package_definition)) == expected_remotes
  end

  test "packages returns a list of gem names belonging to a remote URL" do
    package_definition = %PackageDefinition{
      remotes: %{
        "https://rubygems.org/" => %Remote{
          type: :gem, url: "https://rubygems.org/",
          dependencies: %{"aasm" => %{version: "5.0.6", dependencies: []}},
          branch: "", revision: "", ref: "", tag: "",
          glob: "",
          submodules: false
        },
        "https://acme.io/basic/gems/ruby/" => %Remote{
          type: :gem, url: "https://acme.io/basic/gems/ruby/",
          dependencies: %{"cusco" => %{version: "1.9.5", dependencies: []}},
          branch: "", revision: "", ref: "", tag: "",
          glob: "",
          submodules: false
        },
      }}

    assert PackageDefinition.packages(package_definition, "https://rubygems.org/") == {:ok, ["aasm"]}
  end

  test "packages returns an error when remote URL cannot be found" do
    assert PackageDefinition.packages(PackageDefinition.new(), "https://rubygems.org/") == {:error, :remote_not_found}
  end
end
