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
function read_OMS_timeserie(filepath::String; no_value=-9999)
    # Initialize a dictionary to store values for each ID
    data_dict = Dict{Symbol, Vector{Float64}}()
    timestamps = DateTime[]
    column_names = Symbol[]
    open(filepath, "r") do file
        lines = readlines(file)

        # Extract column names from the line starting with "ID,,"
        id_line = findfirst(l -> startswith(l, "ID,,"), lines)
        column_names = Symbol.(split(lines[id_line], ",")[3:end])

        # Initialize the dictionary with column names
        for name in column_names
            data_dict[name] = Float64[]
        end

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
                push!(timestamps, timestamp)
                for (j, name) in enumerate(column_names)
                    value = parse(Float64, data[j + 1])
                    push!(data_dict[name], value)
                end
    
            catch error
                println("Error parsing line $i: $error")
            end
        end
    end

    # Convert dictionary values to a matrix
    values_matrix = hcat([data_dict[key] for key in column_names]...)
    values_matrix[values_matrix.==no_value].=NaN
    # Return as a TimeArray
    return TimeArray(timestamps, values_matrix, column_names)
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
function write_OMS_timeserie(ta::TimeArray, file_path::String; timestamp_format = "yyyy-mm-dd HH:MM", author = "GEOFramejl package")
    try
        column_names = colnames(ta)
        column_header = join(["value_" * string(name) for name in column_names], ",")
        
        function col_type(values)
            first_value = values[1]
            if first_value isa Float64 || first_value isa Float32
                return "double"
            elseif first_value isa Integer
                return "integer"
            else
                return "unknown"  # Fallback type
            end
        end
        # Precompute column types
        type_strings = [col_type(ta[:, Symbol(col)]) for col in column_names]
        


        # Cache the values and symbols
        ta_symbols = Symbol.(column_names)
        ta_values = [values(ta[:, sym]) for sym in ta_symbols]

        # Open file and write header
        open(file_path, "w") do f
            write(f, "@T,table\n")
            write(f, "Created,$(Dates.format(now(), timestamp_format))\n")
            write(f, "Author, $author\n")
            write(f, "@H,timestamp,$column_header\n")
            write(f, "ID,," * join(column_names, ",") * "\n")
            write(f, "Type,Date," * join(type_strings, ",") * "\n")
            format_row = timestamp_format * join(fill(",", length(column_names)), "")
            write(f, "Format,$format_row,\n")
            
            # Write data
            for i in eachindex(timestamp(ta))
                formatted_timestamp = Dates.format(timestamp(ta)[i], timestamp_format)
                values_to_write = [ta_values[j][i] for j in 1:length(ta_values)]
                value_line = join(values_to_write, ",")
                write(f, "$formatted_timestamp,$value_line\n")
            end
        end
        return true
    catch e
        println("An error occurred: $e")
        return false
    end
end
