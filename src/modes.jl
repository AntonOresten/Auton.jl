using ReplMaker: initrepl
using REPL.LineEdit: EmptyCompletionProvider

using .Highlight: highlight
using .IORules: Lines, LineSplit, Block, Color
model_response_rules(model) = Lines() ∘ LineSplit() ∘ Block(model, :blue) ∘ Color(:light_black)
code_block_rules(language) = Lines() ∘ Block(language, :green)

function run_code(code::CodeBlock)
    out, err = tee_stdout_with_stderr(target=string(typeof(code))) do
        run(code)
    end
    return read(seekstart(out), String), read(seekstart(err), String)
end

function context_repl(input::AbstractString, state::ConversationState=convstate())
    push!(state.conversation, PromptingTools.UserMessage("```julia\n$input\n```"))
    out, err = run_code(CodeBlock(input, :julia))
    push_context!(state.conversation, out, err)
    !isempty(err) && println(err)
    return nothing
end

function auton_repl(input::AbstractString, state::ConversationState=convstate())
    push!(state.conversation, PromptingTools.UserMessage(input))
    println()
    model_iteration(state)
end

function get_response(; schema, model, conversation, streamcallback, kwargs...)
    _streamcallback = contains("gemini")(model) ? nothing : streamcallback
    response = if isnothing(schema)
        PromptingTools.aigenerate(conversation; streamcallback=_streamcallback, kwargs...)
    else
        PromptingTools.aigenerate(schema, conversation; streamcallback=_streamcallback, kwargs...)
    end
    isnothing(_streamcallback) && print(streamcallback, response.content)
    return response
end

function model_iteration(state::ConversationState; i=0)
    response = model_response_rules(state.model)(stdout) do streamcallback
        get_response(; state.schema, state.conversation, streamcallback, state.model, verbose=false)
    end
    push!(state.conversation, response)

    blocks = filter(block -> language(block) != NO_LANGUAGE, codeblocks(response.content))
    for block in blocks
        println()
        code_block_rules(language(block))(stdout) do io
            print(io, highlight(language(block), block.code))
        end
        println()
        out, err = run_code(block)
        push_context!(state.conversation, out, err)
        if !isempty(err)
            println(err)
            break
        end
    end

    if i < 5 && !isempty(blocks)
        println()
        model_iteration(state; i=i+1)
    end

    return nothing
end

function __init__()
    !isdefined(Base, :active_repl) && return nothing
    initrepl(
        context_repl,
        mode_name="auton_context",
        start_key='-',
        prompt_text="👁️ julia> ",
        prompt_color=:light_green,
    )
    initrepl(
        auton_repl,
        mode_name="auton_conversation",
        start_key='=',
        prompt_text="auton> ",
        prompt_color=:cyan,
        valid_input_checker=Returns(true),
        completion_provider=EmptyCompletionProvider(),
    )
end