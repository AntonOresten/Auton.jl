module Highlight

export highlight

highlight(language, str::AbstractString; kwargs...) = highlight(Val(Symbol(language)), str; kwargs...)

include("julia.jl")

end