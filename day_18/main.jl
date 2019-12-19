using DrWatson
quickactivate(@__DIR__)
using LightGraphs
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
# data = cur_day |> read_input |> x->split(x, '\n') .|> collect |>
#     x->hcat(x...) |> x->permutedims(x, [2, 1])
data = cur_day |> test_input |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |>
    x->hcat(x...) |> x->permutedims(x, [2, 1])

function get_avail_keys(g::SimpleGraph, cur_pos, key2node)
    states = floyd_warshall_shortest_paths(g)
    get_avail_keys(states, cur_pos, key2node)
end

function get_avail_keys(states::LightGraphs.FloydWarshallState, cur_pos, key2node)
    dist_from_node = states.dists[cur_pos, :]
    let2dist = Dict(letter=>dist_from_node[node] for (letter, node) in key2node if dist_from_node[node] < typemax(Int))
    let2dist
end

function build_graph(data)
    g = LightGraphs.SimpleGraphs.grid(data |> size |> collect)
    start_node = 0
    key2node = Dict{Char, Int}()
    door2node = Dict{Char, Int}()
    door2neighbors = Dict{Char, Vector{Int}}()
    for (i, j) in enumerate(CartesianIndices(data))
        if data[j] == '#'
            for n in neighbors(g, i)
                rem_edge!(g, i, n)
            end
        elseif data[j] == '@'
            start_node = i
        elseif Int('a') <= Int(data[j]) <= Int('z')
            key2node[data[j]] = i
        elseif Int('A') <= Int(data[j]) <= Int('Z')
            door2node[data[j]] = i
        end
    end

    for (letter, node) in door2node
        neighbors_list = neighbors(g, node) |> collect
        door2neighbors[letter] = neighbors_list
        for n in neighbors_list
            rem_edge!(g, node, n)
        end
    end

    g, key2node, door2node, door2neighbors, start_node
end

function take_key!(g, avail_keys)
    next_key = avail_keys |> keys |> first
    cur_node = key2node[next_key]
    push!(have_keys, next_key)
    # I have gathered key, adding edges for its doors
    next_door = uppercase(next_key)
    # checking adding edges
    neighbors(g, door2node[next_door])
    for neighbor in door2neighbors[next_door]
        add_edge!(g, door2node[next_door], neighbor)
    end
    neighbors(g, door2node[next_door])
    # removing from key2node so I keep only remaining ones
    delete!(key2node, next_key)
end

function part1()
    g, key2node, door2node, door2neighbors, start_node = build_graph(data)
end

g, key2node, door2node, door2neighbors, start_node = build_graph(data)

have_keys = Set{Char}()
# looking which keys I can gather
states = floyd_warshall_shortest_paths(g)
avail_keys = get_avail_keys(states, start_node, key2node)

# only 1 key available
length(avail_keys) == 1
@assert length(avail_keys) == 1
next_key = avail_keys |> keys |> first
cur_node = key2node[next_key]
push!(have_keys, next_key)
# I have gathered key, adding edges for its doors
next_door = uppercase(next_key)
# checking adding edges
neighbors(g, door2node[next_door])
for neighbor in door2neighbors[next_door]
    add_edge!(g, door2node[next_door], neighbor)
end
neighbors(g, door2node[next_door])
# removing from key2node so I keep only remaining ones
delete!(key2node, next_key)

# searching for next keys
states = floyd_warshall_shortest_paths(g)
avail_keys = get_avail_keys(states, start_node, key2node)

function part2()
    # nodes = data |> flatten |> unique
    # g = Graph(length(nodes))
    # int2name = nodes |> enumerate |> Dict
    # name2int = Dict(v=>k for (k, v) in int2name)
    # for (node1, node2) in data
    #     add_edge!(g, name2int[node1], name2int[node2])
    # end
    # paths = dijkstra_shortest_paths(g, name2int["YOU"])
    # paths.dists[paths.parents[name2int["SAN"]]] - 1
end

println(part1())
submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
