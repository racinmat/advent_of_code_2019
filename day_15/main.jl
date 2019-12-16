using DrWatson
quickactivate(@__DIR__)
using DataStructures
using Base.Iterators: flatten
include(projectdir("misc.jl"))
include(projectdir("interpret.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->read_numbers(x, ',')

abstract type Direction end
struct Up <: Direction end
struct Down <: Direction end
struct Left <: Direction end
struct Right <: Direction end

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

function get_direction(from::CartesianIndex, to::CartesianIndex)
    for direction in directions
        if move(from, direction) == to
            return direction
        end
    end
    throw("no direction found")
end

is_neighbor(i::CartesianIndex, j::CartesianIndex) = (k = i - j; (k[1] == 0 && abs(k[2]) == 1) || (k[2] == 0 && abs(k[1]) == 1))

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

function explore_neighbours!(channel_in, channel_out, grid, open_nodes, visited, preceder, point)
    for direction in directions
        new_point = try_move!(channel_in, channel_out, grid, direction, point)
        if new_point != point
            try_move!(channel_in, channel_out, grid, opposite(direction), new_point)
            if new_point ∉ visited
                push!(open_nodes, new_point)
                preceder[new_point] = point
            end
        end
    end
end

function go_to_point!(channel_in, channel_out, grid, preceder, cur_point, goal_point)
    while cur_point != goal_point
        next_point = preceder[cur_point]
        direction = get_direction(cur_point, next_point)
        cur_point = try_move!(channel_in, channel_out, grid, direction, cur_point)
    end
end

function part1()
    channel_in = Channel(1)
    channel_out = Channel(Inf)
    arr = copy(data)
    visited = Set{CartesianIndex}()
    # -1 is undiscovered
    grid = ones(Int, 100, 100) .* -1
    start_point = CartesianIndex(size(grid) .÷ 2)
    cur_point = start_point
    grid[cur_point] = 1
    open_nodes = Stack{CartesianIndex}()
    push!(open_nodes, cur_point)
    program = @async run_program!(arr, channel_in, channel_out)
    num_steps = 0
    successor = Dict{CartesianIndex, CartesianIndex}()
    preceder = Dict{CartesianIndex, CartesianIndex}()
    while !isempty(open_nodes) && sum(grid .== 2) == 0
        new_point = pop!(open_nodes)
        push!(visited, new_point)
        if is_neighbor(new_point, cur_point)
            direction = get_direction(cur_point, new_point)
            tmp_point = try_move!(channel_in, channel_out, grid, direction, cur_point)
            successor[cur_point] = tmp_point
            preceder[tmp_point] = cur_point
            cur_point = tmp_point
        elseif new_point == cur_point
            nothing
        else
            go_to_point!(channel_in, channel_out, grid, preceder, cur_point, preceder[new_point])
            cur_point = preceder[new_point]
            direction = get_direction(cur_point, new_point)
            tmp_point = try_move!(channel_in, channel_out, grid, direction, cur_point)
            successor[cur_point] = tmp_point
            preceder[tmp_point] = cur_point
            cur_point = tmp_point
        end
        explore_neighbours!(channel_in, channel_out, grid, open_nodes, visited, preceder, new_point)
        num_steps += 1
    end

    # calculating path length
    backtrack_point = cur_point
    path_length = 1
    while backtrack_point != start_point
        path_length += 1
        backtrack_point = preceder[backtrack_point]
    end

    path_length
end

function build_map()
    # building map
    channel_in = Channel(1)
    channel_out = Channel(Inf)
    arr = copy(data)
    visited = Set{CartesianIndex}()
    # -1 is undiscovered
    grid = ones(Int, 100, 100) .* -1
    start_point = CartesianIndex(size(grid) .÷ 2)
    cur_point = start_point
    grid[cur_point] = 1
    open_nodes = Stack{CartesianIndex}()
    push!(open_nodes, cur_point)
    program = @async run_program!(arr, channel_in, channel_out)
    num_steps = 0
    successor = Dict{CartesianIndex, CartesianIndex}()
    preceder = Dict{CartesianIndex, CartesianIndex}()
    while !isempty(open_nodes)
        new_point = pop!(open_nodes)
        push!(visited, new_point)
        if is_neighbor(new_point, cur_point)
            direction = get_direction(cur_point, new_point)
            tmp_point = try_move!(channel_in, channel_out, grid, direction, cur_point)
            successor[cur_point] = tmp_point
            preceder[tmp_point] = cur_point
            cur_point = tmp_point
        elseif new_point == cur_point
            nothing
        else
            go_to_point!(channel_in, channel_out, grid, preceder, cur_point, preceder[new_point])
            cur_point = preceder[new_point]
            direction = get_direction(cur_point, new_point)
            tmp_point = try_move!(channel_in, channel_out, grid, direction, cur_point)
            successor[cur_point] = tmp_point
            preceder[tmp_point] = cur_point
            cur_point = tmp_point
        end
        explore_neighbours!(channel_in, channel_out, grid, open_nodes, visited, preceder, new_point)
        num_steps += 1
    end
    grid
end

get_neighbors(grid, point) = [move(point, direction) for direction in directions if grid[move(point, direction)] == 1]

function part2()
    grid = build_map()
    oxygen_set = Set{CartesianIndex}()
    open_nodes = Stack{Vector{CartesianIndex}}()
    init_oxygen = findfirst(x->x==2, grid)
    push!(oxygen_set, init_oxygen)
    push!(open_nodes, [init_oxygen])
    i = 0
    while !isempty(open_nodes)
        cur_layer = pop!(open_nodes)
        new_layer = cur_layer .|> (x->get_neighbors(grid, x)) |> flatten |> unique
        isempty(new_layer) && break
        grid[new_layer] .= 2
        push!(open_nodes, new_layer)
        i += 1
    end
    i
end

using BenchmarkTools

println(part1())
@btime part1()
# submit(part1(), cur_day, 1)
println(part2())
@btime part2()
# submit(part2(), cur_day, 2)
