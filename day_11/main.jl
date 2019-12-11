using DrWatson
quickactivate(@__DIR__)
using Images
include(projectdir("misc.jl"))
include(projectdir("interpret.jl"))

abstract type Direction end
struct Up <: Direction end
struct Down <: Direction end
struct Left <: Direction end
struct Right <: Direction end

rot_left(dir::Type{Up}) = Left
rot_left(dir::Type{Down}) = Right
rot_left(dir::Type{Left}) = Down
rot_left(dir::Type{Right}) = Up

rot_right(dir::Type{Up}) = Right
rot_right(dir::Type{Down}) = Left
rot_right(dir::Type{Left}) = Up
rot_right(dir::Type{Right}) = Down

rot(dir, i) = i == 0 ? rot_left(dir) : rot_right(dir)

move(i, dir::Type{Up}) = i + CartesianIndex(-1, 0)
move(i, dir::Type{Down}) = i + CartesianIndex(1, 0)
move(i, dir::Type{Left}) = i + CartesianIndex(0, -1)
move(i, dir::Type{Right}) = i + CartesianIndex(0, 1)

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->read_numbers(x, ',')

function part1()
    visited = Set{CartesianIndex}()
    grid = zeros(Int, 10000, 10000)
    point = CartesianIndex(size(grid) .÷ 2)
    direction = Up
    channel_in = Channel(Inf)
    channel_out = Channel(Inf)
    program = @async run_program!(copy(data), channel_in, channel_out)
    push!(visited, point)
    while true
        put!(channel_in, grid[point])
        if istaskdone(program)
            break
        end
        color = take!(channel_out)
        grid[point] = color
        rotation = take!(channel_out)
        direction = rot(direction, rotation)
        point = move(point, direction)
        push!(visited, point)
    end
    length(visited)
end

function part2()
    visited = Set{CartesianIndex}()
    grid = zeros(Int, 500, 500)
    point = CartesianIndex(size(grid) .÷ 2)
    grid[point] = 1
    direction = Up
    channel_in = Channel(Inf)
    channel_out = Channel(Inf)
    program = @async run_program!(copy(data), channel_in, channel_out)
    push!(visited, point)
    while true
        put!(channel_in, grid[point])
        if istaskdone(program)
            break
        end
        color = take!(channel_out)
        grid[point] = color
        rotation = take!(channel_out)
        direction = rot(direction, rotation)
        point = move(point, direction)
        push!(visited, point)
    end
    save("day-10-img.png", colorview(Gray, convert.(Float64, grid)))
end

println(part1())
# submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
