module Highlight

export highlight

highlight(language, str::AbstractString; kwargs...) = highlight(Val(Symbol(language)), str; kwargs...)
highlight(language::Symbol, str::AbstractString; kwargs...) = str

include("julia.jl")

end