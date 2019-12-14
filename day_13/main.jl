using DrWatson
quickactivate(@__DIR__)
include(projectdir("misc.jl"))
include(projectdir("interpret.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->read_numbers(x, ',')

function part1()
    grid_description = run_program_all_out!(copy(data))
    desc = reshape(grid_description, (3, length(grid_description) ÷ 3))
    x_max = maximum(desc[1, :])
    y_max = maximum(desc[2, :])
    grid = zeros(Int, x_max+1, y_max+1)
    for i in 1:size(desc)[2]
        x_coord, y_coord, grid_type = desc[:, i]
        grid[x_coord+1, y_coord+1] = grid_type
    end
    sum(grid .== 2)
end

function part2()
    data
end

println(part1())
# submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
