function box(text::AbstractString; header="", color=:normal)
    colorcode = Base.text_colors[color]
    resetcode = Base.text_colors[:normal]

    lines = split(strip(text), '\n')
    !isempty(header) && insert!(lines, 1, colorcode*header*resetcode)

    if length(lines) == 1
        output = colorcode*"[ "*resetcode*lines[1]*'\n'
    else
        output = colorcode*"┌ "*resetcode*lines[1]*'\n'
        for line in lines[2:end-1]
            output *= colorcode*"│ "*resetcode*line*'\n'
        end
        output *= colorcode*"└ "*resetcode*lines[end]*'\n'
    end
    
    output
end
