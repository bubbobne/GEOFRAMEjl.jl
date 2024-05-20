using Geodesy
using DataFrames
import GeoDataFrames as GDF
using ArchGDAL
import GeoFormatTypes as GFT
using LibGEOS
using GeoArrays

"""
    calculate_area(point::LibGEOS.Geometry, side_length::Float64, polygon::LibGEOS.Geometry) -> Float64

Calculate the area of a square centered at a given point that is also within a specified polygon.

# Arguments
- `point`: The geometric point around which the square is centered.
- `side_length`: The length of the side of the square. This value should be in the same units as the geometry.
- `polygon`: The polygon within which the area calculation is to be confined.

# Returns
- Returns the area of the square that lies within the polygon. If the square is entirely outside the polygon, returns 0.0.

# Example
```julia
point = LibGEOS.Point(1.0, 1.0)
polygon = LibGEOS.fromWKT("POLYGON((0 0, 4 0, 4 4, 0 4, 0 0))")
side_length = 2.5
area = calculate_area(point, side_length, polygon)
println("The area of the square within the polygon is: $area")

"""
function calculate_area(point,polygon)
    # Construct the square geometry around the point
    intersection = LibGEOS.intersection(point, polygon)
    return LibGEOS.area(intersection)
end



function create_square(point, b)
    x, y = LibGEOS.getcoord(point)
    half_s = b / 2
# Calculate coordinates of the square's vertices

# Define the coordinates of the vertices    
    bottom_left = [x - half_s, y - half_s]
    bottom_right = [x + half_s, y - half_s]
    top_right = [x + half_s, y + half_s]
    top_left = [x - half_s, y + half_s]

    coords = [[bottom_left, bottom_right, top_right, top_left, bottom_left]]

    square_polygon = LibGEOS.Polygon(coords)

# Check the polygon by outputting its WKT
    polygon_wkt = LibGEOS.writegeom(square_polygon)
    println("Polygon WKT: $polygon_wkt")
    return  square_polygon
end

"""
polygons_contains_any_point(grid_gdf::GeoDataFrame, polygons_gdf::GeoDataFrame, b::Float64) -> Dict{Any,Array{Tuple{Any,Float64},1}}

Determines which points from a grid of points fall within each polygon in a given set of polygons, calculates the area of a square centered at each point that is within the polygon, and stores these results in a dictionary indexed by polygon IDs.
Arguments

    grid_gdf: A GeoDataFrame containing points, each representing the center of a square. Must include a column ID.
    polygons_gdf: A GeoDataFrame containing polygons. Must include a column ID for indexing results.
    b: The length of the side of each square centered at the grid points. The unit should match that of the geometries.

Returns

    Returns a dictionary where keys are the IDs of the polygons and values are arrays of tuples. Each tuple contains the ID of a point and the normalized area of the square centered at the point that falls within the polygon.

Example
using ArchGDAL
using GeoDataFrames

grid_gdf = GeoDataFrame(load_shapefile("points.shp"))
polygons_gdf = GeoDataFrame(load_shapefile("polygons.shp"))
side_length = 250.0
results = polygons_contains_any_point(grid_gdf, polygons_gdf, side_length)
for (polygon_id, data) in results
    println("Polygon ID $polygon_id has the following points and areas: $data")
end

"""
function polygons_contains_any_point(grid_gdf, polygons_gdf, b)
    results = Dict()
    df = DataFrame(id = grid_gdf.data, geometry=grid_gdf.geometry)
    df.geometry = [create_square(geom, b) for geom in df.geometry]
    for (idx, polygon) in enumerate(polygons_gdf.geometry)
        polygon_id = polygons_gdf[idx, :ID]
        points_in_polygon = [(point.id, point.geometry) for point in eachrow(df) if LibGEOS.intersects(polygon, point.geometry)]
        if !isempty(points_in_polygon)
            area_tot = LibGEOS.area(polygon)
            areas = [calculate_area(pt[2],polygon, b) for pt in points_in_polygon]
            @assert isapprox(sum(areas), area_tot, atol=1e-8)
            point =  [(id=points_in_polygon[i][1], area=areas[i] / area_tot) for i in 1:length(points_in_polygon)]
            results[polygon_id] = point
        else
            results[polygon_id] = []  # No points in this polygon
        end

    end
    return results
end