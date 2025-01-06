const NO_LANGUAGE = Symbol("")

struct CodeBlock{Language}
    code::String
end

language(::CodeBlock{Language}) where Language = Language

CodeBlock(code, language::Symbol=NO_LANGUAGE) = CodeBlock{language}(code)
CodeBlock(code, language) = CodeBlock(code, Symbol(language))
CodeBlock(code, ::Nothing) = CodeBlock(code)

Base.run(block::CodeBlock) = @warn "Not running unknown language: $(language(block))"

function Base.run(m::Module, block::CodeBlock{:julia})
    # optionally call _show on each subexpr for verbose context
     _show(x) = showdisplay(stdout, x)
     _show(::Nothing) = nothing
    expr = Meta.parse("begin\n$(block.code)\nend")
    subexprs = expr.args # filter(x -> !(x isa LineNumberNode), expr.args)
    _eval(x) = Core.eval(m, x)
    for (i, subexpr) in enumerate(subexprs)
        ret = Core.eval(m, subexpr)
        i == length(subexprs) && _show(ret)
    end
    return nothing
end

Base.run(block::CodeBlock{:julia}) = run(Main, block)
Base.run(block::CodeBlock{:shell}) = run(`sh -c $(block.code)`)

function Base.show(io::IO, ::MIME"text/plain", block::CodeBlock)
    print(io, "```$(language(block))\n$(block.code)\n```")
end

function codeblocks(md::AbstractString)
    lines = split(md, '\n')
    in_block = false
    nesting  = 0
    lang     = ""
    buf      = IOBuffer()
    blocks   = CodeBlock[]
    pat      = r"^```(.*)$"

    for line in lines
        if occursin(pat, line)
            captured = match(pat, line).captures[1] |> strip
            if !in_block
                in_block = true
                nesting  = 0
                lang     = captured
                truncate(buf, 0)
                seekstart(buf)
            else
                if !isempty(captured)
                    nesting += 1
                    println(buf, line)
                elseif nesting > 0
                    nesting -= 1
                    println(buf, line)
                else
                    push!(blocks, CodeBlock(String(take!(buf)), lang))
                    in_block = false
                    lang     = ""
                end
            end
        elseif in_block
            println(buf, line)
        end
    end

    return blocks
end
