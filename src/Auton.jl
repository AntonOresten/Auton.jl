module Auton

include("IORules.jl")

include("highlight/highlight.jl")

include("interaction.jl")
export convstate, convstate!, reset_convstate!
export model, model!
export schema, schema!

include("io.jl")

include("codeblock.jl")

include("modes.jl")

end
