using TimeSeries


function correctDateFormat(date_component)
    date_component = replace(date_component, "mm" => "temporary_placeholder")
    date_component = replace(date_component, "MM" => "mm")
    date_component = replace(date_component, "temporary_placeholder" => "MM")
    return date_component
end

"""
    read_OMS_timeserie(path::String) -> TimeSeries

Reads an OMS file (format as csv) from the specified path and returns a time series object.

# Arguments
- `path::String`: The file path from which to read the time series data.

# Returns
- `TimeSeries`: A time series object constructed from the data in the file.

# Example
```julia-repl
julia> ts = read_timeseries("data/timeseries.csv")
TimeSeries(...)
"""

function read_OMS_timeserie(filepath)
    # Initialize arrays for timestamps and values
    timestamps = DateTime[]
    values = Float64[]
    column_name = ""
    open(filepath, "r") do file
        lines = readlines(file)

        # Extract column name from the line starting with "ID,,"
        id_line = findfirst(l -> startswith(l, "ID,,"), lines)
        column_name = split(lines[id_line], ",")[3]

        # Extract and correct the date format from the line starting with "Format,"
        format_line = findfirst(l -> startswith(l, "Format,"), lines)
        date_format = correctDateFormat(split(lines[format_line], ",")[2])

        # Find where data starts; data lines start after "Format," line
        start_index = format_line + 1

        # Iterate over the lines containing data
        for i in start_index:length(lines)
            line = lines[i]
            data = filter(!isempty, split(line, ","))
            try
                timestamp = DateTime(data[1], date_format)
                value = parse(Float64, data[2])
                push!(timestamps, timestamp)
                push!(values, value)
            catch error
                println("Error parsing line $i: $error")
            end
        end
    end
        # Return as a TimeArray using the extracted column name
        return TimeArray(timestamps, values, Symbol.([column_name]))
end



"""
    write_OMS_timeserie(path::String) -> TimeSeries

    Write a time series as OMS file (format as csv) to the specified path.

# Arguments
- `path::String`: The file path from which to write the time series data.

# Example
```julia-repl
julia> write_timeseries("data/timeseries.csv")
"""
function write_OMS_timeserie(path)
    return "Write OMS!"
end
