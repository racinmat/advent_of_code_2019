using DrWatson
quickactivate(@__DIR__)
using LinearAlgebra, SparseArrays, Dates
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = split(read_input(cur_day), '\n') .|> x->split(x, ',')
# data = split("R8,U5,L5,D3\nU7,R6,D4,L4", '\n') .|> x->split(x, ',')
# data = split("R75,D30,R83,U83,L12,D49,R71,U7,L72\nU62,R66,U55,R34,D71,R55,D58,R83", '\n') .|> x->split(x, ',')
# data = split("R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51\nU98,R91,D20,R16,D67,R40,U7,R15,U6,R7", '\n') .|> x->split(x, ',')
line1, line2 = data
dirs1 = map(x->x[1], line1)
lens1 = map(x->parse(Int, x[2:end]), line1)
dirs2 = map(x->x[1], line2)
lens2 = map(x->parse(Int, x[2:end]), line2)

norm1(x) = norm(x, 1)
function move(dir, len, point)
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

function get_range(dir, len, point)
    if dir == 'L'
        return point[1], point[2]-len:point[2]-1
    elseif dir == 'R'
        return point[1], point[2]+1:point[2]+len
    elseif dir == 'U'
        return point[1]-len:point[1]-1, point[2]
    elseif dir == 'D'
        return point[1]+1:point[1]+len, point[2]
    end
end

function build_grid()
    # enough, does not eat so much ram, and working with sparse matrices is slower
    grid = zeros(Int8, 30000, 30000)
    # grid = zeros(Int8, 500, 500)
    # grid = zeros(Int8, 20, 20)
    start = CartesianIndex(size(grid) .÷ 2)
    grid[start] += 1
    # using coprimes to identify crossing
    for (dirs, lens, num) in [(dirs1, lens1, 2), (dirs2, lens2, 3)]
        point = start
        for (dir, len) in zip(dirs, lens)
            point_to = move(dir, len, point)
            grid[get_range(dir, len, point)...] .+= num
            point = point_to
        end
    end
    grid, start
end

function part1()
    grid, start = build_grid()
    sub_start(x) = x - start
    findall(x->x == 5, grid) .|> (x->x |> sub_start |> Tuple |> norm1) |> minimum |> Int
end


function part2()
    grid, start = build_grid()
    sub_start(x) = x - start
    junctions = findall(x->x == 5, grid)
    # rolling wires in time
    seg1 = seg2 = 1   # segments in lines
    idx1 = idx2 = 0   # number in segment
    coord1 = CartesianIndex(start)
    coord2 = CartesianIndex(start)
    min_len = min(sum(lens1), sum(lens2))
    # for each junction, I will save its time for each line
    junction_times = zeros(Int64, length(junctions), 2)
    for t in 1:min_len
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
        coord1 = move(dirs1[seg1], 1, coord1)
        coord2 = move(dirs2[seg2], 1, coord2)

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
#submit(part1(), cur_day, 1)
@btime part1()
println(part2())
#submit(part2(), cur_day, 2)
@btime part2()
