defmodule DependencyTracker.Javascript.PackageDefinitionTest do
  use ExUnit.Case
  doctest DependencyTracker.Javascript.PackageDefinition

  alias DependencyTracker.Javascript.PackageDefinition
  alias DependencyTracker.Javascript.Package

  test "parse_block accepts a String representing a dependency and returns a list of dependencies" do
    {:ok, block} = File.read("test/fixtures/javascript/public_package.lock")

    expected_package_definition = {:ok, %DependencyTracker.Javascript.PackageDefinition{
      orgs: %{"public_npm" => [%DependencyTracker.Javascript.Package{
          full_name: "yallist",
          org: "public_npm",
          name: "yallist",
          version: "4.0.0",
          url: "https://registry.yarnpkg.com/yallist",
          resolution_url: "https://registry.yarnpkg.com/yallist/-/yallist-4.0.0.tgz#9bb92790d9c0effec63be73519e11a35019a3a72",
          dependencies: [],
          optional_dependencies: [],
          integrity: "sha512-3wdGidZyq5PB084XLES5TpOSRA3wjXAlIWMhum2kRcv/41Sn2emQ0dycQW4uZXLejwKvg6EsvbdlVL+FYEct7A=="
          }
        ]
      }
    }}

    assert PackageDefinition.parse_block(block) == expected_package_definition
  end

  test "parse_block returns an error when the block cannot be parsed" do
    block_without_specs = "BROKEN_BLOCK\n"

    {status, _} = PackageDefinition.parse_block(block_without_specs)

    assert :error == status
  end

  test "parse collects parsed blocks into a PackageDefinition struct" do
    {:ok, package_definition} = PackageDefinition.parse("test/fixtures/javascript/yarn.lock")

    # Assert that orgs are not empty
    assert Enum.count(Map.keys(package_definition.orgs)) > 0

    # Assert that every org has at least one package
    assert Enum.all?(Map.values(package_definition.orgs), fn packages ->
      Enum.count(packages) > 0
    end)

    # Assert that we can have more than one package per org
    assert Enum.any?(Map.values(package_definition.orgs), fn packages ->
      Enum.count(packages) > 1
    end)
  end

  test "parse returns an error when the file cannot be read" do
    expected_package_definition = {:error, :enoent}

    assert PackageDefinition.parse("test/fixtures/javascript/yarn.lock.notfound") == expected_package_definition
  end

  test "orgs returns a list of organizations belonging to a PackageDefinition struct" do
    package_definition = %PackageDefinition{
      orgs: %{
        "public_npm" => [%Package{
          full_name: "yallist",
          org: "public_npm",
          name: "yallist",
          version: "4.0.0",
          url: "https://registry.yarnpkg.com/yallist",
          resolution_url: "https://registry.yarnpkg.com/yallist/-/yallist-4.0.0.tgz#9bb92790d9c0effec63be73519e11a35019a3a72",
          dependencies: [],
          optional_dependencies: [],
          integrity: "sha512-3wdGidZyq5PB084XLES5TpOSRA3wjXAlIWMhum2kRcv/41Sn2emQ0dycQW4uZXLejwKvg6EsvbdlVL+FYEct7A=="
        }],
        "ampproject" => [%Package{
          full_name: "@ampproject/remapping",
          org: "ampproject",
          name: "remapping",
          version: "2.1.2",
          url: "https://registry.yarnpkg.com/@ampproject/remapping",
          resolution_url: "https://registry.yarnpkg.com/@ampproject/remapping/-/remapping-2.1.2.tgz#4edca94973ded9630d20101cd8559cedb8d8bd34",
          dependencies: [
            %{name: "@jridgewell/trace-mapping", version: " \"^0.3.0"}
          ],
          optional_dependencies: [],
          integrity: "sha512-hoyByceqwKirw7w3Z7gnIIZC3Wx3J484Y3L/cMpXFbr7d9ZQj2mODrirNzcJa+SM3UlpWXYvKV4RlRpFXlWgXg=="
        }]
      }}

    assert PackageDefinition.orgs(package_definition) == ["ampproject", "public_npm"]
  end

  test "packages returns a list of packages names belonging to an organization" do
    package_definition = %PackageDefinition{
      orgs: %{
        "public_npm" => [%Package{
          full_name: "yallist",
          org: "public_npm",
          name: "yallist",
          version: "4.0.0",
          url: "https://registry.yarnpkg.com/yallist",
          resolution_url: "https://registry.yarnpkg.com/yallist/-/yallist-4.0.0.tgz#9bb92790d9c0effec63be73519e11a35019a3a72",
          dependencies: [],
          optional_dependencies: [],
          integrity: "sha512-3wdGidZyq5PB084XLES5TpOSRA3wjXAlIWMhum2kRcv/41Sn2emQ0dycQW4uZXLejwKvg6EsvbdlVL+FYEct7A=="
        }],
        "ampproject" => [%Package{
          full_name: "@ampproject/remapping",
          org: "ampproject",
          name: "remapping",
          version: "2.1.2",
          url: "https://registry.yarnpkg.com/@ampproject/remapping",
          resolution_url: "https://registry.yarnpkg.com/@ampproject/remapping/-/remapping-2.1.2.tgz#4edca94973ded9630d20101cd8559cedb8d8bd34",
          dependencies: [
            %{name: "@jridgewell/trace-mapping", version: " \"^0.3.0"}
          ],
          optional_dependencies: [],
          integrity: "sha512-hoyByceqwKirw7w3Z7gnIIZC3Wx3J484Y3L/cMpXFbr7d9ZQj2mODrirNzcJa+SM3UlpWXYvKV4RlRpFXlWgXg=="
        }]
      }}

    expected_package = %Package{
      full_name: "@ampproject/remapping",
      org: "ampproject",
      name: "remapping",
      version: "2.1.2",
      url: "https://registry.yarnpkg.com/@ampproject/remapping",
      resolution_url: "https://registry.yarnpkg.com/@ampproject/remapping/-/remapping-2.1.2.tgz#4edca94973ded9630d20101cd8559cedb8d8bd34",
      dependencies: [
        %{name: "@jridgewell/trace-mapping", version: " \"^0.3.0"}
      ],
      optional_dependencies: [],
      integrity: "sha512-hoyByceqwKirw7w3Z7gnIIZC3Wx3J484Y3L/cMpXFbr7d9ZQj2mODrirNzcJa+SM3UlpWXYvKV4RlRpFXlWgXg=="
    }

    assert PackageDefinition.packages(package_definition, "ampproject") == {:ok, [expected_package]}
  end

  test "packages returns an error when organization cannot be found" do
    assert PackageDefinition.packages(PackageDefinition.new(), "acme") == {:error, :organization_not_found}
  end
end
