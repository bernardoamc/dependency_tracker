defmodule DependencyTracker.GemfileLockTest do
  use ExUnit.Case
  doctest DependencyTracker.GemfileLock

  alias DependencyTracker.GemfileLock
  alias DependencyTracker.GemfileLock.Remote

  test "parse_block accepts a String representing a GEM definition and returns a list of dependencies" do
    block = "GEM\n  remote: https://rubygems.org/\n  specs:\n    aasm (5.0.6)\n"
    expected_gemfile_lock = {:ok, %GemfileLock{
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

    assert GemfileLock.parse_block(block) == expected_gemfile_lock
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

    expected_gemfile_lock = {:ok, %GemfileLock{
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

    assert GemfileLock.parse_block(block) == expected_gemfile_lock
  end

  test "parse_block returns an error when the block cannot be parsed" do
    block_without_specs = "GEM\n  remote: https://rubygems.org/"
    expected_gemfile_lock = {:error, "Could not parse block"}

    {status, _} = GemfileLock.parse_block(block_without_specs)

    assert :error == status
  end

  test "parse filters GEM and GIT blocks from file and collects parsed blocks into a GemfileLock struct" do
    {:ok, gemfile_lock} = GemfileLock.parse("test/fixtures/ruby/Gemfile.lock")

    # Assert that remotes are not empty
    assert Enum.count(Map.values(gemfile_lock.remotes)) > 0

    # Assert that there are no other types besides :gem and :git
    assert Enum.all?(Map.values(gemfile_lock.remotes), fn remote -> remote.type == :gem or remote.type == :git end)
  end

  test "parse returns an error when the file cannot be read" do
    expected_gemfile_lock = {:error, :enoent}

    assert GemfileLock.parse("test/fixtures/ruby/Gemfile.lock.notfound") == expected_gemfile_lock
  end

  test "remote_urls returns a list of all the remote URLs within a GemfileLock struct" do
    gemfile_lock = %GemfileLock{
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

    assert Enum.sort(GemfileLock.remote_urls(gemfile_lock)) == expected_remotes
  end

  test "gems returns a list of gem names belonging to a remote URL" do
    gemfile_lock = %GemfileLock{
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

    assert GemfileLock.gems(gemfile_lock, "https://rubygems.org/") == {:ok, ["aasm"]}
  end

  test "gems returns an error when remote URL cannot be found" do
    assert GemfileLock.gems(GemfileLock.new(), "https://rubygems.org/") == {:error, :remote_not_found}
  end
end
