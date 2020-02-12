```@meta
CurrentModule = OptionalArgChecks
```

# OptionalArgChecks

Provides two macros, [`@mark`](@ref) and [`@elide`](@ref) which give users control over
skipping arbitrary code in functions for better performance.

For convenience, this package also exports [`@argcheck`](@ref) and [`@check`](@ref) from
the package [`ArgCheck.jl`](https://github.com/jw3126/ArgCheck.jl) and provides the macro
`@skipargcheck` to skip these checks.

## API

```@index
```

```@autodocs
Modules = [OptionalArgChecks]
```
