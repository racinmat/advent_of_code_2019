using DrWatson
quickactivate(@__DIR__)
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->replace(x, "."=>"0") |> x->replace(x, "#"=>"1") |> x->split(x, '\n') .|> collect .|>
    (x->parse.(Int, x)) |> x->hcat(x...) |> x->Array(x')
data = cur_day |> test_input |> x->replace(x, "."=>"0") |> x->replace(x, "#"=>"1") |> x->split(x, '\n') .|> collect .|>
    (x->parse.(Int, x)) |> x->hcat(x...) |> x->Array(x')

function next_gen(grid::Array{Int, 2})::Array{Int, 2}
    new_grid = copy(grid)
    neighbors = [CartesianIndex(-1, 0), CartesianIndex(0, -1), CartesianIndex(1, 0), CartesianIndex(0, 1)]
    for i in CartesianIndices(grid)
        neighbor_sum = sum(grid[i+n] for n in neighbors if all(1 .<= Tuple(i+n) .<= size(grid)))
        if grid[i] == 1
            new_grid[i] = neighbor_sum == 1 ? 1 : 0
        else
            new_grid[i] = 1 <= neighbor_sum <= 2 ? 1 : 0
        end
    end
    new_grid
end

function grid_repr(grid)
    sum(2^(i-1)*j for (i, j) in enumerate(reshape(grid', (1, length(grid)))))
end

function part1()
    grid = copy(data)
    reprs = Set{Int}()
    repr = grid_repr(grid)
    while repr ∉ reprs
        push!(reprs, repr)
        grid = next_gen(grid)
        repr = grid_repr(grid)
    end
    repr
end

function part2()
    data
end

using BenchmarkTools

println(part1())
@btime part1()
submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
