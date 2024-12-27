using Auton
using Test

using Auton: CodeBlock, codeblocks

@testset "Auton.jl" begin
    
    @testset "CodeBlock" begin
        @test codeblocks("x = 1; sin(x)") == [CodeBlock("x = 1"), CodeBlock("sin(x)")]
    end
end

