module IORules

export IORule, IOWithRule
export Formatter, Color, Split, LineSplit, Block, Lines
export apply_rule, with_rule, write_rule, close_rule


abstract type IORule <: Function end

apply_rule(data, ::IORule) = data

(rule::IORule)(data) = apply_rule(data, rule)


struct IOWithRule{Rule<:IORule} <: IO
    io::IO
    rule::Rule
end

with_rule(io::IO, rule::IORule) = IOWithRule(io, rule)

(rule::IORule)(io::IO) = with_rule(io, rule)

write_rule(io::IOWithRule, data) = write(io.io, apply_rule(data, io.rule))

Base.write(io::IOWithRule, data) = write_rule(io, data)

# to fix method ambiguity
Base.write(io::IOWithRule, data::Vector{UInt8}) = write_rule(io, data)
Base.write(io::IOWithRule, data::Union{SubString{String}, String}) = write_rule(io, data)

close_rule(::IO) = nothing
close_rule(io::IOWithRule) = close_rule(io.io)

Base.close(io::IOWithRule) = close_rule(io)

function (rule::IORule)(f::Function, io::IO)
    io = with_rule(io, rule)
    ret = f(io)
    close_rule(io)
    return ret
end


struct IORuleChain{Rules<:Tuple{Vararg{IORule}}} <: IORule
    rules::Rules
end

function Base.:∘(rule1::IORule, rule2::IORule)
    rules(rule::IORule) = (rule,)
    rules(chain::IORuleChain) = chain.rules
    return IORuleChain((rules(rule1)..., rules(rule2)...))
end

with_rule(io::IO, rule::IORuleChain) = foldr((rule, io) -> with_rule(io, rule), rule.rules; init=io)


struct Formatter <: IORule
    func::Function
end

apply_rule(data, rule::Formatter) = rule.func(data)

Color(color) = Formatter(x -> Base.text_colors[color] * x)


struct Split <: IORule
    func::Function
end

function write_rule(io::IOWithRule{Split}, data)
    for chunk in io.rule.func(data)
        write(io.io, chunk)
    end
end

split_line(s::AbstractString, n::Integer) = @views [s[i:min(i+n-1, end)] for i in 1:n:length(s)]

add_newlines(strings) = [i < length(strings) ? s * "\n" : s for (i, s) in enumerate(strings)]

LineSplit(width=displaysize(stdout)[2]-5) = Split(line -> add_newlines(split_line(line, width)))


function format_block_line(
    prefix, content,
    prefix_color::Symbol=:blue, content_color::Symbol=:default,
)
    Base.text_colors[prefix_color] * "$prefix" * Base.text_colors[content_color] * content
end

struct Block <: IORule
    header
    color::Symbol
end

function with_rule(io::IO, rule::Block)
    print(io, format_block_line("╭─$(rule.header)", "\n", rule.color))
    return IOWithRule(io, rule)
end

function write_rule(io::IOWithRule{Block}, str::Union{SubString{String}, String})
    print(io.io, format_block_line("│ ", "", io.rule.color))
    print(io.io, str)
end

function close_rule(io::IOWithRule{Block})
    print(io.io, format_block_line("╰───┈─┈─┈┈┈ ┈ ┈", "\n", io.rule.color))
end


struct Lines <: IORule
    buffer::Vector{UInt8}
end

Lines() = Lines(UInt8[])

function write_rule(io::IOWithRule{Lines}, str::Union{SubString{String}, String})
    push!(io.rule.buffer, codeunits(str)...)
    while true
        last_newline_index = findfirst(x -> x == 0x0a, io.rule.buffer)
        if last_newline_index === nothing
            break
        end
        to_flush = io.rule.buffer[1:last_newline_index]
        write(io.io, String(to_flush))
        deleteat!(io.rule.buffer, 1:last_newline_index)
    end
    return nothing
end

function close_rule(io::IOWithRule{Lines})
    write_rule(io, "\n")
    close_rule(io.io)
end

end
