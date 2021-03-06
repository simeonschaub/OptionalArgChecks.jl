```@meta
CurrentModule = OptionalArgChecks
```

# OptionalArgChecks

Provides two macros, [`@mark`](@ref) and [`@skip`](@ref) which give users control over
skipping arbitrary code in functions for better performance.

For convenience, this package also exports [`@argcheck`](https://github.com/jw3126/ArgCheck.jl)
and [`@check`](https://github.com/jw3126/ArgCheck.jl) from the package
[`ArgCheck.jl`](https://github.com/jw3126/ArgCheck.jl) and provides the macro
[`@skipargcheck`](@ref) to skip these checks.

!!! warning
    This package is still experimental, and there might be undiscovered bugs. Please open an issue, if you encounter any problems.

!!! warning
    Currently, `@skip` and `@skipargcheck` will not recurse through keyword arguments, due to limitations in `IRTools`.

## API

```@index
```

```@autodocs
Modules = [OptionalArgChecks]
```
