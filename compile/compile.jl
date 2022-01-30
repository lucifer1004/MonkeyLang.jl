import Pkg; Pkg.instantiate()

using PackageCompiler

create_app(joinpath(@__DIR__, ".."), "build"; 
    executables = [
        "monkey" => "julia_main",
    ],
)
