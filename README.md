# Auton

[![Build Status](https://github.com/AntonOresten/Auton.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/AntonOresten/Auton.jl/actions/workflows/CI.yml?query=branch%3Amain)

Auton is a minimal REPL interface for giving large language models context-awareness and agency to augment your workflow.

It introduces two REPL modes:
- **Context mode** (`-`): similar to the standard julia mode, but feeds your code and anything going through stdout or stderr as context to a global conversation.
- **Auton mode** (`=`): a plaintext conversational mode, where the model is given agency through runnable code blocks, stdout/stderr feedback, and ability to instantly act on outputs iteratively in a feedback loop.

Auton does *not* intercept the outputs of any calls made outside of these modes.

## Models

Auton uses PromptingTools.jl to manage conversations and stream responses, and thus any model and schema.

GoogleGenAI.jl (which is used by PromptingTools.jl for Gemini models) does not seem to support streaming, so those models are currently not supported by Auton.

## Loading on startup

Add the following to `~/.julia/config/startup.jl`

```julia
using Pkg
atreplinit() do repl
    try
        @eval using Auton
    catch e
        @warn "error while importing Auton" e
    end
end
```