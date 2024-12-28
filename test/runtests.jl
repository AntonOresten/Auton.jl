using Auton
using Test

using Auton: CodeBlock, codeblocks

@testset "Auton.jl" begin
    
    @testset "code.jl" begin

        @testset "CodeBlock" begin
            @test CodeBlock("x = 1", "python") isa CodeBlock{:python}
            @test CodeBlock("x = 1") isa CodeBlock{:julia}
            @test CodeBlock("x = 1", nothing) isa CodeBlock{:julia}
        end

        @testset "codeblocks" begin
            code = """
            ```julia
            x = 1
            ```
            ```python
            print("Hello, world!")
            ```
            """
            @test codeblocks(code) ==
                CodeBlock[CodeBlock("x = 1"), CodeBlock("print(\"Hello, world!\")", "python")]
        end

    end

end
