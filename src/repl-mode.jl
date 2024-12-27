import ReplMaker

const _autoexecute = Ref(false)

function autoexecute(enable::Bool)
    _autoexecute[] = enable
    return nothing
end

function precaution(::CodeBlock{Language}) where Language
    if !_autoexecute[]
        print("Execute $Language code? (y/n) [y]: ")
        readline() in ["y", ""] || return true
        println()
    end
    return false
end

function auton_repl(input::AbstractString)
    output = get_llm_response(input)
    println(box(output, header="", color=:green))
    blocks = codeblocks(output)
    for block in blocks
        println(box(highlight(block), header="", color=:blue))
        precaution(block) && continue
        run(block)
        println()
    end
end

function __init__()
    !isdefined(Base, :active_repl) && return nothing
    ReplMaker.initrepl(
        auton_repl,
        mode_name="auton",
        start_key='§',
        prompt_text=() -> "auton> ",
        prompt_color=:cyan,
        valid_input_checker=Returns(false)
    )
end
