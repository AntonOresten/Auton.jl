baremodule GlobalConversation

using PromptingTools: AbstractChatMessage, SystemMessage, UserMessage, AIMessage
import PromptingTools
import Base

const DEFAULT_SYSTEM_MESSAGE = "YOU ARE A HELPFUL ASSISTANT. YOU GIVE GREAT ANSWERS AT ALL COSTS."

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

aigenerate(model) = PromptingTools.aigenerate(get(); model, verbose=false, streamcallback=Base.stdout)

end


