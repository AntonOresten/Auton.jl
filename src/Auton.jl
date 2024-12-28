module Auton

include("utils/utils.jl")

include("highlight/highlight.jl")

include("codeblock.jl")

include("conversation.jl")

include("repl-mode.jl")
export autoexecute!, autoexecute

@deprecate autoexecute(enable::Bool) autoexecute!(enable)

end
