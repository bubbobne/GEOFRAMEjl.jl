using GEOFRAMEjl
using Test
using TimeSeries

@testset "GEOFRAMEjl.jl" begin
    t = GEOFRAMEjl.read_OMS_timeserie("data/testOMS.csv")
    @test isapprox(values(t[Symbol("967")])[1], 99.068235, atol=1e-5)
    @test GEOFRAMEjl.write_OMS_timeserie(" ") == "Write OMS!"
end
