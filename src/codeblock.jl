const DEFAULT_LANGUAGE = "julia"

struct CodeBlock{Language}
    code::String
end

language(::CodeBlock{Language}) where Language = Language

CodeBlock(code::AbstractString, language=DEFAULT_LANGUAGE) = CodeBlock{Symbol(language)}(String(code))
CodeBlock(code::AbstractString, ::Nothing) = CodeBlock(code)

function codeblocks(input::AbstractString)
    # FIXME: this doesn't work for nested code blocks
    pattern = r"```(\w+)?\n(.*?)\n```"s
    CodeBlock[CodeBlock(code, language) for (language, code) in eachmatch(pattern, input)]
end

Base.run(block::CodeBlock) = @warn "Not running unknown language: $(language(block))"
Base.run(m::Module, block::CodeBlock{:julia}) = Core.eval(m, Meta.parse("begin\n$(block.code)\nend"))
Base.run(block::CodeBlock{:julia}) = run(Main, block)
Base.run(block::CodeBlock{:cmd}) = run(`sh -c $(block.code)`)

highlighted(block::CodeBlock) = block.code
highlighted(block::CodeBlock{:julia}) = JuliaHighlighting.highlight(block.code)

Base.string(block::CodeBlock; highlight=true) = highlight ? highlighted(block) : block.code

Base.show(io::IO, ::MIME"text/plain", block::CodeBlock) = print(io, string(block))
