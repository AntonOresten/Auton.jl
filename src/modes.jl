using ReplMaker: initrepl
using .IORules: Lines, LineSplit, Block, Color

model_response_rules(model) = Lines() ∘ LineSplit() ∘ Block(model, :blue) ∘ Color(:light_black)

code_block_rules(language) = Lines() ∘ Block(language, :green)

function context_repl(input::AbstractString, conversation::Conversation=default_conversation[])
    chunk = MessageChunk([UserMessage("```julia\n$input\n```")])
    push!(conversation, chunk)
    block = CodeBlock(input, :julia)
    out, err = tee_stdout_with_stderr(target="top-level scope") do
        run(block)
    end
    _, err_msg = add_context(chunk, out, err)
    if !isempty(err_msg)
        println(err_msg)
    end
    return nothing
end

function auton_repl(
    input::AbstractString, conversation::Conversation=default_conversation[];
    model="gpt-4o",
)
    query = UserMessage(input)
    query_chunk = MessageChunk([query])
    push!(conversation, query_chunk)

    response = model_response_rules(model)(stdout) do streamcallback
        PromptingTools.aigenerate(reduce(vcat, conversation); model, streamcallback, verbose=false)
    end
    response_chunk = MessageChunk([response])
    push!(conversation, response_chunk)
    println()
    for block in filter(block -> language(block) != NO_LANGUAGE, codeblocks(response.content))
        code_block_rules(language(block))(stdout) do io
            print(io, Highlight.highlight(Val(:julia), block.code))
        end
        println()
        # FIXME: this is a hack to get the backtrace to show fewer frames
        out, err = tee_stdout_with_stderr(target="CodeBlock{:julia}") do
            run(block)
        end
        _, err_msg = add_context(response_chunk, out, err)
        if !isempty(err_msg)
            println(err_msg)
            break
        end
    end

    return nothing
end

function __init__()
    init_default_conversation()
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
        valid_input_checker=Returns(false)
    )
end
