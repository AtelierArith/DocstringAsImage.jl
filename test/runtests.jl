using Test
using DocstringAsImage
using DocstringAsImage: preprocess_text4typst
using Aqua
using JET

@testset "Aqua" begin
    Aqua.test_all(DocstringAsImage)
end

if VERSION >= v"1.12.0" # The latest stable version of Julia
    @testset "JET" begin
        JET.report_package(DocstringAsImage, target_defined_modules = true)
    end
end

@testset "preprocess_text4typst" begin
    input = """
    Here's a math block with special characters:
    ```math
    α + β = γ
    ```
    And some Unicode text: 🚀 こんにちは
    Inline math: ``∫f(x)dx``

    # Examples
    ```jldoctest; filter = r"\\n\\s*(1|1\\.0|true)"
    julia> Set(Any[true, 1, 1.0])
    Set{Any} with 1 element:
    1.0

    julia> MyIdSet{Any}(Any[true, 1, 1.0])
    MyIdSet{Any} with 3 elements:
    1.0
    1
    true
    ```
    """
    expected = raw"""
    Here's a math block with special characters:
    $$α + β = γ$$
    And some Unicode text: 🚀 こんにちは
    Inline math: $∫f(x)dx$

    # Examples
    ```julia
    julia> Set(Any[true, 1, 1.0])
    Set{Any} with 1 element:
    1.0

    julia> MyIdSet{Any}(Any[true, 1, 1.0])
    MyIdSet{Any} with 3 elements:
    1.0
    1
    true
    ```
    """
    @test preprocess_text4typst(input) == expected
end
