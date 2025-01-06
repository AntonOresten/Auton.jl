using Auton
using Test

using Auton: CodeBlock, codeblocks

@testset "Auton.jl" begin
    
    @testset "codeblock.jl" begin

        @testset "CodeBlock" begin
            @test CodeBlock("x = 1", "python") isa CodeBlock{:python}
            @test CodeBlock("x = 1") isa CodeBlock{Auton.NO_LANGUAGE}
            @test CodeBlock("x = 1", nothing) isa CodeBlock{Auton.NO_LANGUAGE}
        end

        @testset "codeblocks" begin
            code = """
            ```julia
            \"\"\"
            ```jldoctest
            julia> x
            1
            ```
            \"\"\"
            const x = 1
            ```
            ```python
            print("Hello, world!")
            ```
            """
            @test codeblocks(code) ==
                CodeBlock[CodeBlock("\"\"\"\n```jldoctest\njulia> x\n1\n```\n\"\"\"\nconst x = 1", "julia"),
                          CodeBlock("print(\"Hello, world!\")", "python")]
        end

    end

end
