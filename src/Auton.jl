module Auton

include("code.jl")

include("llm.jl")

include("format/format.jl")

include("repl-mode.jl")
export autoexecute

end
