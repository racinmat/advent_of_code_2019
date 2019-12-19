using DrWatson
quickactivate(@__DIR__)
include(projectdir("misc.jl"))
include(projectdir("interpret.jl"))

idx_directions = [CartesianIndex(-1, 0), CartesianIndex(1, 0), CartesianIndex(0, -1), CartesianIndex(0, 1)]

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->read_numbers(x, ',')

function part1()
    grid_line = run_program_all_out!(copy(data)) .|> Char
    grid_lines = Vector{Vector{Char}}()

    while length(grid_line) > 1
        line_end = findfirst(x->x=='\n', grid_line)
        push!(grid_lines, grid_line[1:line_end-1])
        global grid_line = grid_line[line_end+1:end]
    end
    grid = hcat(grid_lines...)
    crossings = Vector{CartesianIndex}()
    for i in CartesianIndices(grid[2:end-1, 2:end-1])
        if
        crossing =
        push!(crossings, crossing)
    end
end

function part2()
    data
end

println(part1())
submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
