using ReplMaker: initrepl
using PromptingTools: aigenerate, SystemMessage, UserMessage, AIMessage

const _autoexecute = Ref(get(ENV, "AUTON_AUTOEXECUTE", "false") == "true")

autoexecute() = _autoexecute[]
autoexecute!(enable::Bool) = (_autoexecute[] = enable; nothing)

function precaution(::CodeBlock{Language}) where Language
    if !autoexecute()
        print("Execute $Language code? (y/n) [y]: ")
        readline() in ["y", ""] || return true
        println()
    end
    return false
end

function auton_repl(input::AbstractString)
    model = "gpt-4o-mini"
    printstyled("[ $model\n", color=:green)#println(box("", header=model, color=:green))
    response = aigenerate(input; model, verbose=false, streamcallback=stdout)
    println()
    output_buffer = IOBuffer()
    block_outputs = []
    for block in codeblocks(response.content)
        println(box(string(block), header=language(block), color=:blue))
        precaution(block) && continue
        tee_stdout(output_buffer) do
            run(block)
        end
        push!(block_outputs, String(take!(output_buffer)))
    end
    return nothing
end

function __init__()
    !isdefined(Base, :active_repl) && return nothing
    initrepl(
        auton_repl,
        mode_name="auton",
        start_key='§',
        prompt_text="auton> ",
        prompt_color=:cyan,
        valid_input_checker=Returns(false)
    )
end
