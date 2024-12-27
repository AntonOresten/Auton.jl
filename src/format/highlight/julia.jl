module JuliaHighlighting

using JuliaSyntax
using Crayons

function colorscheme()
    return (
        symbol      = :light_magenta,
        comment     = :black,
        string      = :light_cyan,
        call        = :light_cyan,
        op          = :light_red,
        keyword     = :light_red,
        text        = :default,
        funcdef     = :light_magenta,
        argdef      = :light_cyan,
        _macro      = :light_cyan,
        number      = :light_blue,
        bracket     = :white,
    )
end

function highlight(str::AbstractString; scheme = colorscheme())
    tokens = JuliaSyntax.tokenize(str)
    crayons = fill(Crayon(foreground = scheme.text), length(tokens))
    
    # We track two previous tokens to replicate your logic of occasionally recoloring them
    pprev_t = Token()
    prev_t  = Token()
    
    # We also define a small function for convenience:
    text_of(t) = JuliaSyntax.untokenize(t, str)

    for i in eachindex(tokens)
        t = tokens[i]
        k = JuliaSyntax.kind(t)

        if k == K"Identifier" && JuliaSyntax.kind(prev_t) == K"::"
            crayons[i]   = Crayon(foreground = scheme.argdef)

        # :foo  (symbol) -- check that the previous token is `:` and the pre-previous
        # is not an integer, float, identifier, or )
        elseif k == K"Identifier" &&
               JuliaSyntax.kind(prev_t) == K":" &&
               JuliaSyntax.kind(pprev_t) ∉ (K"Integer", K"Float", K"Identifier", K")")
            crayons[i-1] = Crayon(foreground = scheme.symbol)
            crayons[i]   = Crayon(foreground = scheme.symbol)

        # Keywords (e.g. `if`, `function`, `for`, etc.)
        elseif JuliaSyntax.is_keyword(k)
            if k == K"true" || k == K"false"
                crayons[i] = Crayon(foreground = scheme.symbol)
            else
                crayons[i] = Crayon(foreground = scheme.keyword)
            end

        # Strings
        elseif k in (K"String", K"Char", K"CmdString", K"\"", K"'", K"`")
            crayons[i] = Crayon(foreground = scheme.string)

        # Operators, `true`, `false`
        elseif JuliaSyntax.is_operator(k) || k == K"true" || k == K"false"
            crayons[i] = Crayon(foreground = scheme.op)

        # Comments
        elseif k == K"Comment"
            crayons[i] = Crayon(foreground = scheme.comment)

        # Brackets: treat `(`, `[`, `{` the same
        # If you want separate colors for each bracket type, just do more if-clauses.
        elseif k in (K"(", K"[", K"{")
            # If the token before it is an identifier, color that identifier + bracket as a function call
            if JuliaSyntax.kind(prev_t) == K"Identifier" &&
               !(i > 2 && JuliaSyntax.kind(tokens[i-2]) == K"@")
                crayons[i-1] = Crayon(foreground = scheme.call)
            # Alternatively, if we see something like `foo.( ... )`
            elseif JuliaSyntax.kind(prev_t) == K"." &&
                   JuliaSyntax.kind(pprev_t) == K"Identifier"
                crayons[i-2] = Crayon(foreground = scheme.call)
                crayons[i-1] = Crayon(foreground = scheme.call)
            end
            # If it’s a function definition like `function f(`, color `f(` in a special color
            if i > 3 &&
               JuliaSyntax.is_whitespace(JuliaSyntax.kind(tokens[i-2])) &&
               JuliaSyntax.kind(tokens[i-3]) == K"function"
                crayons[i-1] = Crayon(foreground = scheme.funcdef)
            end
            # color the bracket itself
            crayons[i] = Crayon(foreground = scheme.bracket)

        # For closing brackets, just color them the same as bracket
        elseif k in (K")", K"]", K"}")
            crayons[i] = Crayon(foreground = scheme.bracket)

        # MacroName
        elseif k == K"MacroName"
            # Recolor the preceding `@` and the macro name
            crayons[i-1] = Crayon(foreground = scheme._macro)
            crayons[i]   = Crayon(foreground = scheme._macro)

        # Numbers
        elseif k in (K"Integer", K"BinInt", K"OctInt", K"HexInt", K"Float") ||
               (k == K"Identifier" && text_of(t) == "NaN")
            crayons[i] = Crayon(foreground = scheme.number)

        # Everything else (identifiers, etc.) defaults to `scheme.text`
        else
            crayons[i] = Crayon(foreground = scheme.text)
        end
        
        pprev_t = prev_t
        prev_t  = t
    end

    buf = IOBuffer()
    for (cr, tk) in zip(crayons, tokens)
        print(buf, cr, text_of(tk), Crayon(reset = true))
    end
    return String(take!(buf))
end

end