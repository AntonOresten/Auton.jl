# Auton

[![Build Status](https://github.com/AntonOresten/Auton.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/AntonOresten/Auton.jl/actions/workflows/CI.yml?query=branch%3Amain)

Auton is a minimal REPL interface for giving large language models context-awareness and agency to augment your workflow.

It introduces two REPL modes:
- **Context mode** (`-`): similar to the standard julia mode, but feeds your code and anything going through stdout or stderr as context to a global conversation.
- **Auton mode** (`=`): a plaintext conversational mode, where the model is given agency through runnable code blocks, stdout/stderr, and ability to immediately act on outputs iteratively in a feedback loop.

Auton does *not* intercept the outputs of any calls made outside of these modes.

## Models

Auton uses [PromptingTools.jl](https://github.com/svilupp/PromptingTools.jl) to manage conversations and stream responses, and can thus handle any model and schema.

For Google models like Gemini, you additionally need to load the [GoogleGenAI.jl](https://github.com/tylerjthomas9/GoogleGenAI.jl) package.

## API keys

Model providers require you to generate API keys, which are ideally added as environment variables.

See the [PromptingTools.jl docs](https://siml.earth/PromptingTools.jl/v0.69.1/getting_started).

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