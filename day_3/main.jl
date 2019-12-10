using DrWatson
quickactivate(@__DIR__)
using LinearAlgebra, SparseArrays, Dates
import Base: min, max, findall
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> read_lines |> x->split.(x, ',')
# data = split("R8,U5,L5,D3\nU7,R6,D4,L4", '\n') .|> x->split(x, ',')
# data = split("R75,D30,R83,U83,L12,D49,R71,U7,L72\nU62,R66,U55,R34,D71,R55,D58,R83", '\n') .|> x->split(x, ',')
# data = split("R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51\nU98,R91,D20,R16,D67,R40,U7,R15,U6,R7", '\n') .|> x->split(x, ',')
line1, line2 = data
const dirs1 = getindex.(line1, 1)
const lens1 = map(x->parse(Int, x[2:end]), line1)
const dirs2 = getindex.(line2, 1)
const lens2 = map(x->parse(Int, x[2:end]), line2)

norm1(x) = norm(x, 1)
function move(dir::Char, len::Int, point::CartesianIndex)
    if dir == 'L'
        return point - CartesianIndex(0, len)
    elseif dir == 'R'
        return point + CartesianIndex(0, len)
    elseif dir == 'U'
        return point - CartesianIndex(len, 0)
    elseif dir == 'D'
        return point + CartesianIndex(len, 0)
    end
end

function get_range(dir::Char, len::Int, point::CartesianIndex)::Tuple{Union{Int, UnitRange{Int}}, Union{Int, UnitRange{Int}}}
    if dir == 'L'
        return @inbounds point[1], point[2]-len:point[2]-1
    elseif dir == 'R'
        return @inbounds point[1], point[2]+1:point[2]+len
    elseif dir == 'U'
        return @inbounds point[1]-len:point[1]-1, point[2]
    elseif dir == 'D'
        return @inbounds point[1]+1:point[1]+len, point[2]
    end
end

min(a::UnitRange{Int}, b::Int) = a.start < b ? a.start : b
min(a::Int, b::UnitRange{Int}) = b.start < a ? b.start : a
max(a::UnitRange{Int}, b::Int) = a.stop > b ? a.stop : b
max(a::Int, b::UnitRange{Int}) = b.stop > a ? b.stop : a

function build_grid()
    # enough, does not eat so much ram, and working with sparse matrices is slower
    grid = zeros(Int8, 30000, 30000)
    min_x = size(grid)[1]
    min_y = size(grid)[2]
    max_x = 0
    max_y = 0
    # grid = zeros(Int8, 500, 500)
    # grid = zeros(Int8, 20, 20)
    start = CartesianIndex(size(grid) .÷ 2)
    grid[start] += 1
    # using coprimes to identify crossing
    dir = dirs1[1]
    len = lens1[1]
    for (dirs, lens, num) in [(dirs1, lens1, 2), (dirs2, lens2, 3)]
        point = start
        for (dir, len) in zip(dirs, lens)
            point_to = move(dir, len, point)
            a_range = get_range(dir, len, point)
            min_x = min(min_x, a_range[1])
            min_y = min(min_y, a_range[2])
            max_x = max(max_x, a_range[1])
            max_y = max(max_y, a_range[2])
            grid[a_range...] .+= num
            point = point_to
        end
    end
    grid, start, min_x, min_y, max_x, max_y
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

function part1()
    grid, start, min_x, min_y, max_x, max_y = build_grid()
    adjust_i(x) = x + CartesianIndex(min_x-1, min_y-1) - start
    isfive = x->x==5
    findall(isfive, grid[min_x:max_x, min_y:max_y]) .|> (x->x |> adjust_i |> Tuple |> norm1) |> minimum |> Int
end

function part2()
    grid, start, min_x, min_y, max_x, max_y = build_grid()
    adjust_i(x) = x + CartesianIndex(min_x-1, min_y-1)
    junctions = findall(x->x == 5, grid[min_x:max_x, min_y:max_y]) .|> adjust_i
    # rolling wires in time
    seg1 = seg2 = 1   # segments in lines
    idx1 = idx2 = 0   # number in segment
    coord1 = CartesianIndex(start)
    coord2 = CartesianIndex(start)
    min_len = min(sum(lens1), sum(lens2))
    # for each junction, I will save its time for each line
    junction_times = zeros(Int64, length(junctions), 2)
    @inbounds for t in 1:min_len
        if idx1 == lens1[seg1]
            seg1 += 1
            idx1 = 0
        end
        if idx2 == lens2[seg2]
            seg2 += 1
            idx2 = 0
        end
        idx1 += 1
        idx2 += 1
        @inbounds coord1 = move(dirs1[seg1], 1, coord1)
        @inbounds coord2 = move(dirs2[seg2], 1, coord2)

        if coord1 ∈ junctions
            junction_times[findfirst(map(x->x==coord1, junctions)), 1] = t
        end
        if coord2 ∈ junctions
            junction_times[findfirst(map(x->x==coord2, junctions)), 2] = t
        end
    end
    sum(junction_times, dims=2) |> minimum
end

using BenchmarkTools

println(part1())
@btime part1() # orig  1.218 s (12659 allocations: 859.01 MiB)
#submit(part1(), cur_day, 1)
println(part2())
@btime part2() # orig  1.291 s (1051536 allocations: 881.73 MiB)
#submit(part2(), cur_day, 2)
