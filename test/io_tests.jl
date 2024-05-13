using GEOFRAMEjl
using Test
using TimeSeries, Dates

@testset "IO csv" begin
    data_path = joinpath(@__DIR__, "data", "testOMS.csv")
    t = GFIO.read_OMS_timeserie(data_path)
    @test isapprox(values(t[Symbol("967")])[1], 99.068235, atol=1e-5)
    data_path = joinpath(@__DIR__, "data", "testWOMS.csv")
    @test GFIO.write_OMS_timeserie(t, data_path)
end
