using DrWatson
quickactivate(@__DIR__)
include(projectdir("misc.jl"))
include(projectdir("interpret.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->read_numbers(x, ',')

function part1()
    tot_sum = 0
    for x in 0:49
        for y in 0:49
            channel_in = Channel(2)
            channel_out = Channel(1)
            program = @async run_program!(copy(data), channel_in, channel_out)
            put!(channel_in, x)
            put!(channel_in, y)
            cell_type = take!(channel_out)
            tot_sum += cell_type
        end
    end
    tot_sum
end

function minor_diag_indices(diag_start, max_size=typemax(Int))
    [CartesianIndex(diag_start - x + 1, x) for x in 1:diag_start if x <= max_size && (diag_start - x + 1) <= max_size]
end

function major_diag_indices(diag_start, max_size=typemax(Int))
    [CartesianIndex(diag_start + x - 1, x) for x in 1:max_size if 1 <= (diag_start + x - 1) <= max_size && x <= max_size]
end

function line_2x_indices(diag_start, max_size=typemax(Int))
    [CartesianIndex(diag_start + x - 1, x * 2) for x in 1:max_size if 1 <= (diag_start + x - 1) <= max_size && x*2 <= max_size]
end

function part2()
    tot_sum
end

function fill_grid(grid_size)
    # exploration of beam to see how big array should I make
    grid = zeros(Int, grid_size, grid_size)
    tot_sum = 0
    for i in CartesianIndices(grid)
        x, y = Tuple(i)
        if x > y
            continue
        end
        channel_in = Channel(2)
        channel_out = Channel(1)
        program = @async run_program!(copy(data), channel_in, channel_out)
        put!(channel_in, x - 1)
        put!(channel_in, y - 1)
        cell_type = take!(channel_out)
        # tot_sum += cell_type
        grid[x, y] = cell_type
    end
    grid
end

function fill_grid_heur(grid_size)
    # exploration of beam to see how big array should I make
    grid = zeros(Int, grid_size, grid_size)
    tot_sum = 0
    for i in CartesianIndices(grid)
        x, y = Tuple(i)
        if x > y
            grid[x, y] = 2
            continue
        end
        if x < y ÷ 1.5 |> Int
            grid[x, y] = 2
            continue
        end
        channel_in = Channel(2)
        channel_out = Channel(1)
        program = @async run_program!(copy(data), channel_in, channel_out)
        put!(channel_in, x - 1)
        put!(channel_in, y - 1)
        cell_type = take!(channel_out)
        # tot_sum += cell_type
        grid[x, y] = cell_type
    end
    grid
end

@time fill_grid(200)

grid_size = size(grid)[1]
for i in 1:200
    print(sum(grid[minor_diag_indices(i, grid_size)]))
end

major_diag_indices(1, grid_size)
major_diag_indices(10, grid_size)
major_diag_indices(-10, grid_size)
major_diag_indices(-100, grid_size)
major_diag_indices(2, grid_size)
line_2x_indices(2, grid_size)
line_2x_indices(4, grid_size)
line_2x_indices(75, grid_size)

sum(grid[major_diag_indices(2, grid_size)])

sum_2x_line = [sum(grid[line_2x_indices(i, grid_size)]) for i in -grid_size:grid_size]
sum_on_major_diag = [sum(grid[major_diag_indices(i, grid_size)]) for i in -grid_size:grid_size]
findfirst(x->x>0, sum_on_major_diag) - grid_size
findlast(x->x>0, sum_on_major_diag) - grid_size

findfirst(x->x>0, sum_2x_line) - grid_size
findlast(x->x>0, sum_2x_line) - grid_size

maximum(sum_2x_line)
minimum(sum_2x_line)
# max square that fits to the grid
maximum(sum(grid[minor_diag_indices(i, grid_size)]) for i in 1:grid_size)

using Images
save("day-19-img.png", colorview(Gray, convert.(Float64, grid)))

grid_heur = fill_grid_heur(grid_size)
save("day-19-heur-img.png", colorview(Gray, convert.(Float64, grid_heur ./ 2)))

println(part1())
submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
