using GEOFRAMEjl
using Test
using TimeSeries, Dates

@testset "kge Function Tests" begin
    observed = [1.0, 2.0, 3.0, 4.0, 5.0]
    simulated = [1.1, 1.9, 3.05, 3.95, 5.1]
    no_value = -9999.0

    # Test basic functionality
    @test GOF.kge(observed, simulated, false, n_min=2) ≈ 0.9905 atol = 0.001
    @test GOF.kge(observed, simulated, true, n_min=2) ≈ 0.99318275 atol = 0.001

    # Test with no-value data points
    observed_with_novalue = [1.0, no_value, 3.0, no_value, 5.0]
    simulated_with_novalue = [1.1, 2.0, 3.05, 4.0, 5.1]
    @test GOF.kge(observed_with_novalue, simulated_with_novalue, false, no_value=no_value, n_min=2) ≈ 0.97297257 atol = 0.001
    @test GOF.kge(observed_with_novalue, simulated_with_novalue, true, no_value=no_value, n_min=2) ≈ 0.96132002 atol = 0.001

    # Test different parameters
    # @test kge(observed, simulated,true, a=0.9, b=1.1, g=0.95) ≈ 0.945 atol=0.001
    # Test error handling

    @test_throws AssertionError GOF.kge([1.0, 2.0], [1.0, 2.0, 3.0], true)
end

@testset "kge_ts Function Tests" begin
    timestamps = DateTime(2020, 1, 1):Day(1):DateTime(2020, 1, 5)
    observed_values = [1.0, 2.0, 3.0, 4.0, 5.0]
    simulated_values = [1.1, 1.9, 3.05, 3.95, 5.1]
    observed_ta = TimeArray(timestamps, observed_values)
    simulated_ta = TimeArray(timestamps, simulated_values)
    # Basic functionality test
    @test GOF.kge_ts(observed_ta, simulated_ta, false, n_min=2) ≈ 0.9905 atol = 0.001
    @test GOF.kge_ts(observed_ta, simulated_ta, true, n_min=2) ≈ 0.99318275 atol = 0.001

    # Timestamp misalignment test
    altered_timestamps = DateTime(2020, 1, 2):Day(1):DateTime(2020, 1, 6)
    misaligned_ta = TimeArray(altered_timestamps, simulated_values)
    @test_throws AssertionError GOF.kge_ts(observed_ta, misaligned_ta, true)
end



@testset "Nash-Sutcliffe Efficiency Tests" begin
    # Create sample TimeArray data
    dates = Date(2001, 1, 1):Day(1):Date(2001, 1, 10)
    observed_data = TimeArray(dates, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0])
    simulated_data = TimeArray(dates, [1.1, 1.9, 3.1, 3.9, 4.8, 6.1, 6.9, 8.2, 8.8, 10.1])

    # Test for exact timestamp match and close values
    nse_value = GOF.nse_ts(observed_data, simulated_data, n_min=2)
    @test nse_value ≈ 0.99 atol = 0.01
end

@testset "Log-Transformed Nash-Sutcliffe Efficiency Tests" begin
    dates = Date(2021, 1, 1):Day(1):Date(2021, 1, 10)
    observed = TimeArray(dates, [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0])
    simulated = TimeArray(dates, [9.5, 19.0, 29.5, 39.0, 49.5, 59.0, 69.5, 79.0, 89.5, 99.0])

    # Test for exact timestamp match and close values
    nse_log_value = GOF.nse_log_ts(observed, simulated, n_min=2)
    @test nse_log_value ≈ 0.99 atol = 0.01
end




@testset "Mean Squared Error Function Tests" begin
    # Sample data for testing
    observed = [2.0, 3.0, 4.0, 5.0]
    predicted = [2.1, 2.9, 4.0, 5.1]
    # Test 1: Correct calculation
    @test GOF.mse(observed, predicted, n_min=3) ≈ 0.0074999 atol = 0.001

    # Test 2: Different lengths should raise an error
    observed_short = [2.0, 3.0]
    @test_throws AssertionError GOF.mse(observed_short, predicted)

    # Test 3: Empty arrays should return NaN or some error
    @test_throws AssertionError GOF.mse(Float64[], Float64[])
end



@testset "Mean Squared Error for Time Series Function Tests" begin
    # Creating sample TimeArray data
    dates = Date(2021, 1, 1):Day(1):Date(2021, 1, 10)
    observed_data = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]
    simulated_data = [110, 190, 310, 390, 490, 610, 690, 790, 890, 1010]
    observed_ta = TimeArray(dates, observed_data)
    simulated_ta = TimeArray(dates, simulated_data)
    # Test 1: Correct timestamp and data handling
    @test GOF.mse_ts(observed_ta, simulated_ta, n_min=5) ≈ 100 atol = 10

    # Test 2: Mismatched timestamps
    dates_shifted = Date(2021, 1, 2):Day(1):Date(2021, 1, 11)
    simulated_ta_shifted = TimeArray(dates_shifted, simulated_data)
    @test_throws AssertionError GOF.mse_ts(observed_ta, simulated_ta_shifted)

    # Test 3: Handling of `no_value` indicators and `n_min`
    simulated_data_with_no_values = [110, -9999.0, 310, -9999.0, 490, 610, -9999.0, 790, 890, 1010]
    simulated_ta_no_values = TimeArray(dates, simulated_data_with_no_values)
    @test GOF.mse_ts(observed_ta, simulated_ta_no_values; no_value=-9999.0, n_min=5) ≈ 100 atol = 10
end