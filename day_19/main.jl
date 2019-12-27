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

function fill_grid(grid_size, offset=CartesianIndex(0, 0))
    # exploration of beam to see how big array should I make
    grid = zeros(Int, grid_size, grid_size)
    tot_sum = 0
    for i in CartesianIndices(grid)
        x, y = Tuple(i)
        if x > y
            continue
        end
        if x < y ÷ 1.5 |> Int
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

function get_type_for_point(data, x, y)::Int
    channel_in = Channel(2)
    channel_out = Channel(1)
    program = @async run_program!(data, channel_in, channel_out)
    put!(channel_in, x - 1)
    put!(channel_in, y - 1)
    cell_type = take!(channel_out)
    cell_type
end

function sum_minor_diag(data, diag_start)
    tot_sum = 0
    start_idx = (0, 0)
    end_idx = (0, 0)
    prev_cell = 0
    prev_xy = (0, 0)
    for i in minor_diag_indices(diag_start)
        x, y = Tuple(i)
        if x > y
            continue
        end
        if x < y ÷ 1.5 |> Int
            continue
        end
        cell_type = get_type_for_point(data, x, y)
        if tot_sum == 0 && cell_type == 1
            start_idx = x, y
        elseif prev_cell == 1 && cell_type == 0
            end_idx = prev_xy
        end
        tot_sum += cell_type
        prev_cell = cell_type
        prev_xy = x, y
    end
    tot_sum, start_idx, end_idx
end

function part2()
    target_size = 100
    coarse_idxs = collect(Int(round(1.1^i)) for i in 50:90)
    coarse_search_res = [sum_minor_diag(data, i) for i in coarse_idxs]
    coarse_search_sums = [i[1] for i in coarse_search_res]
    to_idx = findfirst(x->x>=target_size, coarse_search_sums)
    from_idx = findlast(x->x<=target_size, coarse_search_sums[1:to_idx+1])

    fine_search_res = [sum_minor_diag(data, i) for i in coarse_idxs[from_idx]:coarse_idxs[to_idx]+1]
    fine_search_sum = [i[1] for i in fine_search_res]
    first_target_idx = findfirst(x->x==target_size, fine_search_sum)
    first_target_sum = first_target_idx + coarse_idxs[from_idx] - 1
    res_point1 = fine_search_res[first_target_idx][2]
    res_point2 = fine_search_res[first_target_idx][3]
    square_corner_x = min(res_point1[1], res_point2[1])
    square_corner_y = min(res_point1[2], res_point2[2])
    res = (square_corner_x - 1) * 10000 + (square_corner_y - 1)
    res
end

println(part1())
# submit(part1(), cur_day, 1)
println(part2())
# submit(part2(), cur_day, 2)
