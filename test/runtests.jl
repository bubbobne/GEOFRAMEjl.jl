using Test

# Include test files for each module
include("gof_test.jl")
include("io_tests.jl")

@testset "MyPackage Tests" begin


    @testset "Outlier Module Tests" begin
        include("outlier_test.jl")  # These should contain tests specific to the outlier module
    end

    @testset "Geo Module Tests" begin
        include("gof_test.jl")  # These should contain tests specific to the Geo module
    end

    @testset "IO Module Tests" begin
        include("io_tests.jl")  # These should contain tests specific to the IO module
    end


end