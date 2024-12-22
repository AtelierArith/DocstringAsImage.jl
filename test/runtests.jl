using Test
using DocstringAsImage
using Aqua
using JET

@testset "Aqua" begin
    Aqua.test_all(DocstringAsImage)
end

@testset "JET" begin
    JET.report_package(DocstringAsImage, target_defined_modules=true)
end
