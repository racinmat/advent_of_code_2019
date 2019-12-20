using DrWatson
quickactivate(@__DIR__)
using LightGraphs, Combinatorics, TimerOutputs, MetaGraphs
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
# data = cur_day |> read_input |> x->split(x, '\n') .|> collect |>
#     x->hcat(x...) |> x->permutedims(x, [2, 1])
data = cur_day |> test_input |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |>
    x->hcat(x...) |> x->permutedims(x, [2, 1])

function build_graph(data)
    g = LightGraphs.SimpleGraphs.grid(data |> size |> collect)
    g = MetaGraph(g)
    start_node = 0
    key2node = Dict{Char, Int}()
    door2node = Dict{Char, Int}()
    door2neighbors = Dict{Char, Vector{Int}}()
    for (i, j) in enumerate(CartesianIndices(data))
        set_prop!(g, i, :coords, j)
    end

    for vertex in nv(g):-1:1
        coords = get_prop(g, vertex, :coords)
        if data[coords] == '#'
            rem_vertex!(g, vertex)
        end
    end

    for vertex in vertices(g)
        coords = get_prop(g, vertex, :coords)
        if data[coords] == '@'
            start_node = vertex
        elseif Int('a') <= Int(data[coords]) <= Int('z')
            key2node[data[coords]] = vertex
        elseif Int('A') <= Int(data[coords]) <= Int('Z')
            door2node[data[coords]] = vertex
        end
    end
    # need to remap vertices, theirs numbering is changed after removal

    for (letter, node) in door2node
        neighbors_list = neighbors(g, node) |> collect
        door2neighbors[letter] = neighbors_list
        for n in neighbors_list
            rem_edge!(g, node, n)
        end
    end

    g.graph, key2node, door2node, door2neighbors, start_node
end

DistCache = Dict{Set{Char}, Array{Int, 2}}
SolCache = Dict{Tuple{Int, Set{Char}}, Int} # cache of shortest paths to goal from (cur_position, have_keys)

node2coords = Dict(i => Tuple(j) for (i, j) in enumerate(CartesianIndices(data)))
coords2node = Dict(Tuple(j) => i for (i, j) in enumerate(CartesianIndices(data)))

struct TooLongPathException <: Exception end

function shortest_paths(g::AbstractGraph, dist_cache::DistCache, have_keys)
    if !haskey(dist_cache, have_keys)
        states = floyd_warshall_shortest_paths(g)
        dist_cache[copy(have_keys)] = copy(states.dists)
    end
    dist_cache[have_keys]
    # @timeit to "floyd_warshall" states = floyd_warshall_shortest_paths(g)
    # states.dists
end

function get_avail_keys(g::AbstractGraph, cur_pos, key2node, dist_cache::DistCache, have_keyse)
    dists = shortest_paths(g, dist_cache, have_keys)
    get_avail_keys(dists, cur_pos, key2node)
end

function get_avail_keys(dists::Array{Int, 2}, cur_pos, key2node)
    dist_from_node = dists[cur_pos, :]
    let2dist = Dict(letter=>dist_from_node[node] for (letter, node) in key2node if dist_from_node[node] < typemax(Int))
    let2dist
end

function take_key!(g, key2node, door2neighbors, door2node, have_keys, next_key, dists::Array{Int, 2}, cur_node, taken_order::Vector{Char})
    next_node = key2node[next_key]
    push!(have_keys, next_key)
    push!(taken_order, next_key)
    # I have gathered key, adding edges for its doors
    next_door = uppercase(next_key)
    if haskey(door2neighbors, next_door)   # for the last key there is no door
        # adding edges
        for neighbor in door2neighbors[next_door]
            add_edge!(g, door2node[next_door], neighbor)
        end
        delete!(door2node, next_door)
    end
    # removing from key2node so I keep only remaining ones
    delete!(key2node, next_key)

    # draw_grid(g, key2node, door2node, cur_node)

    dist_traveled = dists[cur_node, next_node]
    # println("keys gathered: $have_keys")
    # println("travelling from $cur_node to $next_node: $dist_traveled")
    dist_traveled, next_node
end

# looking at the problem as branch and bounds ~or sth like this
function solve_branches(g, start_node, key2node, door2neighbors, door2node, have_keys::Set{Char}, dist_cache::DistCache, sol_cache::SolCache, path_ub::Int, taken_order::Vector{Char}, path_so_far::Int, avail_keys)
    println("path_ub: $path_ub for solve_branches with keys: $(taken_order |> join)")
    g = copy(g)
    key2node = copy(key2node)
    door2node = copy(door2node)
    have_keys = copy(have_keys)
    taken_order = copy(taken_order)
    best_dist = path_ub
    best_start_key = nothing
    # trying all possible keys to start with
    for key_to_start in avail_keys
        try
            dist_travelled = solve_branch(g, start_node, key2node, door2neighbors, door2node, key_to_start, have_keys, dist_cache, sol_cache, best_dist, taken_order, path_so_far)
            if dist_travelled < best_dist
                best_dist = dist_travelled
                best_start_key = key_to_start
                println("path_ub: $best_dist for solve_branches with keys: $(taken_order |> join)")
            end
        catch err
            if err isa TooLongPathException
                # println("too bad solution cutoff")
                continue
            else
                throw(err)
            end
        end
    end
    best_dist > path_ub && return typemax(Int)
    best_dist
end

solve_branch(g, start_node, key2node, door2neighbors, door2node) = solve_branch(g, start_node, key2node, door2neighbors, door2node, Set{Char}(), DistCache(), SolCache(), typemax(Int), Vector{Char}(), 0)

function solve_branch(g, start_node, key2node, door2neighbors, door2node, have_keys::Set{Char}, dist_cache::DistCache, sol_cache::SolCache, path_ub::Int, taken_order::Vector{Char}, path_so_far::Int)
    # println("path_ub: $path_ub with keys: $have_keys")
    cache_key = (start_node, have_keys)
    if haskey(sol_cache, cache_key)
        total_dist = sol_cache[cache_key]
        println("total_dist to $(taken_order |> join): $(total_dist + path_so_far)")
        return total_dist
    end

    # println("solving branch: keys: $have_keys, start: $start_node, num_edges: $(ne(g))")
    g = copy(g)
    key2node = copy(key2node)
    door2node = copy(door2node)
    orig_taken_order = copy(taken_order)
    have_keys = copy(have_keys)
    taken_order = copy(taken_order)
    total_dist = 0
    cur_node = start_node

    # looking which keys I can gather
    dists = shortest_paths(g, dist_cache, have_keys)
    avail_keys = get_avail_keys(dists, start_node, key2node)
    while !isempty(key2node) && length(avail_keys) == 1
        # total_dist > path_ub && return typemax(Int)
        # total_dist > path_ub && throw(TooLongPathException())
        # only 1 key available
        next_key = avail_keys |> keys |> first
        dist_travelled, cur_node = take_key!(g, key2node, door2neighbors, door2node, have_keys, next_key, dists, cur_node, taken_order)
        total_dist += dist_travelled

        # println("solving branch: keys: $have_keys, start: $cur_node, num_edges: $(ne(g))")
        dists = shortest_paths(g, dist_cache, have_keys)
        avail_keys = get_avail_keys(dists, cur_node, key2node)
    end

    if !isempty(key2node) && length(avail_keys) > 1
        # println("multiple keys available")
        # println(avail_keys)
        total_dist += solve_branches(g, cur_node, key2node, door2neighbors, door2node, have_keys, dist_cache, sol_cache, path_ub, taken_order, total_dist + path_so_far, avail_keys |> keys)
        # total_dist > path_ub && return typemax(Int)
        # total_dist > path_ub && throw(TooLongPathException())
    end
    sol_cache[cache_key] = total_dist
    println("total_dist from $(orig_taken_order |> join) to $(taken_order |> join): $total_dist")
    println("total_dist to $(taken_order |> join): $(total_dist + path_so_far)")
    total_dist
end

function solve_branch(g, start_node, key2node, door2neighbors, door2node, key_to_pick, have_keys::Set{Char}, dist_cache::DistCache, sol_cache::SolCache, path_ub::Int, taken_order::Vector{Char}, path_so_far::Int)
    # println("path_ub: $path_ub with keys: $have_keys and key_to_pick: $key_to_pick")
    g = copy(g)
    key2node = copy(key2node)
    door2node = copy(door2node)
    have_keys = copy(have_keys)
    taken_order = copy(taken_order)
    total_dist = 0
    dists = shortest_paths(g, dist_cache, have_keys)
    dist_travelled, cur_node = take_key!(g, key2node, door2neighbors, door2node, have_keys, key_to_pick, dists, start_node, taken_order)
    total_dist += dist_travelled
    # total_dist > path_ub && return typemax(Int)
    # total_dist > path_ub && throw(TooLongPathException())
    # println("dist from $start_node to $cur_node: $total_dist")
    # todo: check that this is working pruning
    total_dist += solve_branch(g, cur_node, key2node, door2neighbors, door2node, have_keys, dist_cache, sol_cache, path_ub, taken_order, total_dist + path_so_far)
    # total_dist > path_ub && return typemax(Int)
    # total_dist > path_ub && throw(TooLongPathException())
    # println("dist from $start_node to end: $total_dist")
    # println("total_dist: $total_dist with keys: $have_keys")
    total_dist
end

function draw_grid(g, key2node, door2node, cur_node)
    data_to_print = copy(data)
    for (i, j) in enumerate(CartesianIndices(data))
        if i ∈ values(key2node)
            for (letter, node) in key2node
                if i == node
                    data_to_print[j] = letter
                end
            end
        elseif i ∈ values(door2node)
            for (letter, node) in door2node
                if i == node
                    data_to_print[j] = letter
                end
            end
        elseif i == cur_node
            data_to_print[j] = '@'
        elseif degree(g, i) == 0
            data_to_print[j] = '#'
        elseif degree(g, i) > 0
            data_to_print[j] = '.'
        end
    end
    for i in 1:size(data_to_print)[1]
        println(join(data_to_print[i, :]))
    end
    println()
end

function part1()
    g, key2node, door2node, door2neighbors, start_node = build_graph(data)
    solve_branch(g, start_node, key2node, door2neighbors, door2node)
    # display(to)
end

using BenchmarkTools
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)
@time solve_branch(g, start_node, key2node, door2neighbors, door2node)

#testing
data = read_file(cur_day, "test_input_81.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_node = build_graph(data)
solve_branch(g, start_node, key2node, door2neighbors, door2node) == 81

data = read_file(cur_day, "test_input_132.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_node = build_graph(data)
solve_branch(g, start_node, key2node, door2neighbors, door2node) == 132

data = read_file(cur_day, "test_input_136.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_node = build_graph(data)
solve_branch(g, start_node, key2node, door2neighbors, door2node) == 136

# g, key2node, door2node, door2neighbors, start_node = build_graph(data)
#
# have_keys = Set{Char}()
# # looking which keys I can gather
# states = floyd_warshall_shortest_paths(g)
# avail_keys = get_avail_keys(states, start_node, key2node)
#
# # only 1 key available
# length(avail_keys) == 1
# @assert length(avail_keys) == 1
# next_key = avail_keys |> keys |> first
# dist_travelled = take_key!(g, key2node, next_key, states, cur_node)
#
# # searching for next keys
# states = floyd_warshall_shortest_paths(g)
# avail_keys = get_avail_keys(states, start_node, key2node)

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
# submit(part1(), cur_day, 1)
println(part2())
# submit(part2(), cur_day, 2)
