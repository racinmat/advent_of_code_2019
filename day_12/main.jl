using DrWatson
quickactivate(@__DIR__)
using Combinatorics, StaticArrays
using Base.Iterators: flatten
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])

function parse_row(str)
    m = match(r"<x=(-?[0-9]+), y=(-?[0-9]+), z=(-?[0-9]+)>", str)
    Vector(parse.(Int, [m[1], m[2], m[3]]))
end

const data = cur_day |> read_input |> x->split(x, '\n') .|> parse_row
# const data = cur_day |> test_input |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> parse_row

function iteration!(positions, velocities, combs)
    @simd for i in 1:length(combs)
        idx1, idx2 = combs[i]
        @inbounds velocities[idx1, :] += sign.(positions[idx2, :] - positions[idx1, :])
        @inbounds velocities[idx2, :] += sign.(positions[idx1, :] - positions[idx2, :])
    end
    positions .+= velocities
end

function part1()
    positions = MMatrix{4, 3}(copy(hcat(data...)'))
    velocities = MMatrix{4, 3}(zeros(Int, size(positions)))
    combs = combinations(1:size(positions)[1], 2) |> collect
    for i in 1:1000
        iteration!(positions, velocities, combs)
    end
    sum(sum(abs.(positions), dims=2) .* sum(abs.(velocities), dims=2))
end

function part2()
    data
end

using BenchmarkTools

println(part1())
@btime part1()
# submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
