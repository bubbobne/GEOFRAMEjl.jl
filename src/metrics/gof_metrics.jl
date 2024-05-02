using Statistics, TimeSeries, Dates

"""
    kge(observed::Array{Float64}, simulated::Array{Float64},modified::Boolean`; a::Float64=1.0, b::Float64=1.0, g::Float64=1.0, no_value::Float64=-9999.0) -> Float64

Calculate the Kling-Gupta Efficiency (KGE) between two time series or arrays.

# Arguments
- `observed::Array{Float64}`: An array of observed data values.
- `simulated::Array{Float64}`: An array of simulated data values corresponding to the observed values.
- `modified::Boolean`: true used 2012 formula otherwise 2009.
- `a::Float64=1.0`: A scaling coefficient for the correlation component, defaulting to 1.
- `b::Float64=1.0`: A scaling coefficient for the variability component, defaulting to 1.
- `g::Float64=1.0`: A scaling coefficient for the bias component, defaulting to 1.
- `no_value::Float64=-9999.0`: A placeholder value for missing or invalid data, defaulting to -9999.

# Returns
- `Float64`: The KGE score as a floating point number. A value of 1 indicates a perfect match between the observed and simulated data, whereas a value closer to 0 indicates a poor match.

# Exceptions
- `ArgumentError`: Thrown if the input arrays `observed` and `simulated` do not have the same length.
- `ErrorException`: Thrown if all data points are filtered out due to being flagged as no-value.

# Description
The KGE is calculated using the formula:

    KGE = 1 - sqrt((r - α)^2 + (β * σ_s/σ_o - 1)^2 + (γ * μ_s/μ_o - 1)^2)

where:
- `r` is the correlation coefficient between the observed and simulated data.
- `σ_s` and `σ_o` are the standard deviations of the simulated and observed data, respectively.
- `μ_s` and `μ_o` are the means of the simulated and observed data, respectively.

The function first checks that the two input arrays are of the same length. It then filters out any data points where either array contains the `no_value`. The KGE is only calculated from the remaining valid data points.

# Usage
```julia
observed = [1.0, 2.0, 3.0, -9999.0, 5.0]
simulated = [1.1, 1.9, 2.95, 4.0, 5.05]
kge_score = kge(observed, simulated, true)
println("KGE Score: ", kge_score)
"""

function kge(observed::Array{Float64}, simulated::Array{Float64}, modified::Bool;
    a::Float64=1.0, b::Float64=1.0, g::Float64=1.0,
    no_value::Float64=-9999.0)
    # Step 1: Check if the input arrays have the same length
    println( length(observed) == length(simulated))
    @assert length(observed) == length(simulated)
    # Step 2: Filter out no-value data
    valid_indices = (observed .!= no_value) .& (simulated .!= no_value)
    filtered_observed = observed[valid_indices]
    filtered_simulated = simulated[valid_indices]
    # Check if there's enough data left
    @assert length(filtered_observed) > 0
    # Step 3: Calculate KGE
    r = cor(filtered_observed, filtered_simulated)
    sigma_o = std(filtered_observed)
    sigma_s = std(filtered_simulated)
    mu_o = mean(filtered_observed)
    mu_s = mean(filtered_simulated)
    beta =  mu_s / mu_o
    alpha = sigma_s / sigma_o
    if modified
        alpha =alpha / beta
    end
    kge = 1.0 - sqrt((r - a)^2 + ((b * alpha) - 1)^2 + ((g * beta) - 1)^2)
    return kge
end


"""
    kge_ts(observed_ta::TimeArray, simulated_ta::TimeArray, modified::Boolean; a::Float64=1.0, b::Float64=1.0, g::Float64=1.0, no_value::Float64=-9999.0) -> Float64

Calculate the Kling-Gupta Efficiency (KGE) for two aligned TimeArray objects.

# Arguments
- `observed_ta::TimeArray`: A TimeArray object containing the observed data.
- `simulated_ta::TimeArray`: A TimeArray object containing the simulated data.
- `modified::Boolean`: true used 2012 formula otherwise 2009.
- `a::Float64=1.0`, `b::Float64=1.0`, `g::Float64=1.0`: Parameters for the KGE calculation.
- `no_value::Float64=-9999.0`: Indicator for no-value or missing data points.

# Returns
- `Float64`: The calculated KGE score.

# Exceptions
- `ArgumentError`: Thrown if the TimeArray objects do not start and end on the same dates or if their timesteps are inconsistent.

# Description
This function verifies that the two TimeArray objects are aligned in terms of their timestamps. It then extracts the data arrays and computes the KGE using the `calculate_kge` function defined earlier.

# Usage
```julia
using TimeSeries

timestamps = DateTime(2020, 1, 1):Day(1):DateTime(2020, 1, 10)
observed_values = [1.0, 2.0, 3.0, -9999.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
simulated_values = [1.1, 1.9, 2.95, 4.0, 5.05, 5.95, 7.1, 8.05, 8.95, 10.1]
observed_ta = TimeArray(timestamps, observed_values)
simulated_ta = TimeArray(timestamps, simulated_values)

kge_score = kge_ts(observed_ta, simulated_ta)
println("KGE Score: ", kge_score)
"""

function kge_ts(observed_ta::TimeArray, simulated_ta::TimeArray,modified::Bool;
    a::Float64=1.0, b::Float64=1.0, g::Float64=1.0,
    no_value::Float64=-9999.0)
    # Verify that the time stamps align
    @assert timestamp(observed_ta) == timestamp(simulated_ta)
    observed_values = values(observed_ta)
    simulated_values = values(simulated_ta)
    # Calculate KGE using the previously defined function
    return kge(observed_values, simulated_values, modified, a=a, b=b, g=g, no_value=no_value)
end