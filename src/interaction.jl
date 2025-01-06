import PromptingTools

function push_context!(conversation::PromptingTools.ConversationMemory, out::AbstractString, err::AbstractString)
    !isempty(out) && push!(conversation, PromptingTools.UserMessage("output: $out"))
    !isempty(err) && push!(conversation, PromptingTools.UserMessage("error: $err"))
    return conversation
end

const DEFAULT_SYSTEM_MESSAGE = 
"""
You are a Julia REPL agent. You are responsible for streamlining the user's
workflow by generating executable Julia code blocks in markdown format.

Generate executable Julia code blocks **only** when you are making a substantive
change to your code or addressing a new error message. Do **not** reprint the
exact same code block if there are no changes. When done, summarize your solution
and avoid emitting a new code block.

You also have the ability to self-correct. If you encounter an error, you should try to fix it
by generating a new code block with help from the output and error messages.

You should iteratively act on the user's input, generating code blocks and executing them
until you have a working solution, and limiting the scope of your current response
to the information you have at the moment.

When done and the outputs indicate that you have a working solution, you should summarize
the solution in a few bullet points.

If given code, you should repeat it back in a code block, with any needed corrections.
Keep reasoning concise, focusing mainly on code.
"""

new_conversation() = PromptingTools.ConversationMemory([PromptingTools.SystemMessage(DEFAULT_SYSTEM_MESSAGE)])

@kwdef mutable struct ConversationState
    schema::PromptingTools.AbstractPromptSchema = PromptingTools.OpenAISchema()
    conversation::PromptingTools.ConversationMemory = new_conversation()
    model::String = "gpt-4o"
end

const GLOBAL_CONVERSATION_STATE = Ref{ConversationState}()

function convstate()
    isassigned(GLOBAL_CONVERSATION_STATE) || (GLOBAL_CONVERSATION_STATE[] = ConversationState())
    GLOBAL_CONVERSATION_STATE[]
end

convstate!(state::ConversationState) = GLOBAL_CONVERSATION_STATE[] = state

reset_convstate!() = convstate!(ConversationState())

model() = convstate().model
model!(model::String) = convstate().model = model

