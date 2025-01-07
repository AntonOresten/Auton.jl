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

Generate Julia code blocks **only** when you are making a substantive
change to your code or addressing a new error message. Do **not** repeat the
exact same code block or function definition if there are no changes.
When done, summarize your solution and avoid emitting a new code block.

You are responsible for ensuring that code generates useful output that
are helpful to you and the user in case of an error. Errors may not be
the result of a mistake in the code you generate, but rather the result
of a mistake or incomplete context.

All code blocks should be executable and make sense in the current context.

You also have the ability to self-correct. If you encounter an error, you should try to fix it
by generating a new code block with help from the output and error messages.

You should iteratively act on the user's input, generating code blocks and executing them
until you have a working solution, and limiting the scope of your current response
to the information you have at the moment.
"""

new_conversation() = PromptingTools.ConversationMemory([PromptingTools.SystemMessage(DEFAULT_SYSTEM_MESSAGE)])

@kwdef mutable struct ConversationState
    schema::Union{PromptingTools.AbstractPromptSchema, Nothing} = nothing
    conversation::PromptingTools.ConversationMemory = new_conversation()
    model::String = "gpt-4o-mini"
end

const GLOBAL_CONVERSATION_STATE = Ref{ConversationState}()

convstate!(state::ConversationState) = GLOBAL_CONVERSATION_STATE[] = state

reset_convstate!() = convstate!(ConversationState())

function convstate()
    isassigned(GLOBAL_CONVERSATION_STATE) || reset_convstate!()
    GLOBAL_CONVERSATION_STATE[]
end

model() = convstate().model
model!(model::String) = convstate().model = model

schema() = convstate().schema
schema!(schema::PromptingTools.AbstractPromptSchema) = convstate().schema = schema
