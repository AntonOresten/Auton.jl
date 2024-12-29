const NO_LANGUAGE = Symbol("")

struct CodeBlock{Language}
    code::String
end

language(::CodeBlock{Language}) where Language = Language

CodeBlock(code, language::Symbol=NO_LANGUAGE) = CodeBlock{language}(code)
CodeBlock(code, language) = CodeBlock(code, Symbol(language))
CodeBlock(code, ::Nothing) = CodeBlock(code)

function codeblocks(input::AbstractString)
    # FIXME: this doesn't work for nested code blocks
    pattern = r"```(\w+)?\n(.*?)\n```"s
    CodeBlock[CodeBlock(code, language) for (language, code) in eachmatch(pattern, input)]
end

Base.run(block::CodeBlock) = @warn "Not running unknown language: $(language(block))"

function Base.run(m::Module, block::CodeBlock{:julia})
    # optionally call _show on each subexpr for verbose context
    #_show(x) = showdisplay(stdout, x)
    #_show(::Nothing) = nothing
    expr = Meta.parse("begin\n$(block.code)\nend")
    subexprs = filter(x -> !(x isa LineNumberNode), expr.args)
    foreach(subexpr -> Core.eval(m, subexpr), subexprs)
end

Base.run(block::CodeBlock{:julia}) = run(Main, block)
Base.run(block::CodeBlock{:cmd}) = run(`sh -c $(block.code)`)

highlighted(block::CodeBlock) = block.code
highlighted(block::CodeBlock{:julia}) = JuliaHighlighting.highlight(block.code)

Base.string(block::CodeBlock; highlight=true) = highlight ? highlighted(block) : block.code

Base.show(io::IO, ::MIME"text/plain", block::CodeBlock) = print(io, string(block))
