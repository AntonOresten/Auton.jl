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

mutable struct OutputContext
    output::String
    errors::String
end

function push_tee(f::Function, ctx::OutputContext)
    out, err = tee_stdout_with_stderr(f)
    !isempty(out) && (ctx.output *= "\n" * out)
    !isempty(err) && (ctx.errors *= "\n" * err)
end

function Base.string(ctx::OutputContext)
    """
    Output:
    $(ctx.output)

    Errors:
    $(ctx.errors)
    """
end

function auton_repl(input::AbstractString)
    GlobalConversation.pushuser(input)
    model = "gpt-4o-mini"
    streamcallback = stdout |> Lines() ∘ LineSplit() ∘ Block(model, :blue) ∘ Color(:light_black)
    response = GlobalConversation.aigenerate(model; streamcallback)
    close(streamcallback)
    println()
    GlobalConversation.push(response)
    ctx = OutputContext("", "")
    for block in filter(block -> language(block) != NO_LANGUAGE, codeblocks(response.content))
        block_io = stdout |> Lines() ∘ Block(string(language(block)), :green)
        write(block_io, string(block))
        close(block_io)
        println()
        precaution(block) && continue
        push_tee(ctx) do
            run(block)
        end
        println()
        if ctx.errors != ""
            GlobalConversation.pushuser("Not all code blocks executed successfully.")
            break
        end
    end
    GlobalConversation.pushuser(string(ctx))
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
