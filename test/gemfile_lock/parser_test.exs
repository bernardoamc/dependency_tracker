defmodule DependencyTracker.GemfileLock.ParserTest do
  use ExUnit.Case
  doctest DependencyTracker.GemfileLock.Parser

  alias DependencyTracker.GemfileLock.Parser

  test "parse parses GEM blocks and returns that block metadata" do
    {:ok, file} = File.read("test/fixtures/ruby/gem/remote.txt")
    {:ok, [remote], "", _, _, _} = Parser.parse(file)

    assert remote == %{
      dependencies: %{
        "aasm" => %{
          dependencies: [%{name: "concurrent-ruby", version: "~> 1.0"}],
          version: "5.5.0"
        },
        "actioncable" => %{version: "7.0.7.2", dependencies: [
          %{name: "actionpack", version: "= 7.0.7.2"},
          %{name: "activesupport", version: "= 7.0.7.2"},
          %{name: "nio4r", version: "~> 2.0"},
          %{name: "websocket-driver", version: ">= 0.6.1"}
        ]},
        "actionmailbox" => %{version: "7.0.7.2", dependencies: [
          %{name: "actionpack", version: "= 7.0.7.2"},
          %{name: "activejob", version: "= 7.0.7.2"},
          %{name: "activerecord", version: "= 7.0.7.2"},
          %{name: "activestorage", version: "= 7.0.7.2"},
          %{name: "activesupport", version: "= 7.0.7.2"},
          %{name: "mail", version: ">= 2.7.1"},
          %{name: "net-imap", version: ""},
          %{name: "net-pop", version: ""},
          %{name: "net-smtp", version: ""}
        ]}
      },
      submodules: false,
      type: :gem,
      url: "https://rubygems.org/"
    }
  end

  test "parse parses GIT blocks with revision and ref" do
    {:ok, file} = File.read("test/fixtures/ruby/git/ref.txt")
    {:ok, [remote], "", _, _, _} = Parser.parse(file)

    assert remote == %{
      dependencies: %{"ferrum" => %{version: "0.13", dependencies: [
        %{name: "addressable", version: "~> 2.5"},
        %{name: "concurrent-ruby", version: "~> 1.1"},
        %{name: "webrick", version: "~> 1.7"},
        %{name: "websocket-driver", version: ">= 0.6, < 0.8"}
      ]}},
      ref: "ad5e714be9b0d8d9d9a9782782f7dbc733cf5e93",
      revision: "ad5e714be9b0d8d9d9a9782782f7dbc733cf5e93",
      submodules: false,
      type: :git,
      url: "https://github.com/acme/ferrum"
    }
  end

  test "parse parses GIT blocks with revision and branch" do
    {:ok, file} = File.read("test/fixtures/ruby/git/branch.txt")
    {:ok, [remote], "", _, _, _} = Parser.parse(file)

    assert remote == %{
      branch: "anonymous/instrument-redis",
      dependencies: %{"dl-queue" => %{version: "0.34.0", dependencies: []}},
      revision: "d5a3fd283cc43745213799637afb837582455d6a",
      submodules: false,
      type: :git,
      url: "https://github.com/acme/dl-queue.git"
    }
  end

  test "parse parses GIT blocks with revision and tag" do
    {:ok, file} = File.read("test/fixtures/ruby/git/tag.txt")
    {:ok, [remote], "", _, _, _} = Parser.parse(file)

    assert remote == %{
      dependencies: %{"httparty" => %{version: "0.13.5", dependencies: [%{name: "multi_xml", version: ">= 0.5.2"}]}},
      revision: "f4769dcbd5b74af9565228c034105fc37bf831a7",
      submodules: false,
      tag: "v0.13.5.1",
      type: :git,
      url: "https://github.com/acme/httparty.git"
    }
  end

  test "parse parses GIT blocks with revision and glob" do
    {:ok, file} = File.read("test/fixtures/ruby/git/glob.txt")
    {:ok, [remote], "", _, _, _} = Parser.parse(file)

    assert remote == %{
      branch: "main",
      dependencies: %{"markdown_extensions" => %{version: "0.1.0", dependencies: [
        %{name: "markdown", version: ">= 5.4.0"}
      ]}},
      glob: "gems/markdown_extensions/markdown_extensions.gemspec",
      revision: "1f9cd19d5001cf7ed07be5c6e4386c0ca096703c",
      submodules: false,
      type: :git,
      url: "https://github.com/acme/markdown.git"
    }
  end

  test "parse parses GIT blocks with revision and submodules" do
    {:ok, file} = File.read("test/fixtures/ruby/git/submodules.txt")
    {:ok, [remote], "", _, _, _} = Parser.parse(file)

    assert remote == %{
      branch: "acme-css-version",
      dependencies: %{"content_script_service" => %{version: "0.1.0", dependencies: [
        %{name: "msgpack", version: "~> 1.0"}
      ]}},
      revision: "54cd0c994cef8a16b432d9e35668f5b2120112a3",
      submodules: true,
      type: :git,
      url: "https://github.com/acme/css.git"
    }
  end

  test "parse parses GIT block with only revision" do
    {:ok, file} = File.read("test/fixtures/ruby/git/missing_ref.txt")
    {:ok, [remote], "", _, _, _} = Parser.parse(file)

    assert remote == %{
      dependencies: %{"rtlize" => %{version: "0.2.1", dependencies: []}},
      revision: "12ebf061fab2322e4a1e1dd08420492080011265",
      submodules: false,
      type: :git,
      url: "https://github.com/maljub01/RTLize.git"
    }
  end

  test "parse returns error when block cannot be parsed" do
    {status, _reason, _rest, _, _, _} = Parser.parse("DEPENDENCIES\n  assm")

    assert status == :error
  end
end
