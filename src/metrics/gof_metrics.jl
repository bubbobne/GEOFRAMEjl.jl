using Statistics, TimeSeries, Dates
const n = 30
"""
    check_array(observed::Array{Float64}, simulated::Array{Float64}, no_value::Float64 = -9999.0)

Check if the input arrays `observed` and `simulated` are of the same length and filter out entries where either array contains the `no_value` indicator.

# Arguments
- `observed::Array{Float64}`: Array of observed data points.
- `simulated::Array{Float64}`: Array of simulated data points corresponding to the observed data.
- `no_value::Float64`: A specific value in the data arrays that indicates missing or invalid data.

# Returns
- `filtered_observed::Array{Float64}`: The observed data array after removing entries marked by `no_value`.
- `filtered_simulated::Array{Float64}`: The simulated data array after removing entries marked by `no_value`.

# Example
```julia
observed = [1.0, -9999.0, 3.0, 4.5]
simulated = [1.1, 2.0, 2.9, 4.6]
filtered_observed, filtered_simulated = check_array(observed, simulated)
Notes

    An assertion error will be thrown if the input arrays are not of the same length or if there are fewer than 30 valid data points after filtering.
"""
function check_array(observed::AbstractArray{T}, simulated::AbstractArray{U}; no_value::Float64=-9999.0, n_min::Int=n) where {T <: Number, U <: Number}
    # Ensure both input arrays are of the same length
    @assert !isempty(observed) "Input arrays must not be empty."
    @assert !isempty(simulated) "Input arrays must not be empty."
    @assert length(observed) >= n_min "Observed array must have at least $n_min elements."
    @assert length(simulated) >= n_min "Simulated array must have at least $n_min elements."
    @assert length(observed) == length(simulated) "Observed and simulated arrays must be of the same length."

    # Filter out indices where either array has a 'no_value' marker
    valid_indices = (observed .!= no_value) .& (simulated .!= no_value)
    filtered_observed = observed[valid_indices]
    filtered_simulated = simulated[valid_indices]

    # Ensure there are at least 30 valid data points
    @assert length(filtered_observed) > n_min "Insufficient number of valid data points after filtering."

    return filtered_observed, filtered_simulated
end



"""
    check_ts(observed_ta::TimeArray, simulated_ta::TimeArray)

Verify that the timestamps in the `TimeArray` objects for observed and simulated data match and return the corresponding values of these arrays for further processing.

# Arguments
- `observed_ta::TimeArray`: TimeArray object containing observed data with timestamps.
- `simulated_ta::TimeArray`: TimeArray object containing simulated data with corresponding timestamps.

# Returns
- Tuple of arrays containing the values from `observed_ta` and `simulated_ta`.

# Example
```julia
using TimeSeries
dates = Date(2021, 1, 1):Day(1):Date(2021, 1, 10)
observed_ta = TimeArray(dates, rand(10))
simulated_ta = TimeArray(dates, rand(10))
observed_values, simulated_values = check_ts(observed_ta, simulated_ta)

Notes

    An assertion error will be thrown if the timestamps do not match.
"""

function check_ts(observed_ta::TimeArray, simulated_ta::TimeArray)
    @assert timestamp(observed_ta) == timestamp(simulated_ta)
    return values(observed_ta), values(simulated_ta)
end



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

function kge(observed::AbstractArray{T}, simulated::AbstractArray{U}, modified::Bool;
    a::Float64=1.0, b::Float64=1.0, g::Float64=1.0,
    no_value::Float64=-9999.0, n_min::Int=n) where {T <: Number, U <: Number}
    filtered_observed, filtered_simulated = check_array(observed, simulated, no_value=no_value, n_min=n_min)
    # Step 3: Calculate KGE
    r = cor(filtered_observed, filtered_simulated)
    sigma_o = std(filtered_observed)
    sigma_s = std(filtered_simulated)
    mu_o = mean(filtered_observed)
    mu_s = mean(filtered_simulated)
    beta = mu_s / mu_o
    alpha = sigma_s / sigma_o
    if modified
        alpha = alpha / beta
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

function kge_ts(observed_ta::TimeArray, simulated_ta::TimeArray, modified::Bool;
    a::Float64=1.0, b::Float64=1.0, g::Float64=1.0,
    no_value::Float64=-9999.0, n_min::Int=n)
    # Verify that the time stamps align
    observed_values, simulated_values = check_ts(observed_ta, simulated_ta)
    # Calculate KGE using the previously defined function
    return kge(observed_values, simulated_values, modified, a=a, b=b, g=g, no_value=no_value, n_min=n_min)
end


"""
    nse(filtered_observed::Array{Float64}, filtered_simulated::Array{Float64})

Calculate the Nash-Sutcliffe Efficiency (NSE) to assess the predictive accuracy and performance of hydrological models.

# Arguments
- `filtered_observed::Array{Float64}`: Filtered array of observed data points.
- `filtered_simulated::Array{Float64}`: Filtered array of simulated data points.

# Returns
- `Float64`: The computed NSE value. A value of 1 indicates perfect prediction, while a value of 0 indicates that the model predictions are as accurate as the mean of the observed data.

# Example
```julia
observed = [1.0, 2.0, 3.0, 4.0]
simulated = [1.1, 2.1, 2.9, 4.1]
nse_value = nse(observed, simulated)

Notes

    This function assumes that the input data arrays are already filtered and do not contain invalid entries.
"""
function nse(observed::AbstractArray{T}, simulated::AbstractArray{U}; no_value::Float64=-9999.0, n_min::Int=n) where {T <: Number, U <: Number}
    filtered_observed, filtered_simulated = check_array(observed, simulated, no_value=no_value, n_min=n_min)
    mu_o = mean(filtered_observed)
    # Calculate Nash-Sutcliffe Efficiency
    numerator = sum((filtered_simulated .- filtered_observed) .^ 2)
    denominator = sum((filtered_observed .- mu_o) .^ 2)
    nse = 1.0 - (numerator / denominator)
    return nse
end


"""
nse_ts(observed_ta::TimeArray, simulated_ta::TimeArray; no_value::Float64 = -9999.0)

Calculate the Nash-Sutcliffe Efficiency (NSE) from time series data provided as `TimeArray` objects, ensuring that the timestamps match before computation.

# Arguments
- `observed_ta::TimeArray`: TimeArray object containing observed data.
- `simulated_ta::TimeArray`: TimeArray object containing simulated data.
- `no_value::Float64`: A specific value that indicates missing or invalid data in the arrays.

# Returns
- `Float64`: The NSE value calculated from the time-aligned observed and simulated data values.

# Example
```julia
using TimeSeries
dates = Date(2021, 1, 1):Day(1):Date(2021, 1, 10)
observed = TimeArray(dates, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0])
simulated = TimeArray(dates, [1.1, 1.9, 3.1, 3.9, 4.8, 6.1, 6.9, 8.2, 8.8, 10.1])
nse_value = nse_ts(observed, simulated)

Notes
    The function first checks time alignment and then uses previously defined functions to filter data and compute the NSE.
"""
function nse_ts(observed_ta::TimeArray, simulated_ta::TimeArray; no_value::Float64=-9999.0, n_min::Int=n)
    # Verify that the time stamps align
    observed_values, simulated_values = check_ts(observed_ta, simulated_ta)
    # Calculate NSE using the previously defined function
    return nse(observed_values, simulated_values, no_value=no_value, n_min=n_min)
end


"""
    nse_log(observed::Array{Float64}, simulated::Array{Float64}; no_value::Float64 = -9999.0)

Calculate the Nash-Sutcliffe Efficiency (NSE) based on the logarithm of observed and simulated data arrays.
This version of the NSE emphasizes differences in lower magnitudes more significantly than in higher magnitudes by applying a logarithmic transformation to the data.

# Arguments
- `observed::Array{Float64}`: Array of observed data points.
- `simulated::Array{Float64}`: Array of simulated data points.
- `no_value::Float64`: A specific value in the data arrays that indicates missing or invalid data.

# Returns
- `Float64`: The computed log-transformed NSE value.

# Example
```julia
observed = [10.0, 20.0, 30.0, 40.0]
simulated = [9.0, 18.5, 31.0, 39.5]
nse_log_value = nse_log(observed, simulated)

Notes

    Prior to calculation, entries with the no_value are filtered out.

    This function transforms data using natural logarithm, which requires non-zero and positive data.
    """
function nse_log(observed::AbstractArray{T}, simulated::AbstractArray{U},; no_value::Float64=-9999.0, n_min::Integer=n) where {T <: Number, U <: Number}
    filtered_observed, filtered_simulated = check_array(observed, simulated, no_value=no_value, n_min=n_min)
    mu_o = log(mean(filtered_observed))
    safe_log!(x) = x > 0 ? log(x) : x # Handling non-positive values conservatively
    log_observed = map(safe_log!, filtered_observed)
    log_simulated = map(safe_log!, filtered_simulated)
    nse = 1.0 - sum((log_simulated .- log_observed) .^ 2) / sum((log_observed .- mu_o) .^ 2)
    return nse
end

"""
nse_log_ts(observed_ta::TimeArray, simulated_ta::TimeArray; no_value::Float64 = -9999.0)

Calculate the log-transformed Nash-Sutcliffe Efficiency (NSE) for time series data provided as `TimeArray` objects.
This function first verifies that the timestamps in the observed and simulated data match, and then computes the log-transformed NSE.

# Arguments
- `observed_ta::TimeArray`: TimeArray object containing observed data with timestamps.
- `simulated_ta::TimeArray`: TimeArray object containing simulated data with timestamps.
- `no_value::Float64`: Value indicating missing or invalid data.

# Returns
- `Float64`: The computed log-transformed NSE value.

# Example
```julia
using TimeSeries
dates = Date(2021, 1, 1):Day(1):Date(2021, 1, 10)
observed = TimeArray(dates, [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0])
simulated = TimeArray(dates, [9.5, 19.0, 29.5, 39.0, 49.5, 59.0, 69.5, 79.0, 89.5, 99.0])
nse_log_value = nse_log_ts(observed, simulated)

Notes

    Ensures data integrity by verifying time alignment before computing NSE.
    Log transformation is applied to emphasize differences in lower magnitudes.
"""
function nse_log_ts(observed_ta::TimeArray, simulated_ta::TimeArray; no_value::Float64=-9999.0, n_min::Integer=n)
    # Verify that the time stamps align
    observed_values, simulated_values = check_ts(observed_ta, simulated_ta)
    # Calculate NSE using the previously defined function
    return nse_log(observed_values, simulated_values, no_value=no_value, n_min=n_min)
end


"""
    mse(observed::Array{Float64}, predicted::Array{Float64}) -> Float64

Calculate the Mean Squared Error (MSE) between observed and predicted data arrays. This function computes the average of the squares of the differences between observed and predicted values, providing a measure of the quality of the estimator.

# Arguments
- `observed::Array{Float64}`: Array containing the actual observed values.
- `predicted::Array{Float64}`: Array containing the predicted values, corresponding to the observed data.

# Returns
- `Float64`: The calculated mean squared error.

# Example
```julia
observed = [1.0, 2.0, 3.0, 4.0]
predicted = [0.9, 2.1, 2.9, 4.1]
error = mse(observed, predicted)

Notes

    Both input arrays must be of the same length. The function does not handle mismatches in array length or validate for no-values.
    """
function mse(observed::AbstractArray{T}, predicted::AbstractArray{U},; no_value::Float64=-9999.0, n_min::Int=n)where {T <: Number, U <: Number}
    filtered_observed, filtered_simulated = check_array(observed, predicted, no_value=no_value, n_min=n_min)
    errors = (filtered_observed .- filtered_simulated) .^ 2
    return mean(errors)
end

"""
    mse_ts(observed_ta::TimeArray, simulated_ta::TimeArray; no_value::Float64 = -9999.0, n_min::Integer = 30) -> Float64

Calculate the Mean Squared Error (MSE) for time series data provided as `TimeArray` objects, ensuring that the timestamps in the observed and simulated data align and that there are at least `n_min` valid comparisons. This function is designed to measure the average of the squares of the errors between the observed and simulated values.

# Arguments
- `observed_ta::TimeArray`: A `TimeArray` object containing the observed (actual) time series data.
- `simulated_ta::TimeArray`: A `TimeArray` object containing the simulated (predicted) time series data.
- `no_value::Float64`: A specific value that indicates missing or invalid data within the time series. Entries with this value are not considered in the MSE calculation.
- `n_min::Integer`: The minimum number of valid data points required for the MSE calculation. If there are fewer valid data points, the function may raise an error or return a specific indicator (such as `NaN`).

# Returns
- `Float64`: The calculated mean squared error between the valid data points of the observed and simulated data sets.

# Example
```julia
using TimeSeries

# Create sample time series data
dates = Date(2021, 1, 1):Day(1):Date(2021, 1, 10)
observed_values = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]
simulated_values = [110, 190, 310, 390, 490, 610, 690, 790, 890, 1010]
observed_ta = TimeArray(dates, observed_values)
simulated_ta = TimeArray(dates, simulated_values)

# Calculate MSE
mse_result = mse_ts(observed_ta, simulated_ta, no_value=-9999.0, n_min=30)

Notes

    The function relies on check_ts to ensure that both the observed and simulated TimeArray objects have matching timestamps.
    It is important to ensure that the data does not contain too many no_value entries, as this will reduce the number of valid comparisons and could affect the reliability of the MSE calculation.
    If the number of valid data points is less than n_min, consider handling this case appropriately within your broader data analysis workflow, possibly by adjusting n_min or preprocessing data to handle missing values.
    """

function mse_ts(observed_ta::TimeArray, simulated_ta::TimeArray; no_value::Float64=-9999.0, n_min::Integer=n)
    # Verify that the time stamps align
    observed_values, simulated_values = check_ts(observed_ta, simulated_ta)
    # Calculate NSE using the previously defined function
    return mse(observed_values, simulated_values, no_value=no_value, n_min=n_min)
end