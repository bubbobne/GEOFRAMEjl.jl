using GEOFRAMEjl
using Test
using TimeSeries, Dates

@testset "GEOFRAMEjl" begin
    data_path = joinpath(@__DIR__, "data", "testOMS.csv")
    t = GEOFRAMEjl.read_OMS_timeserie(data_path)
    @test isapprox(values(t[Symbol("967")])[1], 99.068235, atol=1e-5)
    data_path = joinpath(@__DIR__, "data", "testWOMS.csv")
    @test GEOFRAMEjl.write_OMS_timeserie(t,data_path)
end


@testset "kge Function Tests" begin
    observed = [1.0, 2.0, 3.0, 4.0, 5.0]
    simulated = [1.1, 1.9, 3.05, 3.95, 5.1]
    no_value = -9999.0

    # Test basic functionality
    @test kge(observed, simulated, false) ≈ 0.9905 atol=0.001
    @test kge(observed, simulated, true) ≈ 0.99318275 atol=0.001

    # Test with no-value data points
    observed_with_novalue = [1.0, no_value, 3.0, no_value, 5.0]
    simulated_with_novalue = [1.1, 2.0, 3.05, 4.0, 5.1]
    @test kge(observed_with_novalue, simulated_with_novalue,false, no_value=no_value) ≈ 0.97297257 atol=0.001
    @test kge(observed_with_novalue, simulated_with_novalue,true, no_value=no_value) ≈ 0.96132002 atol=0.001

    # Test different parameters
    # @test kge(observed, simulated,true, a=0.9, b=1.1, g=0.95) ≈ 0.945 atol=0.001
    # Test error handling

    @test_throws AssertionError kge([1.0, 2.0], [1.0, 2.0, 3.0], true)
end

@testset "kge_ts Function Tests" begin
    timestamps = DateTime(2020, 1, 1):Day(1):DateTime(2020, 1, 5)
    observed_values = [1.0, 2.0, 3.0, 4.0, 5.0]
    simulated_values = [1.1, 1.9, 3.05, 3.95, 5.1]
    observed_ta = TimeArray(timestamps, observed_values)
    simulated_ta = TimeArray(timestamps, simulated_values)
    # Basic functionality test
    @test kge_ts(observed_ta, simulated_ta, false) ≈ 0.9905 atol=0.001
    @test kge_ts(observed_ta, simulated_ta,true) ≈ 0.99318275 atol=0.001

    # Timestamp misalignment test
    altered_timestamps = DateTime(2020, 1, 2):Day(1):DateTime(2020, 1, 6)
    misaligned_ta = TimeArray(altered_timestamps, simulated_values)
    @test_throws AssertionError kge_ts(observed_ta, misaligned_ta,true)
end
