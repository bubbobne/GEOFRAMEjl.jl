module GEOFRAMEjl
include("./timeseries/io_csv.jl")
include("./metrics/gof_metrics.jl")

# Write your package code here.

export write_OMS_timeserie
export read_OMS_timeserie
export kge
export kge_ts
export nse
export nse_ts
export nse_log
export nse_log_ts
export mse
export mse_ts

end
