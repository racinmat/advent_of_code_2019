using DrWatson
quickactivate(@__DIR__)
using LightGraphs, Combinatorics, TimerOutputs, MetaGraphs, Logging, DataStructures, SimpleWeightedGraphs, Dates
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->split(x, '\n') .|> collect |>
    x->hcat(x...) |> x->permutedims(x, [2, 1])
# data = cur_day |> test_input |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |>
#     x->hcat(x...) |> x->permutedims(x, [2, 1])

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

    start_nodes = Vector{Int}()
    for vertex in vertices(g)
        coords = get_prop(g, vertex, :coords)
        if data[coords] == '@'
            push!(start_nodes, vertex)
        elseif Int('a') <= Int(data[coords]) <= Int('z')
            key2node[data[coords]] = vertex
        elseif Int('A') <= Int(data[coords]) <= Int('Z')
            door2node[data[coords]] = vertex
        end
    end
    # need to remap vertices, theirs numbering is changed after removal
    full_graph = copy(g.graph)

    for (letter, node) in door2node
        neighbors_list = neighbors(g, node) |> collect
        door2neighbors[letter] = neighbors_list
        for n in neighbors_list
            rem_edge!(g, node, n)
        end
    end

    g.graph, key2node, door2node, door2neighbors, start_nodes, g.vprops, full_graph
end

# DistCache = Dict{Set{Char}, Array{Int, 2}}
DistCache = Dict{Tuple{Set{Char}, Int}, Vector{Int}}
HeurCache = Dict{Vector{Int}, Int}
GraphCache = Dict{Set{Char}, AbstractGraph}
SolCache = Dict{Tuple{Int, Set{Char}}, Int} # cache of shortest paths to goal from (cur_position, have_keys)
Dists = Array{Int, 2}

struct Node
    taken_keys::Vector{Char}
    graph::SimpleGraph
    cur_pos::Int
    dist_so_far::Int
    heur::Int
end

function shortest_paths(node::Node, dist_cache::DistCache)
    @timeit to "shortest_paths cache key" dist_cache_key = (Set(node.taken_keys), node.cur_pos)
    if !haskey(dist_cache, dist_cache_key)
        @timeit to "dijkstra" states = dijkstra_shortest_paths(node.graph, node.cur_pos)
        @timeit to "copy(states.dists)" dist_cache[dist_cache_key] = copy(states.dists)
    end
    dist_cache[dist_cache_key]
end

function get_avail_keys(dists::Vector{Int}, node::Node, key2node)
    cur_pos = node.cur_pos
    let2dist = Dict(letter=>dists[node] for (letter, node) in key2node if dists[node] < typemax(Int))
    let2dist
end

function build_neighbor(node::Node, next_key::Char, dist_traveled, key2node, door2neighbors, door2node, graph_cache,
        full_dists, heur_cache)
    next_pos = key2node[next_key]
    @timeit to "copy(node.taken_keys)" next_taken_keys = copy(node.taken_keys)
    # copying graph is costly, both time and memory-wise
    push!(next_taken_keys, next_key)
    cache_key = Set(next_taken_keys)
    if !haskey(graph_cache, cache_key)
        @timeit to "copy(node.graph)" next_graph = copy(node.graph)
        @timeit to "uppercase(next_key))" next_door = uppercase(next_key)
        @timeit to "modifying graph" if haskey(door2neighbors, next_door)   # for the last key there is no door
            for neighbor in door2neighbors[next_door]
                add_edge!(next_graph, door2node[next_door], neighbor)
            end
        end
        graph_cache[cache_key] = next_graph
    end
    next_graph = graph_cache[cache_key]
    @timeit to "calc_heuristic" h_val = heuristic!(next_taken_keys, next_pos, key2node, full_dists, heur_cache)
    Node(next_taken_keys, next_graph, next_pos, node.dist_so_far + dist_traveled, min(h_val, node.heur))
end

# based on sum of distances to nearest neighbour of each node
# function heuristic!(taken_keys, cur_pos, key2node, full_dists, heur_cache)
# # todo: try out if sorting kaes sense, seems like takes lots of time?
#     @timeit to "nodes_to_go" nodes_to_go = [j for (i, j) in key2node if i ∉ taken_keys]
#     isempty(nodes_to_go) && return 0
#     @timeit to "push! nodes_to_go" push!(nodes_to_go, cur_pos)
#     if !haskey(heur_cache, nodes_to_go)
#         @timeit to "obtain key_dists" keys_dists = full_dists[nodes_to_go, nodes_to_go]
#         @timeit to "find min_rows sum" min_rows_sum = minimum(keys_dists, dims=1) |> sum
#         heur_cache[nodes_to_go] = min_rows_sum
#     end
#     heur_cache[nodes_to_go]
# end

# based on minimal spanning tree
function heuristic!(taken_keys, cur_pos, key2node, full_dists, heur_cache)
# todo: try out if sorting kaes sense, seems like takes lots of time?
    @timeit to "nodes_to_go" nodes_to_go = [j for (i, j) in key2node if i ∉ taken_keys]
    isempty(nodes_to_go) && return 0
    @timeit to "push! nodes_to_go" push!(nodes_to_go, cur_pos)
    if !haskey(heur_cache, nodes_to_go)
        @timeit to "obtain key_dists" keys_dists = full_dists[nodes_to_go, nodes_to_go]
        @timeit to "kruskal mst sum" mst_sum = kruskal_mst(SimpleWeightedGraph(keys_dists)) .|> (x->x.weight) |> sum
        heur_cache[nodes_to_go] = mst_sum
    end
    heur_cache[nodes_to_go]
end

function make_neighbor_repr(node::Node, letter, dist, key2node)
    next_pos = key2node[letter]
    next_taken_keys = copy(node.taken_keys)
    push!(next_taken_keys, letter)
    next_pos, Set(next_taken_keys), node.dist_so_far + dist
end

function get_neighbors(node::Node, dist_cache, graph_cache, key2node, door2neighbors, door2node, full_dists, heur_cache, open_configs)
    @timeit to "shortest_paths" dists = shortest_paths(node, dist_cache)
    @timeit to "get_avail_keys" avail_keys = get_avail_keys(dists, node, filter(x->x[1] ∉ node.taken_keys, key2node))
    @timeit to "neighbor_repr" neighbor_reprs = Dict(letter=>make_neighbor_repr(node, letter, dist, key2node) for (letter, dist) in avail_keys)
    @timeit to "build_neighbor arr" neighbors = [
        (dist, build_neighbor(node, letter, dist, key2node, door2neighbors, door2node, graph_cache, full_dists, heur_cache))
        for (letter, dist) in avail_keys if neighbor_reprs[letter] ∉ open_configs]
    for (letter, neighbor_repr) in neighbor_reprs
        if neighbor_repr ∉ open_configs
            push!(open_configs, neighbor_repr)
        end
    end
    neighbors
end

function astar(g, start_pos, key2node, door2neighbors, door2node, full_graph)
    # from the tree-like structure of greaph being searched, I don't need closed list
    dist_cache = DistCache()
    sol_cache = SolCache()
    heur_cache = HeurCache()
    graph_cache = GraphCache()
    open_nodes = PriorityQueue{Node, Int}()
    open_configs = Set{Tuple{Int, Set{Char}, Int}}()  # set of tuples (position, set of taken keys, dist)
    start_node = Node([], copy(g), start_pos, 0, typemax(Int) ÷ 10)
    full_dists = floyd_warshall_shortest_paths(full_graph).dists
    # maximum dist with some multiplicative margin
    max_val = maximum([i for i in full_dists if i < typemax(Int)])
    max_size = 0
    for i in 1:size(full_dists)[1]
        full_dists[i, i] = max_val * 100
    end
    target_len = length(key2node)
    enqueue!(open_nodes, start_node, 1)
    while !isempty(open_nodes)
        @timeit to "dequeue" cur_node = dequeue!(open_nodes)
        cur_node_len = length(cur_node.taken_keys)
        @debug "dequeued node: $(cur_node.taken_keys |> join) with dist_so_far: $(cur_node.dist_so_far |> join)"
        if cur_node_len == target_len
            return cur_node.dist_so_far
        end
        if cur_node_len > max_size
            verbose && println("$(Dates.now()): max solution len: $cur_node_len")
            max_size = cur_node_len
        end
        @timeit to "get_neighbors" node_neighbors = get_neighbors(cur_node, dist_cache, graph_cache, key2node,
            door2neighbors, door2node, full_dists, heur_cache, open_configs)
        for (dist, neighbor) in node_neighbors
            f = neighbor.dist_so_far + neighbor.heur
            @debug "enqueing node: $(neighbor.taken_keys |> join) with dist_so_far: $(neighbor.dist_so_far |> join) and h: $(neighbor.heur)"
            @timeit to "enqueue" enqueue!(open_nodes, neighbor, f)
        end
    end
end

function simple_fmt(level, _module, group, id, file, line)
    color = Logging.default_logcolor(level)
    prefix = (level == Logging.Warn ? "Warning" : string(level))*':'
    suffix = "line: $line"
    color, prefix, suffix
end

base_stream = global_logger().stream
my_debug_logger = ConsoleLogger(base_stream, Logging.Debug, meta_formatter=simple_fmt, show_limited=true, right_justify=100)
using BenchmarkTools
to = TimerOutput()
verbose = true
verbose = false

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

function part1()
    g, key2node, door2node, door2neighbors, start_pos, vprops, full_graph = build_graph(data)
    astar(g, start_pos, key2node, door2neighbors, door2node, full_graph)
end

function part2()
    start_pos
    g, key2node, door2node, door2neighbors, start_pos, vprops, full_graph = build_graph(data)
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

# 2019-12-25T21:20:37.707: max solution len: 1
# 2019-12-25T21:20:39.68: max solution len: 2
# 2019-12-25T21:20:43.019: max solution len: 3
# 2019-12-25T21:20:48.656: max solution len: 4
# 2019-12-25T21:21:04.174: max solution len: 5
# 2019-12-25T21:21:24.548: max solution len: 6
# 2019-12-25T21:21:53.972: max solution len: 7
# 2019-12-25T21:22:16.234: max solution len: 8
# 2019-12-25T21:22:38.516: max solution len: 9
# 2019-12-25T21:24:41.97: max solution len: 10
# 2019-12-25T21:25:59.464: max solution len: 11
# 2019-12-25T21:26:04.195: max solution len: 12
# 2019-12-25T21:32:55.222: max solution len: 13

println(part1())
# submit(part1(), cur_day, 1)
println(part2())
# submit(part2(), cur_day, 2)
