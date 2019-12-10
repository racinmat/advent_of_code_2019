using DrWatson
quickactivate(@__DIR__)
using Combinatorics, DataStructures, LinearAlgebra
import Base: atan, findall
using Base.Iterators: flatten
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->replace(x, "."=>"0") |> x->replace(x, "#"=>"1") |> x->split(x, '\n') .|> collect .|>
    (x->parse.(Int, x)) |> x->hcat(x...) |> x->x'
# data = cur_day |> test_input |> x->rstrip(x, '\n') |> x->replace(x, "."=>"0") |> x->replace(x, "#"=>"1") |> x->split(x, '\n') .|> collect .|>
#     (x->parse.(Int, x)) |> x->hcat(x...) |> x->x'

function lies_between(a::CartesianIndex, b::CartesianIndex, between::CartesianIndex)::Bool
    crossproduct = (between[2] - a[2]) * (b[1] - a[1]) - (between[1] - a[1]) * (b[2] - a[2])

    # compare versus epsilon for floating point values, or != 0 if using integers
    if abs(crossproduct) != 0
        return false
    end
    dotproduct = (between[1] - a[1]) * (b[1] - a[1]) + (between[2] - a[2])*(b[2] - a[2])
    if dotproduct < 0
        return false
    end

    squaredlengthba = (b[1] - a[1])*(b[1] - a[1]) + (b[2] - a[2])*(b[2] - a[2])
    if dotproduct > squaredlengthba
        return false
    end
    true
end

function findall(f::Function, a::Array{T, N}) where {T, N}
    j = 1
    b = Vector{CartesianIndex{2}}(undef, length(a))
    @inbounds for i in CartesianIndices(a)
        @inbounds if f(a[i])
            b[j] = i
            j += 1
        end
    end
    resize!(b, j-1)
    sizehint!(b, length(b))
    return b
end

function visibility(points, point1::CartesianIndex, point2::CartesianIndex)::Bool
    vis = true
    i = first(setdiff(Set(points), Set([point1, point2])))
    for i in setdiff(Set(points), Set([point1, point2]))
        vis = vis && !lies_between(point1, point2, i)
    end
    vis
end

function calc_sees(points)
    sees = DefaultDict{CartesianIndex, Int}(()->0)
    for (point1, point2) in combinations(points, 2)
        vis_res = visibility(points, point1, point2)
        if vis_res
            sees[point1] +=1
            sees[point2] +=1
        end
    end
    sees
end

function part1()
    points = findall(x->x==1, data)
    sees = calc_sees(points)
    sees |> values |> maximum
end

atan(i::CartesianIndex) = atan(i[2], i[1])
norm2(x) = norm(x, 2)
norm2(x::CartesianIndex) = norm2(Tuple(x))

function vap_iter!(data, distances_m, angles_m, angles, i)
    a_len = length(angles)
    a_idx = i == a_len ? a_len : i % a_len
    a_cur = angles[a_idx]
    points_in_line = findall(x->x==a_cur, angles_m)
    if isempty(points_in_line)
        deleteat!(angles, a_idx)
        points_in_line = findall(x->x==angles[a_idx], angles_m)
    end
    min_dist =  distances_m[points_in_line] |> minimum
    closest_point = first(p for p in points_in_line if distances_m[p] == min_dist)
    data[closest_point] = 0
    distances_m[closest_point] = Inf32
    closest_point
end

function part2()
    grid = copy(data)
    points = findall(x->x==1, grid)
    sees = calc_sees(points)
    max_val = sees |> values |> maximum
    # point from part 1
    point = first(key for key in keys(sees) if sees[key] == max_val)
    sub_point(x) = x - point

    # starting vaporizing
    angles_m = zeros(Float32, size(grid))
    for i in CartesianIndices(angles_m)
        angles_m[i] = atan(i - point)
    end
    distances_m = ones(Float32, size(grid)) * Inf32
    for i in points
        distances_m[i] = norm2(i - point)
    end
    # todo: add filtering of asteroids
    angles = angles_m |> flatten |> unique |> sort |> reverse
    last_point = point
    for i in 1:200
        closest_point = vap_iter!(grid, distances_m, angles_m, angles, i)
        last_point = closest_point
    end
    last_point[1] * 100 + last_point[2]
end

using BenchmarkTools

println(part1())
@btime part1()
# submit(part1(), cur_day, 1)
println(part2())
@btime part2()
# submit(part2(), cur_day, 2)
