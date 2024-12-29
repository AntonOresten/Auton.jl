baremodule GlobalConversation

using PromptingTools: AbstractChatMessage, SystemMessage, UserMessage, AIMessage
import PromptingTools
import Base

const DEFAULT_SYSTEM_MESSAGE = 
"""
You are a Julia REPL agent. It is your responsibility to streamline the user's
workflow by generating valid Julia code blocks in markdown format. The code blocks
that you generate will be automatically executed and the output will be displayed
once you have made a full response.

Each block is executed in order, and each expression in each block is displayed
in the output that you will see, so print statements should be used sparingly.

If given code, you should repeat it back in a code block, with any needed corrections.
Keep reasoning concise, focusing mainly on code.
"""

const Conversation = Base.Vector{AbstractChatMessage}
const conversation = Base.Ref{Conversation}()

get() = conversation[]
set(new) = (conversation[] = new)
clear() = set(Conversation())
init(msg=DEFAULT_SYSTEM_MESSAGE) = set(Conversation([SystemMessage(msg)]))
copy() = Conversation(get())
isactive() = Base.isassigned(conversation)
push(message) = Base.push!(get(), message)
pushsystem(message) = push(SystemMessage(message))
pushuser(message) = push(UserMessage(message))
pushai(message) = push(AIMessage(message))

aigenerate(model; streamcallback=Base.stdout) = PromptingTools.aigenerate(get(); model, verbose=false, streamcallback)

end
