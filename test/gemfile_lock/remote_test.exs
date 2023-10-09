defmodule DependencyTracker.GemfileLock.RemoteTest do
  use ExUnit.Case
  doctest DependencyTracker.GemfileLock.Remote

  test "new transforms a regular map into a struct" do
    remote = %{
      type: :gem,
      url: "https://rubygems.org/",
      dependencies: %{"aasm" => %{version: "5.0.6", dependencies: []}},
      branch: "",
      revision: "",
      ref: "",
      tag: "",
      glob: "",
      submodules: false
    }

    expected_remote = %DependencyTracker.GemfileLock.Remote{
      type: :gem,
      url: "https://rubygems.org/",
      dependencies: %{"aasm" => %{version: "5.0.6", dependencies: []}},
      branch: "",
      revision: "",
      ref: "",
      tag: "",
      glob: "",
      submodules: false
    }

    assert DependencyTracker.GemfileLock.Remote.new(remote) == expected_remote
  end

  test "gem returns a list of gem names belonging to the remote" do
    remote = %DependencyTracker.GemfileLock.Remote{
      type: :gem,
      url: "https://rubygems.org/",
      dependencies: %{
        "aasm" => %{version: "5.0.6", dependencies: []},
        "cusco" => %{version: "1.0.0", dependencies: []}
      },
      branch: "",
      revision: "",
      ref: "",
      tag: "",
      glob: "",
      submodules: false
    }

    expected_gems = ["aasm", "cusco"]

    assert Enum.sort(DependencyTracker.GemfileLock.Remote.gems(remote)) == expected_gems
  end
end
