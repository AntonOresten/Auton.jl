using PromptingTools: PromptingTools, AbstractChatMessage, SystemMessage, UserMessage, AIMessage

const MessageChunk = Vector{AbstractChatMessage}
const Conversation = Vector{MessageChunk}

function push_context!(chunk::MessageChunk, content::Union{AbstractString,IOBuffer}, prefix::AbstractString="")
    isempty(content) && return nothing
    push!(chunk, UserMessage(prefix * content))
end

function add_context(chunk::MessageChunk, out, err)
    _string(s::AbstractString) = s
    _string(io::IOBuffer) = String(take!(io))
    out_str = _string(out)
    err_str = _string(err)
    push_context!(chunk, out_str, "output: ")
    push_context!(chunk, err_str, "error: ")
    return out_str, err_str
end

const DEFAULT_SYSTEM_MESSAGE = 
"""
You are a Julia REPL agent. It is your responsibility to streamline the user's
workflow by generating valid Julia code blocks in markdown format. The code blocks
that you generate will be automatically executed and the output will be displayed
once you have made a full response.

If given code, you should repeat it back in a code block, with any needed corrections.
Keep reasoning concise, focusing mainly on code.
"""

const default_conversation = Ref{Conversation}()

function init_default_conversation()
    default_conversation[] = [MessageChunk([SystemMessage(DEFAULT_SYSTEM_MESSAGE)])]
end
