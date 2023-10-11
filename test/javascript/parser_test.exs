defmodule DependencyTracker.Javascript.ParserTest do
  use ExUnit.Case
  doctest DependencyTracker.Javascript.Parser

  alias DependencyTracker.Javascript.Parser

  test "parse parses package without dependencies" do
    {:ok, file} = File.read("test/fixtures/javascript/no_dependencies.lock")
    {:ok, [package], "", _, _, _} = Parser.parse(file)

    assert package == %{
      full_name: "@babel/compat-data",
      integrity: "sha512-p8pdE6j0a29TNGebNm7NzYZWB3xVZJBZ7XGs42uAKzQo8VQ3F0By/cQCtUEABwIqw5zo6WA4NbmxsfzADzMKnQ==",
      name: "compat-data",
      org: "babel",
      url: "https://registry.yarnpkg.com/@babel/compat-data/-/compat-data-7.17.7.tgz#078d8b833fbbcc95286613be8c716cef2b519fa2",
      version: "7.17.7"
    }
  end

  test "parse parses package with dependencies" do
    {:ok, file} = File.read("test/fixtures/javascript/with_dependencies.lock")
    {:ok, [package], "", _, _, _} = Parser.parse(file)

    assert package == %{
      dependencies: [%{name: "@babel/highlight", version: "^7.16.7"}],
      full_name: "@babel/code-frame",
      integrity: "sha512-iAXqUn8IIeBTNd72xsFlgaXHkMBMt6y4HJp1tIaK465CWLT/fG1aqB7ykr95gHHmlBdGbFeWWfyB4NJJ0nmeIg==",
      name: "code-frame",
      org: "babel",
      url: "https://registry.yarnpkg.com/@babel/code-frame/-/code-frame-7.16.7.tgz#44416b6bd7624b998f5b1af5d470856c40138789",
      version: "7.16.7"
    }
  end

  test "parse parses package with optional dependencies" do
    {:ok, file} = File.read("test/fixtures/javascript/with_optional_dependencies.lock")
    {:ok, [package], "", _, _, _} = Parser.parse(file)

    assert package == %{
      dependencies: [%{name: "@types/node", version: "*"}, %{name: "playwright-core", version: "1.37.0"}],
      full_name: "@playwright/test",
      integrity: "sha512-181WBLk4SRUyH1Q96VZl7BP6HcK0b7lbdeKisn3N/vnjitk+9HbdlFz/L5fey05vxaAhldIDnzo8KUoy8S3mmQ==",
      name: "test",
      optional_dependencies: [%{name: "fsevents", version: "2.3.2"}],
      org: "playwright",
      url: "https://registry.yarnpkg.com/@playwright/test/-/test-1.37.0.tgz#5b3b60dabaabc0d5d3021fb5a5bb8250b424c71d",
      version: "1.37.0"
    }
  end

  test "parse parses package without organization and set organization as public_npm" do
    {:ok, file} = File.read("test/fixtures/javascript/public_package.lock")
    {:ok, [package], "", _, _, _} = Parser.parse(file)

    assert package == %{
      full_name: "yallist",
      integrity: "sha512-3wdGidZyq5PB084XLES5TpOSRA3wjXAlIWMhum2kRcv/41Sn2emQ0dycQW4uZXLejwKvg6EsvbdlVL+FYEct7A==",
      name: "yallist",
      org: "public_npm",
      url: "https://registry.yarnpkg.com/yallist/-/yallist-4.0.0.tgz#9bb92790d9c0effec63be73519e11a35019a3a72",
      version: "4.0.0"
    }
  end

  test "parse parses package with an organization" do
    {:ok, file} = File.read("test/fixtures/javascript/private_package.lock")
    {:ok, [package], "", _, _, _} = Parser.parse(file)

    assert package == %{
      dependencies: [%{name: "@css/core", version: "2.1.x"}],
      full_name: "@acme/css-extensions",
      integrity: "sha512-fBTo7HZPCqWSJ25ttiz+BpCcBHCBy8p/o87No/OSY4j83yA1ayxefud82dlMcoL1gLR1nRDpgvBLHYhEEGPiHg==",
      name: "css-extensions",
      org: "acme",
      url: "https://registry.yarnpkg.com/@acme/css-extensions/-/css-extensions-1.1.0.tgz#de688427931f36ceaf1f9bb1911cb4cc2de9ec3a",
      version: "1.1.0"
    }
  end
end
