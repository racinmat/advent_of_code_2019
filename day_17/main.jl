using DrWatson
quickactivate(@__DIR__)
include(projectdir("misc.jl"))
include(projectdir("interpret.jl"))

idx_directions = [
    CartesianIndex(-1, 0),
    CartesianIndex(1, 0),
    CartesianIndex(0, -1),
    CartesianIndex(0, 1),
    CartesianIndex(0, 0)
]

offset = CartesianIndex(1, 1)

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->read_numbers(x, ',')

function build_grid(data)
    grid_line = run_program_all_out!(copy(data)) .|> Char
    grid_lines = Vector{Vector{Char}}()

    while length(grid_line) > 1
        line_end = findfirst(x->x=='\n', grid_line)
        push!(grid_lines, grid_line[1:line_end-1])
        grid_line = grid_line[line_end+1:end]
    end
    hcat(grid_lines...)
end

function part1()
    grid = build_grid(data)
    crossings = Vector{CartesianIndex{2}}()
    for i in CartesianIndices(grid[1:end-2, 1:end-2])
        if all('#' == grid[i + j + offset] for j in idx_directions)
            push!(crossings, i + offset)
        end
    end
    grid[crossings] .= 'O'

    res = 0
    for i in crossings
        res += (i[1] - 1) * (i[2] - 1)
    end
    res
end

function part2()
    data
end

println(part1())
submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
