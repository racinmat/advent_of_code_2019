using DrWatson
quickactivate(@__DIR__)
using Combinatorics, StaticArrays
using Base.Iterators: flatten
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])

function parse_row(str)
    m = match(r"<x=(-?[0-9]+), y=(-?[0-9]+), z=(-?[0-9]+)>", str)
    Vector(parse.(Int32, [m[1], m[2], m[3]]))
end

const data = cur_day |> read_input |> x->split(x, '\n') .|> parse_row |> x->hcat(x...)'
# const data = cur_day |> test_input |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> parse_row |> x->hcat(x...)'

function iteration!(positions, velocities, combs)
    @inbounds @simd for i in 1:length(combs)
        idx1, idx2 = combs[i]
        dir = sign.(positions[idx2, :] - positions[idx1, :])
        velocities[idx1, :] += dir
        velocities[idx2, :] -= dir
    end
    positions .+= velocities
end

function part1()
    positions = MMatrix{4, 3, Int32}(copy(data))
    velocities = MMatrix{4, 3, Int32}(zeros(Int32, size(positions)))
    combs = combinations(1:size(positions)[1], 2) |> collect
    for i in 1:1_000
        iteration!(positions, velocities, combs)
    end
    sum(sum(abs.(positions), dims=2) .* sum(abs.(velocities), dims=2))
end

function part2()
    positions = MMatrix{4, 3, Int32}(copy(data))
    velocities = MMatrix{4, 3, Int32}(zeros(Int32, size(positions)))
    combs = combinations(1:size(positions)[1], 2) |> collect
    init_positions = copy(positions)
    # solving individual axes separately
    repeat_indices = MVector{3}([0, 0, 0])
    i = 1
    while any(repeat_indices .== 0)
        iteration!(positions, velocities, combs)
        j = 1
        @inbounds for j in 1:3
            if all(velocities[:, j] .== 0) && all(init_positions[:, j] .== positions[:, j]) && repeat_indices[j] == 0
                repeat_indices[j] = i
            end
        end
        i += 1
    end
    lcm(repeat_indices)
end

using BenchmarkTools
using Traceur

println(part1())
@btime part1()
# submit(part1(), cur_day, 1)
println(part2())
@time part2()
# submit(part2(), cur_day, 2)
