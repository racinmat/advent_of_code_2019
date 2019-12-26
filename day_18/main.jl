using DrWatson
quickactivate(@__DIR__)
using LightGraphs, Combinatorics, TimerOutputs, MetaGraphs, Logging, DataStructures, SimpleWeightedGraphs, Dates
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->split(x, '\n') .|> collect |>
    x->hcat(x...) |> x->permutedims(x, [2, 1])
# data =  read_file(cur_day, "test_input_24.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |>
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
DistData = Tuple{Vector{Int}, Vector{Int}}
DistCache = Dict{Tuple{Set{Char}, Set{Int}}, DistData}
HeurCache = Dict{Vector{Int}, Int}
GraphCache = Dict{Set{Char}, AbstractGraph}
SolCache = Dict{Tuple{Int, Set{Char}}, Int} # cache of shortest paths to goal from (cur_position, have_keys)
Dists = Array{Int, 2}
NodeRepr = Tuple{Set{Int}, Set{Char}, Int}

abstract type Node end

struct SingleNode <: Node
    taken_keys::Vector{Char}
    graph::SimpleGraph
    cur_pos::Int
    dist_so_far::Int
    heur::Int
end

struct MultiNode <: Node
    taken_keys::Vector{Char}
    graph::SimpleGraph
    cur_poses::Vector{Int}
    dist_so_far::Int
    heur::Int
end

function shortest_paths(node::SingleNode, dist_cache::DistCache)
    @timeit to "shortest_paths cache key" dist_cache_key = (Set(node.taken_keys), Set(node.cur_pos))
    if !haskey(dist_cache, dist_cache_key)
        @timeit to "dijkstra" states = dijkstra_shortest_paths(node.graph, node.cur_pos)
        @timeit to "copy(states.dists)" dist_cache[dist_cache_key] = copy(states.dists), ones(Int, size(states.dists))
    end
    dist_cache[dist_cache_key][1]
end

function shortest_paths(node::MultiNode, dist_cache::DistCache)
    dist_cache_key = (Set(node.taken_keys), Set(node.cur_poses))
    if !haskey(dist_cache, dist_cache_key)
        dijkstra_results = hcat([dijkstra_shortest_paths(node.graph, pos).dists for pos in node.cur_poses]...)
        dists = minimum(dijkstra_results, dims=2)[:, 1]
        from_pos = argmin(dijkstra_results, dims=2) .|> (x->x[2]) |> x->x[:, 1]
        dist_cache[dist_cache_key] = (dists, from_pos)
    end
    dist_cache[dist_cache_key]
end

function get_avail_keys(dists::Vector{Int}, node::SingleNode, key2node)
    let2dist = Dict(letter=>dists[node] for (letter, node) in key2node if dists[node] < typemax(Int))
    let2dist
end

function get_avail_keys(dists::DistData, node::MultiNode, key2node)
    let2dist = Dict(letter=>(dists[1][node], dists[2][node]) for (letter, node) in key2node if dists[1][node] < typemax(Int))
    let2dist
end

function build_neighbor(node::SingleNode, next_key::Char, dist_traveled, key2node, door2neighbors, door2node, graph_cache,
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
    SingleNode(next_taken_keys, next_graph, next_pos, node.dist_so_far + dist_traveled, min(h_val, node.heur))
end

function build_neighbor(node::MultiNode, next_key::Char, dist_traveled, from_idx, key2node, door2neighbors, door2node, graph_cache,
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
    next_poses = copy(node.cur_poses)
    next_poses[from_idx] = next_pos
    @timeit to "calc_heuristic" h_val = heuristic!(next_taken_keys, next_pos, key2node, full_dists, heur_cache)
    # todo: here adjust the update of positions and dist by cached dists
    MultiNode(next_taken_keys, next_graph, next_poses, node.dist_so_far + dist_traveled, min(h_val, node.heur))
end

# based on minimal spanning tree
function heuristic!(taken_keys::Vector{Char}, cur_pos::Int, key2node, full_dists, heur_cache)
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

function heuristic!(taken_keys::Vector{Char}, cur_poses::Vector{Int}, key2node, full_dists, heur_cache)
    # figure out good heuristics for multiple starting positions, split to smallet trees based on full_dists could be worth
    0
    # @timeit to "nodes_to_go" nodes_to_go = [j for (i, j) in key2node if i ∉ taken_keys]
    # isempty(nodes_to_go) && return 0
    # @timeit to "push! nodes_to_go" push!(nodes_to_go, cur_pos)
    # if !haskey(heur_cache, nodes_to_go)
    #     @timeit to "obtain key_dists" keys_dists = full_dists[nodes_to_go, nodes_to_go]
    #     @timeit to "kruskal mst sum" mst_sum = kruskal_mst(SimpleWeightedGraph(keys_dists)) .|> (x->x.weight) |> sum
    #     heur_cache[nodes_to_go] = mst_sum
    # end
    # heur_cache[nodes_to_go]
end

function make_neighbor_repr(node::SingleNode, letter, dist, key2node)::NodeRepr
    # todo: rewrite also this to keep multiple positions
    next_pos = key2node[letter]
    next_taken_keys = copy(node.taken_keys)
    push!(next_taken_keys, letter)
    Set(next_pos), Set(next_taken_keys), node.dist_so_far + dist
end

function make_neighbor_repr(node::MultiNode, letter, dist, from_idx, key2node)::NodeRepr
    # todo: rewrite also this to keep multiple positions
    next_pos = key2node[letter]
    next_taken_keys = copy(node.taken_keys)
    push!(next_taken_keys, letter)
    next_poses = copy(node.cur_poses)
    next_poses[from_idx] = next_pos
    Set(next_poses), Set(next_taken_keys), node.dist_so_far + dist
end

function get_neighbors(node::Node, dist_cache, graph_cache, key2node, door2neighbors, door2node, full_dists, heur_cache, open_configs)
    @timeit to "shortest_paths" dists = shortest_paths(node, dist_cache)
    @timeit to "get_avail_keys" avail_keys = get_avail_keys(dists, node, filter(x->x[1] ∉ node.taken_keys, key2node))
    @timeit to "prepare_neighbors" neighbors, neighbor_reprs = prepare_neighbors(node, dists, key2node, open_configs, avail_keys, graph_cache, full_dists, heur_cache)
    for (letter, neighbor_repr) in neighbor_reprs
        if neighbor_repr ∉ open_configs
            push!(open_configs, neighbor_repr)
        end
    end
    neighbors
end

function prepare_neighbors(node::SingleNode, dists::Vector{Int}, key2node, open_configs, avail_keys, graph_cache, full_dists, heur_cache)
    @timeit to "neighbor_repr" neighbor_reprs = Dict(letter=>make_neighbor_repr(node, letter, dist, key2node) for (letter, dist) in avail_keys)
    @timeit to "build_neighbor arr" neighbors = [
        (dist, build_neighbor(node, letter, dist, key2node, door2neighbors, door2node, graph_cache, full_dists, heur_cache))
        for (letter, dist) in avail_keys if neighbor_reprs[letter] ∉ open_configs]
    neighbors, neighbor_reprs
end

function prepare_neighbors(node::MultiNode, dists::Tuple{Vector{Int}, Vector{Int}}, key2node, open_configs, avail_keys, graph_cache, full_dists, heur_cache)
    @timeit to "neighbor_repr" neighbor_reprs = Dict(letter=>make_neighbor_repr(node, letter, dist, from_idx, key2node) for (letter, (dist, from_idx)) in avail_keys)
    @timeit to "build_neighbor arr" neighbors = [
        (dist, build_neighbor(node, letter, dist, from_idx, key2node, door2neighbors, door2node, graph_cache, full_dists, heur_cache))
        for (letter, (dist, from_idx)) in avail_keys if neighbor_reprs[letter] ∉ open_configs]
    neighbors, neighbor_reprs
end

function make_init_node(start_pos::Int)
    SingleNode([], copy(g), start_pos, 0, typemax(Int) ÷ 10)
end

function make_init_node(start_poses::Vector{Int})
    MultiNode([], copy(g), start_poses, 0, typemax(Int) ÷ 10)
end

function astar(g::AbstractGraph, start_poses::Union{Int, Vector{Int}}, key2node, door2neighbors, door2node, full_graph)
    dist_cache = DistCache()
    sol_cache = SolCache()
    heur_cache = HeurCache()
    graph_cache = GraphCache()
    open_nodes = PriorityQueue{Node, Int}()
    open_configs = Set{NodeRepr}()  # set of tuples (position, set of taken keys, dist)
    start_node = make_init_node(start_pos)
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

function part1()
    g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
    astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
end

function part2()
    start_pos = findfirst(x->x=='@', data)
    multi_robot_setting = hcat(['@', '#', '@'], ['#', '#', '#'], ['@', '#', '@'])
    data[start_pos[1]-1:start_pos[1]+1, start_pos[2]-1:start_pos[2]+1] = multi_robot_setting
    g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
    astar(g, start_poses, key2node, door2neighbors, door2node, full_graph)
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
#
# println(part1())
# # submit(part1(), cur_day, 1)
println(part2())
# # submit(part2(), cur_day, 2)
