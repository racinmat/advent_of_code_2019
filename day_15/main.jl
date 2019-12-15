using DrWatson
quickactivate(@__DIR__)
include(projectdir("misc.jl"))
include(projectdir("interpret.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->read_numbers(x, ',')

abstract type Direction end
struct Up <: Direction end
struct Down <: Direction end
struct Left <: Direction end
struct Right <: Direction end

# abstract type CellType end
# struct Wall <: CellType end
# struct Corridor <: CellType end

Int(i::Type{Up}) = 1
Int(i::Type{Down}) = 2
Int(i::Type{Left}) = 3
Int(i::Type{Right}) = 4

move(i, dir::Type{Up}) = i + CartesianIndex(-1, 0)
move(i, dir::Type{Down}) = i + CartesianIndex(1, 0)
move(i, dir::Type{Left}) = i + CartesianIndex(0, -1)
move(i, dir::Type{Right}) = i + CartesianIndex(0, 1)

opposite(i::Type{Up}) = Down
opposite(i::Type{Down}) = Up
opposite(i::Type{Left}) = Right
opposite(i::Type{Right}) = Left

directions = [Up, Down, Left, Right]

function try_move!(channel_in, channel_out, grid, direction, point)
    put!(channel_in, Int(direction))
    cell_type = take!(channel_out)
    grid[move(point, direction)] = cell_type
    if cell_type > 0
        point = move(point, direction)
    end
    point
end

function explore_neighbours!(channel_in, channel_out, grid, borders, point)
    for direction in directions
        new_point = try_move!(channel_in, channel_out, grid, direction, point)
        if new_point != point
            try_move!(channel_in, channel_out, grid, opposite(direction), new_point)
            # push!(borders, new_point)
        end
    end
    # delete!(borders, point)
    point
end

function part1()
    channel_in = Channel(1)
    channel_out = Channel(Inf)
    arr = copy(data)
    # -1 is undiscovered
    # grid = ones(Int, 500, 500) .* -1
    grid = ones(Int, 10, 10) .* -1
    point = CartesianIndex(size(grid) .÷ 2)
    grid[point] = 1
    borders = Set{CartesianIndex}()
    push!(borders, point)
    program = @async run_program!(arr, channel_in, channel_out)
    # todo: rewrite to DFS or BFS search
    explore_neighbours!(channel_in, channel_out, grid, borders, point)
    cell_type = try_move!(channel_in, channel_out, grid, Up)


    istaskdone(program)
end

function part2()
    data
end

println(part1())
submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
