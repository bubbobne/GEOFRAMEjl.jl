using Geodesy
using DataFrames
import GeoDataFrames as GDF
using ArchGDAL
import GeoFormatTypes as GFT
using LibGEOS
using GeoArrays

"""
    create_grid(x_start, x_end, x_step, y_start, y_end, y_step, epsg_code)

Create a grid of points within the specified range and steps, and assign a coordinate system EPSG code.
"""
function create_grid(x_start, x_end, x_step, y_start, y_end, y_step)
    points = [ArchGDAL.createpoint(x, y) for x = x_start:x_step:x_end, y = y_start:y_step:y_end]
    return DataFrame(geometry=vec(points), data=collect(1:length(points)))
end


"""
    save_grid(gdf, file

Save a GeoDataFrame containing points to a shapefile with the given filename.
"""
function save_grid(gdf, filename, epsg_code; name="grid")
    GDF.write(filename, gdf, layer_name=name, crs=GFT.EPSG(epsg_code))
end

"""
    save_individual_points(gdf, epsg_code, path)

Save each point from a collection of points into individual shapefiles, named sequentially.
"""
function save_individual_points(gdf, path, epsg_code; name="grid")
    points = gdf.geometry
    for (idx, pt) in enumerate(points)
        single_pt_gdf = GeoDataFrame(geometry=[pt], crs="EPSG:$epsg_code")
        GDF.write(path * "/point_$(idx).shp", single_pt_gdf, layer_name=name, crs=GFT.EPSG(epsg_code))
    end
end

"""
    filter_points(grid_gdf::GeoDataFrame, polygons_gdf::GeoDataFrame) -> GeoDataFrame

Filter out points from a grid that do not lie within any of the polygons provided in a separate GeoDataFrame. 
Additionally, check and report if any polygon does not contain at least one point from the grid.

# Arguments
- `grid_gdf::GeoDataFrame`: A GeoDataFrame containing a set of points (grid). 
  Each point should be represented as a `Point` geometry. The GeoDataFrame should include a `crs` attribute specifying its coordinate reference system.
- `polygons_gdf::GeoDataFrame`: A GeoDataFrame containing polygon geometries. 
  Each entry should represent a single polygon, and the GeoDataFrame should include an `id` attribute for each polygon for identification purposes.

# Returns
- `GeoDataFrame`: A new GeoDataFrame containing only the points that lie within any of the polygons. 
  This GeoDataFrame includes two columns: `geometry` containing the point geometries and `polygon_id` indicating the ID of the polygon each point is within.

# Side Effects
- Prints a message for each polygon that contains no points, indicating the `id` of the empty polygon.

# Example
```julia
grid_gdf = create_grid(0, 1000, 100, 0, 1000, 100, "EPSG:32633")
polygons_gdf = GeoDataFrames.read("polygons.shp")  # Ensure polygons have an 'id' attribute
filtered_grid_gdf = filter_points(grid_gdf, polygons_gdf)

This function is particularly useful in spatial analyses where it's necessary to identify or remove points based on their geographical location relative to other features (polygons in this case). It supports workflows in environmental science, urban planning, and geographical data management, where understanding the relationship between points and regions is crucial.
Notes

    The function assumes that the input GeoDataFrame objects are properly formatted and that the polygons contain an id attribute for identification.
    Ensure that the coordinate reference system (CRS) of both GeoDataFrames matches or is appropriately handled before using this function to avoid inconsistencies in spatial queries.
    """
function filter_points(grid_gdf, polygons_gdf; buffer=1000)
    # Prepare a DataFrame to collect filtered points
    polygons_contains_any_point(grid_gdf, polygons_gdf)
    columns = names(grid_gdf)
    filtered_points = DataFrame([col => Vector{eltype(grid_gdf[!, col])}() for col in columns])
    # Calculate the union of all polygons and apply a 1 km buffer
    union_polygon = reduce(LibGEOS.union, polygons_gdf.geometry)
    buffered_union = LibGEOS.buffer(union_polygon, buffer)  # Assuming meters as unit
    points_in_buffered_union = [i for (i, point) in enumerate(grid_gdf.geometry) if LibGEOS.contains(buffered_union, point)]
    if !isempty(points_in_buffered_union)
        append!(filtered_points, grid_gdf[points_in_buffered_union, :])
    end

    return DataFrame(filtered_points)
end



"""
    polygons_contains_any_point(grid_gdf, polygons_gdf)

Iterates through a set of polygons and checks if each polygon contains any points from a given grid.
If a polygon has an area greater than 10,000 and contains no points, the function prints the polygon's ID,
its area, and its index in the list of polygons.

# Parameters
- `grid_gdf::GeoDataFrame`: A GeoDataFrame containing point geometries.
- `polygons_gdf::GeoDataFrame`: A GeoDataFrame containing polygon geometries.

# Dependencies
- `LibGEOS`: A library providing the `contains` and `area` functions for geometric operations.

# Example
```julia
using GeoDataFrames
using LibGEOS

# Example GeoDataFrames for grid_gdf and polygons_gdf
grid_gdf = GeoDataFrame(geometry=[Point(1, 2), Point(3, 4), Point(5, 6)])
polygons_gdf = GeoDataFrame(geometry=[Polygon([(0, 0), (0, 10), (10, 10), (10, 0), (0, 0)]), Polygon([(10, 10), (10, 20), (20, 20), (20, 10), (10, 10)])], ID=[1, 2])

# Call the function
polygons_contains_any_point(grid_gdf, polygons_gdf)

Notes

    Ensure that grid_gdf and polygons_gdf are correctly formatted GeoDataFrames with geometries compatible with LibGEOS.
    The function uses LibGEOS.contains to check if a point is within a polygon and LibGEOS.area to calculate the area of the polygon.
    Adjust the area threshold and printed information as needed for your specific use case.
"""

function polygons_contains_any_point(grid_gdf, polygons_gdf)
    for (idx, polygon) in enumerate(polygons_gdf.geometry)
        points_in_polygon = [point for point in grid_gdf.geometry if LibGEOS.contains(polygon, point)]
        area = LibGEOS.area(polygon)
        if area > 10000 && isempty(points_in_polygon)
            println("No points found in polygon with ID: $(polygons_gdf.ID[idx])")
            println("Area: $(area)")
            println("idx: $(idx)")
        end
    end
end




"""
    get_value_from_raster(grid_gdf, raster)

Extracts raster values at the locations specified by the points in `grid_gdf` and appends these values as a new column in `grid_gdf`.

# Parameters
- `grid_gdf::GeoDataFrame`: A GeoDataFrame containing point geometries.
- `raster::Array`: A raster array from which to extract values.

# Returns
- `grid_gdf::GeoDataFrame`: The input GeoDataFrame with an additional column `:raster_value` containing the raster values at each point's location.

# Notes
- Assumes `point` is a LibGEOS point geometry.
- Handles out-of-bounds points by assigning a default value of `-9999.0`.
- Raster values are returned as `Float16`.

# Example
```julia
using GeoDataFrames
using LibGEOS
using ArchGDAL

# Example GeoDataFrame for grid_gdf
grid_gdf = GeoDataFrame(geometry=[Point(1, 2), Point(3, 4), Point(5, 6)])

# Example raster (assuming a 2D array for simplicity)
raster = rand(10, 10)  # Replace with actual raster data

# Call the function
updated_grid_gdf = get_value_from_raster(grid_gdf, raster)

"""
function get_value_from!(grid_gdf, raster)
    function get_raster_value(point, raster)
        # Assuming point is a LibGEOS point geometry
        x, y = ArchGDAL.getpoint(point, 0)
        # Get the pixel value at coordinates (x, y)
        try
            value = raster[x, y][1]
            result = ismissing(value) ? -9999.0 : value
            return Float16(result)
        catch e
            if isa(e, BoundsError)
                # TODO check for env variables
                return Float16(-9999.0)
            else
                println("An unexpected error occurred: $e")
            end
        end
    end

    # Append a new column for raster values
    raster_values = [get_raster_value(point, raster) for point in grid_gdf.geometry]
    grid_gdf[!, :raster_value] = raster_values

    # Continue with the existing logic of the function...
    # Filter polygons, check areas, etc.

    return grid_gdf  # Now including raster values
end


function get_epsg(df)
    a = GDF.metadata(df)["crs"]
    return convert(GFT.EPSG,a).val[1]
end

function intersect_grid(grid_gdf, polygons_gdf)
    # Prepare a DataFrame to collect filtered points
    source_crs = GFT.EPSG(get_epsg(grid_gdf))
    target_crs = GFT.EPSG(get_epsg(polygons_gdf))
    columns = names(grid_gdf)
    if source_crs!=target_crs
        grid_gdf.geometry = GDF.reproject(grid_gdf.geometry,  source_crs, target_crs, order=:trad)
    end
    filtered_points = DataFrame([col => Vector{eltype(grid_gdf[!, col])}() for col in columns])
    union_polygon = reduce(LibGEOS.union, polygons_gdf.geometry)
    grid_in_buffered_union = [i for (i, poly) in enumerate(grid_gdf.geometry) if (LibGEOS.contains(union_polygon, poly) || LibGEOS.overlaps(union_polygon, poly) )]
    if !isempty(grid_in_buffered_union)
        append!(filtered_points, grid_gdf[grid_in_buffered_union, :])
    end
    return DataFrame(filtered_points)
end