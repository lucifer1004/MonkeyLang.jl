using MonkeyLang
using Documenter

DocMeta.setdocmeta!(MonkeyLang, :DocTestSetup, :(using MonkeyLang); recursive = true)

makedocs(;
         modules = [MonkeyLang],
         authors = "Gabriel Wu <wuzihua@pku.edu.cn> and contributors",
         repo = "https://github.com/lucifer1004/MonkeyLang.jl/blob/{commit}{path}#{line}",
         sitename = "MonkeyLang.jl",
         format = Documenter.HTML(;
                                  prettyurls = get(ENV, "CI", "false") == "true",
                                  canonical = "https://lucifer1004.github.io/MonkeyLang.jl",
                                  assets = String[]),
         pages = ["Home" => "index.md"])

deploydocs(; repo = "github.com/lucifer1004/MonkeyLang.jl", devbranch = "main")
