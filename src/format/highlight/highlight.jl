include("julia.jl")

highlight(block::CodeBlock) = block.code
highlight(block::CodeBlock{:julia}) = JuliaHighlighting.highlight(block.code)
