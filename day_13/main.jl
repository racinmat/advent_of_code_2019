using DrWatson
quickactivate(@__DIR__)
include(projectdir("misc.jl"))
include(projectdir("interpret.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->read_numbers(x, ',')

function description_to_grid(grid_description::Vector{Int})
    desc = reshape(grid_description, (3, length(grid_description) ÷ 3))
    x_max = maximum(desc[1, :])
    y_max = maximum(desc[2, :])
    grid = zeros(Int, x_max+1, y_max+1)
    score = 0
    for i in 1:size(desc)[2]
        x_coord, y_coord, grid_type = desc[:, i]
        if x_coord == -1 && y_coord == 0
            score == grid_type
        else
            grid[x_coord+1, y_coord+1] = grid_type
        end
    end
    grid, score
end

function description_to_grid(grid_description::Vector{Int}, grid::Array{Int, 2})
    desc = reshape(grid_description, (3, length(grid_description) ÷ 3))
    score = 0
    for i in 1:size(desc)[2]
        x_coord, y_coord, grid_type = desc[:, i]
        if x_coord == -1 && y_coord == 0
            score = grid_type
        else
            grid[x_coord+1, y_coord+1] = grid_type
        end
    end
    grid, score
end

function part1()
    grid_description = run_program_all_out!(copy(data))
    grid, score = description_to_grid(grid_description)
    sum(grid .== 2)
end

function part2()
    channel_in = Channel(1)
    channel_out = Channel(Inf)
    arr = copy(data)
    arr[1] = 2
    program = @async run_program!(arr, channel_in, channel_out)
    grid_description = Vector{Int}()
    sleep(1e-9)
    while isready(channel_out)
        push!(grid_description, take!(channel_out))
    end

    grid, score = description_to_grid(grid_description)

    while !istaskdone(program)
        ball_x = findfirst(x->x==4, grid)[1]
        desc_x = findfirst(x->x==3, grid)[1]
        direction = sign(ball_x - desc_x)

        put!(channel_in, direction)

        grid_description = Vector{Int}()
        sleep(1e-9)
        while isready(channel_out)
            push!(grid_description, take!(channel_out))
        end
        grid, score = description_to_grid(grid_description, grid)
        # @show grid'
        # display(grid')
        # println(score)
        # println(grid_description)
        # println(sum(grid .== 2))
    end

    score
end

println(part1())
# submit(part1(), cur_day, 1)
println(part2())
# submit(part2(), cur_day, 2)
