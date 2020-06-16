var documenterSearchIndex = {"docs":
[{"location":"index.html#","page":"Home","title":"Home","text":"CurrentModule = OptionalArgChecks","category":"page"},{"location":"index.html#OptionalArgChecks-1","page":"Home","title":"OptionalArgChecks","text":"","category":"section"},{"location":"index.html#","page":"Home","title":"Home","text":"Provides two macros, @mark and @skip which give users control over skipping arbitrary code in functions for better performance.","category":"page"},{"location":"index.html#","page":"Home","title":"Home","text":"For convenience, this package also exports @argcheck and @check from the package ArgCheck.jl and provides the macro @skipargcheck to skip these checks.","category":"page"},{"location":"index.html#API-1","page":"Home","title":"API","text":"","category":"section"},{"location":"index.html#","page":"Home","title":"Home","text":"","category":"page"},{"location":"index.html#","page":"Home","title":"Home","text":"Modules = [OptionalArgChecks]","category":"page"},{"location":"index.html#OptionalArgChecks.@mark-Tuple{Any,Any}","page":"Home","title":"OptionalArgChecks.@mark","text":"@mark label ex\n\nMarks ex as an optional argument check, so when a function is called via @skip with label label, ex will be omitted.\n\njulia> function half(x::Integer)\n           @mark check_even iseven(x) || throw(DomainError(x, \"x has to be an even number\"))\n           return x ÷ 2\n       end\nhalf (generic function with 1 method)\n\njulia> half(4)\n2\n\njulia> half(3)\nERROR: DomainError with 3:\nx has to be an even number\n[...]\n\njulia> @skip check_even half(3)\n1\n\n\n\n\n\n","category":"macro"},{"location":"index.html#OptionalArgChecks.@skip","page":"Home","title":"OptionalArgChecks.@skip","text":"@skip label ex[[ recursive=true]]\n@skip [label1, label2, ...] ex[[ recursive=true]]\n\nFor every function call in ex, expressions marked with label label (or any of the labels label* respectively) using the macro @mark get omitted recursively.\n\n\n\n\n\n","category":"macro"},{"location":"index.html#OptionalArgChecks.@skipargcheck-Tuple{Any}","page":"Home","title":"OptionalArgChecks.@skipargcheck","text":"@skipargcheck ex\n\nElides argument checks created with @argcheck or @check, provided by the package ArgCheck.jl. Is equivalent to @skip argcheck ex.\n\n\n\n\n\n","category":"macro"}]
}