using TimeSeries, Statistics, Dates, Distributions, DataFrames



clean = data -> filter(isfinite, data)


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
    clean_data = clean(data)
    n = length(clean_data)
    if n == 0
        return NaN
    end
    data_sorted = sort(clean_data)
    weights = [pdf(Beta(n * prob + 1, n * (1 - prob) + 1), (i - 0.5) / n) for i in 1:n]
    return sum(data_sorted .* weights) / sum(weights)
end



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
function find_outliers(timearray::TimeArray; method::String="Tukey", threshold::Float64=3.5, contamination::Float64=0.1)
    data = values(timearray)
    ts = timestamp(timearray)
    outlier_indices = []
    # Method mapping with parameters
    methods = Dict(
        "Tukey" => (tukey, NamedTuple()),
        "TukeyHD" => (tukey_hd, NamedTuple()),
        "MAD" => (mad_outliers, (threshold=threshold,)),
        "MADHD" => (mad_hd, (threshold=threshold,)),
        "DMAD" => (double_mad, (threshold=threshold,)),
        "DMADHD" => (double_mad_hd, (threshold=threshold,))
    )
    # Get the appropriate method and its parameters
    if haskey(methods, method)
        outlier_method, params = methods[method]
    else
        error("Unsupported method: $method")
    end

    # Collect outlier indices for each column
    for col in eachcol(data)
        if isempty(col)
            outlier_indices = []
        else
            if isempty(params)
                push!(outlier_indices, outlier_method(col))
            else
                push!(outlier_indices, outlier_method(col; params...))
            end
        end
    end

    # Construct the TimeArray of outliers
    outliers = TimeArray[]
    for (col_index, indices) in enumerate(outlier_indices)
        outlier_dates = ts[indices]
        outlier_values = data[indices, col_index]
        push!(outliers, TimeArray(outlier_dates, outlier_values))
    end

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
function tukey(data::AbstractVector{Float64})
    d = clean(data)
    if isempty(d)
        return []
    else
        q1, q3 = quantile(d, [0.25, 0.75])
        iqr = q3 - q1
        lower_bound = q1 - 1.5 * iqr
        upper_bound = q3 + 1.5 * iqr
        print(q3)

        return findall(x -> x < lower_bound || x > upper_bound, data)
    end
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
function tukey_hd(data::AbstractVector{Float64})
    q1 = harrell_davis_quantile(data, 0.25)
    q3 = harrell_davis_quantile(data, 0.75)
    iqr = q3 - q1
    lower_bound = q1 - 1.5 * iqr
    upper_bound = q3 + 1.5 * iqr
    return findall(x -> x < lower_bound || x > upper_bound, data)

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

function mad_outliers(data::AbstractVector{Float64}; threshold::Float64=3.0)
    median_value = median(clean(data))
    mad = 1.4826 * median(abs.(clean(data) .- median_value))
    lower_bound = median_value - threshold * mad
    upper_bound = median_value + threshold * mad
    return findall(x -> x < lower_bound || x > upper_bound, data)

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
function mad_hd(data::AbstractVector{Float64}; threshold::Float64=3.0)
    median_value = harrell_davis_quantile(data, 0.5)
    mad = 1.4826 * harrell_davis_quantile(abs.(data .- median_value), 0.5)
    lower_bound = median_value - threshold * mad
    upper_bound = median_value + threshold * mad
    return findall(x -> x < lower_bound || x > upper_bound, data)

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
function double_mad(data::AbstractVector{Float64}; threshold::Float64=3.0)
    median_value = median(clean(data))
    left_mad = 1.4826 * median(abs.(clean(data[data.<=median_value]) .- median_value))
    right_mad = 1.4826 * median(abs.(clean(data[data.>=median_value]) .- median_value))
    lower_bound = median_value - threshold * left_mad
    upper_bound = median_value + threshold * right_mad
    return findall(x -> x < lower_bound || x > upper_bound, data)
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
function double_mad_hd(data::AbstractVector{Float64}; threshold::Float64=3.0)
    median_value = harrell_davis_quantile(data, 0.5)
    left_mad = 1.4826 * harrell_davis_quantile(abs.(data[data.<=median_value] .- median_value), 0.5)
    right_mad = 1.4826 * harrell_davis_quantile(abs.(data[data.>=median_value] .- median_value), 0.5)
    lower_bound = median_value - threshold * left_mad
    upper_bound = median_value + threshold * right_mad
    col_indices = findall(x -> x < lower_bound || x > upper_bound, data)
    return col_indices
end
