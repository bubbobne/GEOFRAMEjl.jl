module GEOFRAMEjl
include("./IO/GFIO.jl")
include("./metrics/GOF.jl")
include("./geo/Geo.jl")
include("./reservoire/reservoir.jl")
include("./statistics/statistics.jl")

export Geo
export GFIO
export GOF
export Reservoir
export Statistics

end
