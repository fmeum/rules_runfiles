# Compile-time safe runfiles access for Bazel

* **Compile-time safety**:
  If your Bazel target compiles, it will find its runfiles at runtime.

* **Automatic cross-platform support**:
  `//foo:bar` is `libbar.so` on Linux, but `bar.dll` on Windows? With rules_runfiles, the runfiles path of the file will
  be available as a constant named after the label `//foo:bar`, which is independent of the particular target platform.

* **IDE completions**:
  rules_runfiles translates the Bazel package structure into generated, language-specific structures that work well with
  IDEs. For example, `//foo:bar` is available as `::runfiles::current_repo::foo::bar` (nested namespaces) in C++
  and `JavaRunfilesTargetName.current_repo.foo.bar` (nested classes) in Java.

* **Required for Bazel modules**:
  With Bazel's new module system (also known as bzlmod), the internal names of repositories depend on their declared
  versions as well as the particular way they are loaded. Since the names are part of the runfiles paths, these paths
  are no longer static and thus can no longer be hardcoded. rules_runfiles uses code generation together with a naming
  scheme that carefully avoids the internal names of repositories to allow consistent runfiles access from modules.

The following languages are currently supported:

* C++
* Java

Support for other languages is planned, suggestions and contributions are very welcome.

## Usage

### Step 1: Declaring a `<lang>_runfiles` target

Create a `<lang>_runfiles` target with all the data dependencies you would usually specify on your `<lang>_binary`
or `<lang>_library` and reference it in the `deps` attribute. Here, `<lang>` is either `cc` (C++) or `java` (Java).

```starlark
load("@fmeum_rules_runfiles//runfiles:<lang>_defs.bzl", "<lang>_runfiles")

<lang>_runfiles(
    name = "foo_runfiles",
    data = [
        "data/test.txt",
        "data/dir",
        ":other_binary",
        "@other_repo//path/to/other:binary",
    ],     
)

<lang>_binary(
    name = "foo",
    deps = [
        ":foo_runfiles",
        ...
    ],
    ...
)

```

Note:

* Since the code generated by `rules_runfiles` uses the labels listed in the `data` attribute to refer to runfiles,
  every label must correspond to exactly one file. Rules such
  as [bazel-skylib's `select_file`](https://github.com/bazelbuild/bazel-skylib/blob/6e30a77347071ab22ce346b6d20cf8912919f644/rules/select_file.bzl#L39)
  can be used to break up targets into individual files.
* The `data` dependencies should not be repeated on the `<lang>_binary` or `<lang>_library` target.
* The `<lang>_binary` or `<lang>_library` target should not depend on the Bazel-provided runfiles libraries. It will
  already have access to [slightly improved](https://github.com/bazelbuild/bazel/issues/14336) versions of these
  libraries through the dependency on `foo_runfiles`.
* `<lang>_runfiles` targets are only visible from the package in which they are defined. Since they contain generated
  code that refers to the "current package", exposing them to other packages would lead to very confusing situations. If
  there is a larger list of data dependencies shared between multiple targets in different packages, consider exporting
  the list via a Starlark constant in a `.bzl` file instead.

### Step 2: Accessing the runfiles constants

**C++**: A `cc_runfiles` target with `name = "foo_runfiles"` provides a generated header `foo_runfiles.h` that can be
included via

```c++
#include "path/to/pkg/foo_runfiles.h"
```

This file contains a string constant for every label in the `data` attribute of the `cc_runfiles` rule, organized in
namespaces. When deriving the fully-qualified name of a constant, Bazel repositories and packages map to namespaces and
non-alphanumeric characters are replaced by underscores. There are also special namespaces for the current package, the
current repository and the main repository.

| Bazel label                | C++ constant                                   |
|----------------------------|------------------------------------------------|
| `:foo`                     | `::runfiles::current_pkg::foo`                 |
| `:dir/some-File.txt`       | `::runfiles::current_pkg::dir_some_File_txt`   |
| `//path/to/pkg:foo`        | `::runfiles::current_repo::path::to::pkg::foo` |
| `@foobar//path/to/pkg:foo` | `::runfiles::foobar::path::to::pkg::foo`       |
| `@//path/to/pkg:foo`       | `::runfiles::main_repo::path::to::pkg::foo`    |

The fully-qualified names of these constants can be shortened with `using` and `using namespace` directives.

**Java**: A `java_runfiles` target with `name = "foo_runfiles"` provides a generated class `FooRunfiles` (name converted
to CamelCase with special characters replaced with underscores). By default, this class is contained in a package
determined from the containing Bazel package by the same rules as `java_binary`'s `main_class`. It can be overriden with
the `package` attribute on `java_runfiles`.

This class contains a `String` constant for every label in the `data` attribute of the `java_runfiles` rule, organized
in nested classes. When deriving the fully-qualified name of a constant, Bazel repositories and packages map to nested
classes and non-alphanumeric characters are replaced by underscores. There are also special nested classes for the
current package, the current repository and the main repository.

| Bazel label                | Java constant                                   |
|----------------------------|-------------------------------------------------|
| `:foo`                     | `FooRunfiles.current_pkg.foo`                   |
| `:dir/some-File.txt`       | `FooRunfiles.current_pkg.dir_some_File_txt`     |
| `//path/to/pkg:foo`        | `FooRunfiles.current_repo.path.to.pkg.foo`      |
| `@foobar//path/to/pkg:foo` | `FooRunfiles.foobar.path.to.pkg.foo`            |
| `@//path/to/pkg:foo`       | `FooRunfiles.main_repo.path.to.pkg.foo`         |

The fully-qualified names of these constants can be shortened with `import static` directives.

### Step 3: Using the Bazel runfiles libraries

**C++**:
No additional dependency or include is needed to access the Bazel C++ runfiles library.
See [its main header](third_party/bazel_tools/tools/cpp/runfiles/runfiles.h) for usage instructions.

**Java**:
No additional dependency is needed to access the Bazel Java runfiles library.
See [its main source file](third_party/bazel_tools/tools/java/runfiles/Runfiles.java) for usage instructions.

## Examples

* [cc_runfiles](tests/cc_runfiles)
* [java_runfiles](tests/java_runfiles)
