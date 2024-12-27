const DEFAULT_LANGUAGE = "julia"

struct CodeBlock{Language}
    code::String
end

language(::CodeBlock{Language}) where Language = Language

CodeBlock(code::AbstractString, language=DEFAULT_LANGUAGE) = CodeBlock{Symbol(language)}(String(code))
CodeBlock(code::AbstractString, ::Nothing) = CodeBlock(code)

function codeblocks(input::AbstractString)
    code_block_pattern = r"```(\w+)?\n(.*?)\n```"s
    CodeBlock[CodeBlock(code, language) for (language, code) in eachmatch(code_block_pattern, input)]
end

Base.run(::CodeBlock{Language}) where Language = @warn "Not running unknown language: $(Language)"
Base.run(m::Module, block::CodeBlock{:julia}) = Core.eval(m, Meta.parse("begin\n$(block.code)\nend"))
Base.run(block::CodeBlock{:julia}) = display(run(Main, block))
Base.run(block::CodeBlock{:cmd}) = run(`sh -c $(block.code)`)
