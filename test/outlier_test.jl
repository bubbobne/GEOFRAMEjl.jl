using GEOFRAMEjl
using Test, Dates

# Define the BaseSample and test data
BaseSample = [9, 47, 50, 71, 78, 79, 97, 98, 117, 123, 136, 138, 143, 145, 167,
    185, 202, 216, 217, 229, 235, 242, 257, 297, 300, 315, 344, 347, 347, 360, 362, 368, 387,
    400, 428, 455, 468, 484, 493, 523, 557, 574, 586, 605, 617, 618, 634, 641, 646, 649, 674,
    678, 689, 699, 703, 709, 714, 740, 795, 798, 839, 880, 938, 941, 983, 1014, 1021, 1022,
    1165, 1183, 1195, 1250, 1254, 1288, 1292, 1326, 1362, 1363, 1421, 1549, 1585, 1605, 1629,
    1694, 1695, 1719, 1799, 1827, 1828, 1862, 1991, 2140, 2186, 2255, 2266, 2295, 2321, 2419, 2919, 3612]
Lower1 = vcat([-2000], BaseSample)
Lower2 = vcat([-2001, -2000], BaseSample)
Lower3 = vcat([-2002, -2001, -2000], BaseSample)
Upper1 = vcat(BaseSample, [6000])
Upper2 = vcat(BaseSample, [6000, 6001])
Upper3 = vcat(BaseSample, [6000, 6001, 6002])
Both1 = vcat([-2000], BaseSample, [6000])
Both2 = vcat([-2001, -2000], BaseSample, [6000, 6001])
Both3 = vcat([-2002, -2001, -2000], BaseSample, [6000, 6001, 6002])

# Expected outputs for comparison
expected_outliers = Dict(
    "Lower1_Tukey" => [-2000, 2919, 3612],
    "Lower2_Tukey" => [-2001, -2000, 2919, 3612],
    "Lower3_Tukey" => [-2002, -2001, -2000, 2919, 3612],
    "Lower1_TukeyHD" => [-2000, 2919, 3612],
    "Lower2_TukeyHD" => [-2001, -2000, 2919, 3612],
    "Lower3_TukeyHD" => [-2002, -2001, -2000, 2919, 3612],
    "Lower1_MAD" => [-2000, 2919, 3612],
    "Lower2_MAD" => [-2001, -2000, 2919, 3612],
    "Lower3_MAD" => [-2002, -2001, -2000, 2919, 3612],
    "Lower1_MADHD" => [-2000, 2919, 3612],
    "Lower2_MADHD" => [-2001, -2000, 2919, 3612],
    "Lower3_MADHD" => [-2002, -2001, -2000, 2919, 3612],
    "Lower1_DMAD" => [-2000, 3612],
    "Lower2_DMAD" => [-2001, -2000, 3612],
    "Lower3_DMAD" => [-2002, -2001, -2000, 3612],
    "Lower1_DMADHD" => [-2000],
    "Lower2_DMADHD" => [-2001, -2000],
    "Lower3_DMADHD" => [-2002, -2001, -2000],
    "Upper1_Tukey" => [2919, 3612, 6000],
    "Upper2_Tukey" => [2919, 3612, 6000, 6001],
    "Upper3_Tukey" => [2919, 3612, 6000, 6001, 6002],
    "Upper1_TukeyHD" => [3612, 6000],
    "Upper2_TukeyHD" => [3612, 6000, 6001],
    "Upper3_TukeyHD" => [3612, 6000, 6001, 6002],
    "Upper1_MAD" => [2919, 3612, 6000],
    "Upper2_MAD" => [2919, 3612, 6000, 6001],
    "Upper3_MAD" => [2919, 3612, 6000, 6001, 6002],
    "Upper1_MADHD" => [2919, 3612, 6000],
    "Upper2_MADHD" => [2919, 3612, 6000, 6001],
    "Upper3_MADHD" => [2919, 3612, 6000, 6001, 6002],
    "Upper1_DMAD" => [3612, 6000],
    "Upper2_DMAD" => [6000, 6001],
    "Upper3_DMAD" => [6000, 6001, 6002],
    "Upper1_DMADHD" => [6000],
    "Upper2_DMADHD" => [6000, 6001],
    "Upper3_DMADHD" => [6000, 6001, 6002],
    "Both1_Tukey" => [-2000, 2919, 3612, 6000],
    "Both2_Tukey" => [-2001, -2000, 2919, 3612, 6000, 6001],
    "Both3_Tukey" => [-2002, -2001, -2000, 3612, 6000, 6001, 6002],
    "Both1_TukeyHD" => [-2000, 3612, 6000],
    "Both2_TukeyHD" => [-2001, -2000, 3612, 6000, 6001],
    "Both3_TukeyHD" => [-2002, -2001, -2000, 3612, 6000, 6001, 6002],
    "Both1_MAD" => [-2000, 2919, 3612, 6000],
    "Both2_MAD" => [-2001, -2000, 2919, 3612, 6000, 6001],
    "Both3_MAD" => [-2002, -2001, -2000, 2919, 3612, 6000, 6001, 6002],
    "Both1_MADHD" => [-2000, 2919, 3612, 6000],
    "Both2_MADHD" => [-2001, -2000, 2919, 3612, 6000, 6001],
    "Both3_MADHD" => [-2002, -2001, -2000, 2919, 3612, 6000, 6001, 6002],
    "Both1_DMAD" => [-2000, 6000],
    "Both2_DMAD" => [-2001, -2000, 6000, 6001],
    "Both3_DMAD" => [-2002, -2001, -2000, 6000, 6001, 6002],
    "Both1_DMADHD" => [-2000, 6000],
    "Both2_DMADHD" => [-2001, -2000, 6000, 6001],
    "Both3_DMADHD" => [-2002, -2001, -2000, 6000, 6001, 6002]
)

# Convert sample arrays to TimeArrays
function create_timearray(data::Vector{Int})
    dates = Date(2023, 1, 1):Day(1):(Date(2023, 1, 1) + Day(length(data) - 1))
    TimeArray(dates, data)
end

@testset "Outlier Detection Tests" begin
    for (key, expected) in expected_outliers
        parts = split(key, "_")
        sample_name = parts[1]
        method_name = parts[2]
        sample = eval(Symbol(sample_name))
        ta = create_timearray(sample)
        outliers = GFStatistics.find_outliers(ta; method=String(method_name), threshold=3.0)
        # Debugging output
        println("Method: ", method_name, ", Sample: ", sample_name)
        println("Expected: ", sort(expected))
        println("Actual: ", sort(values(outliers)))

        @test length(values(outliers)) == length(expected)
        if length(values(outliers)) == length(expected)
            @test isapprox(sort(values(outliers)), sort(expected), rtol=1e-5, atol=1e-5)
        end
    end
end
