using TimeSeries, Statistics, Dates, Distributions
"""
        find_outliers(timearray::TimeArray, method::String = "Tukey")

    Finds outliers in a TimeArray using the specified method.

    # Arguments
    - `timearray::TimeArray`: The TimeArray containing the data to analyze.
    - `method::String`: The method to use for finding outliers. Default is "Tukey".

    # Returns
    - A TimeArray containing only the outliers.

    # Example
    ```julia
    dates = Date(2023, 1, 1):Day(1):Date(2023, 1, 10)
    values = [10, 12, 10, 15, 100, 10, 11, 10, 14, 13]
    ta = TimeArray(dates, values)
    outliers = find_outliers(ta)
    println(outliers)
"""
function find_outliers(timearray::TimeArray; method::String="Tukey", threshold::Float64=3.5)
    data = values(timearray)
    outlier_indices = Int[]

    # Determine which method to use for finding outliers
    if method == "Tukey"
        outlier_indices = tukey(data)
    elseif method == "TukeyHD"
        outlier_indices = tukey_hd(data)
    elseif method == "MAD"
        outlier_indices = mad_outliers(data, threshold=threshold)
    elseif method == "MADHD"
        outlier_indices = mad_hd(data, threshold=threshold)
    elseif method == "DMAD"
        outlier_indices = double_mad(data, threshold=threshold)
    elseif method == "DMADHD"
        outlier_indices = double_mad_hd(data, threshold=threshold)
    else
        error("Unsupported method: $method")
    end

    # Extract the dates and values of the outliers
    outliers = timearray[outlier_indices]
    return outliers
end


"""
    tukey(data::AbstractVector)

    Finds outliers in the data using the Tukey method.
    Arguments

        data::AbstractVector: The data to analyze.

    Returns

        An array of indices corresponding to the outliers in the data.

    Example

    julia

    data = [10, 12, 10, 15, 100, 10, 11, 10, 14, 13]
    outlier_indices = tukey(data)
    println(outlier_indices)
"""
function tukey(data)
    q1 = quantile(data, 0.25)
    q3 = quantile(data, 0.75)
    iqr = q3 - q1
    lower_bound = q1 - 1.5 * iqr
    upper_bound = q3 + 1.5 * iqr
    # Find the indices of the outliers
    outlier_indices = findall(x -> x < lower_bound || x > upper_bound, data)
    return outlier_indices
end

"""
tukey_hd(data::AbstractVector)

Finds outliers in the data using Tukey's fences with Harrell-Davis quantile estimation.
Arguments

    data::AbstractVector: The data to analyze.

Returns

    An array of indices corresponding to the outliers in the data.

Example

julia

data = [10, 12, 10, 15, 100, 10, 11, 10, 14, 13]
outlier_indices = tukey_hd(data)
println(outlier_indices)

"""
function tukey_hd(data::AbstractVector)
    q1 = harrell_davis_quantile(data, 0.25)
    q3 = harrell_davis_quantile(data, 0.75)
    iqr = q3 - q1
    lower_bound = q1 - 1.5 * iqr
    upper_bound = q3 + 1.5 * iqr
    # Find the indices of the outliers
    outlier_indices = findall(x -> x < lower_bound || x > upper_bound, data)
    return outlier_indices
end

"""
harrell_davis_quantile(data::AbstractVector, prob::Float64)

Estimates the quantile of the data using the Harrell-Davis method.
Arguments

    data::AbstractVector: The data to analyze.
    prob::Float64: The probability for the quantile (e.g., 0.25 for the 25th percentile).

Returns

    The estimated quantile value.

Example
data = [10, 12, 10, 15, 100, 10, 11, 10, 14, 13]
q1 = harrell_davis_quantile(data, 0.25)
println(q1)

"""

function harrell_davis_quantile(data::AbstractVector, prob::Float64)
    n = length(data)
    data_sorted = sort(data)
    weights = [pdf(Beta(n * prob + 1, n * (1 - prob) + 1), (i - 0.5) / n) for i in 1:n]
    return sum(data_sorted .* weights) / sum(weights)
end


"""
    mad_outliers(data::AbstractVector; threshold::Float64 = 3.5)

    Finds outliers in the data using the Median Absolute Deviation (MAD) method.
    Arguments
        data::AbstractVector: The data to analyze.
        threshold::Float64: The threshold for identifying outliers. Default is 3.5.

    Returns
        An array of indices corresponding to the outliers in the data.

    Example
    data = [10, 12, 10, 15, 100, 10, 11, 10, 14, 13]
    outlier_indices = mad_outliers(data)
    println(outlier_indices)

"""

function mad_outliers(data::AbstractVector; threshold::Float64=3.5)
    median_value = median(data)
    mad =1.4826 * median(abs.(data .- median_value))
    lower_bound = median_value - threshold * mad
    upper_bound = median_value + threshold * mad
    # Find the indices of the outliers
    outlier_indices = findall(x -> x < lower_bound || x > upper_bound, data)
    return outlier_indices
end

"""
    mad_hd(data::AbstractVector; threshold::Float64 = 3.5)

    Finds outliers in the data using the Median Absolute Deviation (MAD) method with Harrell-Davis quantile estimation.
    Arguments
        data::AbstractVector: The data to analyze.
        threshold::Float64: The threshold for identifying outliers. Default is 3.5.

    Returns
        An array of indices corresponding to the outliers in the data.

    Example

    data = [10, 12, 10, 15, 100, 10, 11, 10, 14, 13]
    outlier_indices = mad_hd(data)
    println(outlier_indices)

"""
function mad_hd(data::AbstractVector; threshold::Float64=3.5)
    median_value = harrell_davis_quantile(data, 0.5)
    mad =1.4826 * harrell_davis_quantile(abs.(data .- median_value), 0.5)
    lower_bound = median_value - threshold * mad
    upper_bound = median_value + threshold * mad
    # Find the indices of the outliers
    outlier_indices = findall(x -> x < lower_bound || x > upper_bound, data)
    return outlier_indices
end


"""
    double_mad(data::AbstractVector; threshold::Float64 = 3.5)

    Finds outliers in the data using the Double Median Absolute Deviation (Double MAD) method.
    Arguments

        data::AbstractVector: The data to analyze.
        threshold::Float64: The threshold for identifying outliers. Default is 3.5.

    Returns

        An array of indices corresponding to the outliers in the data.

    Example

    data = [10, 12, 10, 15, 100, 10, 11, 10, 14, 13]
    outlier_indices = double_mad(data)
    println(outlier_indices)

"""
function double_mad(data::AbstractVector; threshold::Float64=3.5)
    median_value = median(data)
    left_mad = 1.4826 *median(abs.(data[data.<=median_value] .- median_value))
    right_mad = 1.4826 *median(abs.(data[data.>=median_value] .- median_value))
    lower_bound = median_value - threshold * left_mad
    upper_bound = median_value + threshold * right_mad
    # Find the indices of the outliers
    outlier_indices = findall(x -> x < lower_bound || x > upper_bound, data)
    return outlier_indices
end

"""
    double_mad_hd(data::AbstractVector; threshold::Float64 = 3.5)

    Finds outliers in the data using the Double Median Absolute Deviation (Double MAD) method with Harrell-Davis quantile estimation.
    Arguments

        data::AbstractVector: The data to analyze.
        threshold::Float64: The threshold for identifying outliers. Default is 3.5.

    Returns

        An array of indices corresponding to the outliers in the data.

    Example

    data = [10, 12, 10, 15, 100, 10, 11, 10, 14, 13]
    outlier_indices = double_mad_hd(data)
    println(outlier_indices)

"""
function double_mad_hd(data::AbstractVector; threshold::Float64=3.5)
    median_value = harrell_davis_quantile(data, 0.5)
    left_mad = 1.4826 * harrell_davis_quantile(abs.(data[data.<=median_value] .- median_value), 0.5)
    right_mad = 1.4826 * harrell_davis_quantile(abs.(data[data.>=median_value] .- median_value), 0.5)
    lower_bound = median_value - threshold * left_mad
    upper_bound = median_value + threshold * right_mad
    # Find the indices of the outliers
    outlier_indices = findall(x -> x < lower_bound || x > upper_bound, data)
    return outlier_indices
end