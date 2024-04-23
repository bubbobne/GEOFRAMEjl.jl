using TimeSeries, Dates


"""
    correctDateFormat(path::String) -> String

Extract the correct date format. OMS file contain often MM for nomth and mm for minutes.

# Arguments
- `path::String`: the original date formatter.

# Returns
- `String`: the corrected date formatter.

# Example
```julia-repl
julia> ts = read_timeseries("yyyy-MM-dd hh:mm")

"""



function correct_date_format!(date_formatter::String)
    date_formatter = replace(date_formatter, "mm" => "temporary_placeholder")
    date_formatter = replace(date_formatter, "MM" => "mm")
    date_formatter = replace(date_formatter, "temporary_placeholder" => "MM")
    return date_formatter
end

"""
    read_OMS_timeserie(filepath::String) -> TimeSeries

Reads an OMS file (format as csv) from the specified path and returns a time series object.

# Arguments
- `filepath::String`: The file path from which to read the time series data.

# Returns
- `TimeSeries`: A time series object constructed from the data in the file.

# Example
```julia-repl
julia> ts = read_timeseries("data/timeseries.csv")
TimeSeries(...)
"""

function read_OMS_timeserie(filepath::String)
    # Initialize arrays for timestamps and values
    timestamps = DateTime[]
    values = Float64[]
    column_name = ""
    open(filepath, "r") do file
        lines = readlines(file)

        # Extract column name from the line starting with "ID,,"
        id_line = findfirst(l -> startswith(l, "ID,,"), lines)
        column_name = split(lines[id_line], ",")[3]
        format_line = findfirst(l -> startswith(l, "Format,"), lines)
        date_format = correct_date_format!(String(split(lines[format_line], ",")[2]))

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
    write_OMS_timeserie(filepath::String) -> TimeSeries

Write a time series as OMS file (format as csv) to the specified path.

# Arguments
- `filepath::String`: The file path from which to write the time series data.

# Example
```julia-repl
julia> write_timeseries("data/timeseries.csv")
"""
function write_OMS_timeserie(ta::TimeArray, file_path::String)
    try
        column_names = colnames(ta)
        column_header = join(["value_" * string(name) for name in column_names], ",")
        type_strings = []
        for col in column_names
            col_type = typeof(values(ta[Symbol(col)])[1])
            if col_type <: Float64 || col_type <: Float32
                push!(type_strings, "Double")
            elseif col_type <: Integer
                push!(type_strings, "Integer")
            else
                push!(type_strings, "Unknown")  # Fallback type
            end
        end

        # Ope
        open(file_path, "w") do f
            write(f, "@T,table\n")
            write(f, "Created,$(Dates.format(now(), "yyyy-mm-dd HH:MM"))\n")
            write(f, "Author,GEOFramejl package\n")
            write(f, "@H,timestamp,$column_header\n")
            write(f, "ID,," * join(column_names, ",") * "\n")
            write(f, "Type,Date," * join(type_strings, ",") * "\n")
            timestamp_format = "yyyy-mm-dd HH:MM"
            format_row = timestamp_format * join(fill(",", length(column_names)), "")
            write(f, "Format,$format_row,\n")

            for i in eachindex(timestamp(ta))
                formatted_timestamp = Dates.format(timestamp(ta)[i], "yyyy-mm-dd HH:MM")
                values_to_write = [values(ta[Symbol(name)])[i] for name in column_names]
                value_line = join(values_to_write, ",")
                write(f, ",$formatted_timestamp,$value_line\n")
            end
        end
        return true
    catch e
        println("An error occurred: $e")
        return false
    end
end
