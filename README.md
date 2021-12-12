# Runfiles

* **Compile-time safety**:
If your Bazel target compiles, it will find its runfiles at runtime.

* **Automatic cross-platform support**:
`//foo:bar` is `libbar.so` on Linux, but `bar.dll` on Windows?
With `rules_runfiles`, the runfiles path of the file will be available as a constant named after the label `//foo:bar`, which is independent of the particular target platform.

* **Support for Bazel modules**:
With Bazel's new module system (also known as bzlmod), the internal names of repositories depend on their declared versions as well as the particular way they are loaded. 
Since the names are part of the runfiles paths, these paths are no longer static and thus can no longer be hardcoded.
`rules_runfiles` uses code generation together with a naming scheme that carefully avoids the internal names of repositories to allow consistent runfiles access from modules.

* **IDE completions**: 
`rules_runfiles` translates the Bazel package structure into generated, language-specific structures that work well with IDEs.
For example, `//foo:bar` is available as `::runfiles::current_repo::foo::bar` (nested namespaces) in C++ and `Runfiles.current_repo.foo.bar` (nested classes) in Java.

The following languages are currently supported:
* C++
* Java

Support for other languages is planned, suggestions are very welcome.

## Usage

1. Create a `<lang>_runfiles` target with all the data dependencies you would 
usually specify on your `<lang>_binary` or `<lang>_library` and reference it in
the `deps` attribute. Here, `<lang>` is either `cc` (C++) or `java` (Java).

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
        ...,
    ],
    ...
)

```

Note:
* The `data` dependencies should not be repeated on `foo`.
*`foo` should not depend on the Bazel-provided runfiles libraries.
It will already have access to [slightly improved](https://github.com/bazelbuild/bazel/issues/14336) versions of these libraries through the dependency on `foo_runfiles`.
* `<lang>_runfiles` targets are only visible from the package in which they are defined.
Since they contain generated code that refers to the "current package", exposing them to other packages would lead to very confusing situations.
If there is a larger list of data dependencies shared between multiple targets in different packages, consider exporting the list via a Starlark constant in a `.bzl` file instead.

