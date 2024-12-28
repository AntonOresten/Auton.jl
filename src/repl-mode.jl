using ReplMaker: initrepl

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
    printstyled("[ $model\n", color=:green) # println(box("", header=model, color=:green))
    GlobalConversation.pushuser(input)
    response = GlobalConversation.aigenerate(model)
    GlobalConversation.push(response)
    println()
    block_outputs = []
    for block in codeblocks(response.content)
        println(box(string(block), header=language(block), color=:blue))
        precaution(block) && continue
        push!(block_outputs, tee_stdout(() -> run(block)))
        println()
    end
    GlobalConversation.pushuser("The output of the code blocks was:\n" * join(block_outputs, "\n"))
    return nothing
end

function __init__()
    !isdefined(Base, :active_repl) && return nothing
    GlobalConversation.init()
    initrepl(
        auton_repl,
        mode_name="auton",
        start_key='§',
        prompt_text="auton> ",
        prompt_color=:cyan,
        valid_input_checker=Returns(false)
    )
end
