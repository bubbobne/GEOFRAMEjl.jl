module GEOFRAMEjl
include("./IO/GFIO.jl")
include("./metrics/GOF.jl")
include("./geo/Geo.jl")
include("./reservoire/reservoir.jl")

export Geo
export GFIO
export GOF
export Reservoir
end
