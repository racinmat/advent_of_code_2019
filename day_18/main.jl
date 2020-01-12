using DrWatson
quickactivate(@__DIR__)
using LightGraphs, Combinatorics, TimerOutputs, MetaGraphs, Logging, DataStructures, SimpleWeightedGraphs, Dates
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
# data = cur_day |> read_input |> x->split(x, '\n') .|> collect |>
#     x->hcat(x...) |> x->permutedims(x, [2, 1])
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
    full_graph = copy(g.graph)

    for (letter, node) in door2node
        neighbors_list = neighbors(g, node) |> collect
        door2neighbors[letter] = neighbors_list
        for n in neighbors_list
            rem_edge!(g, node, n)
        end
    end

    g.graph, key2node, door2node, door2neighbors, start_node, g.vprops, full_graph
end

function build_graph_part_2(data)
    start_pos = findfirst(x->x=='@', data)
    multi_robot_setting = hcat(['@', '#', '@'], ['#', '#', '#'], ['@', '#', '@'])
    data[start_pos[1]-1:start_pos[1]+1, start_pos[2]-1:start_pos[2]+1] = multi_robot_setting
    data_1 = data[1:start_pos[1], 1:start_pos[2]]
    data_2 = data[start_pos[1]:end, 1:start_pos[2]]
    data_3 = data[1:start_pos[1], start_pos[2]:end]
    data_4 = data[start_pos[1]:end, start_pos[2]:end]

    g1, key2node1, door2node1, door2neighbors1, start_pos1, vprops1, full_g1 = build_graph(data_1)
    g2, key2node2, door2node2, door2neighbors2, start_pos2, vprops2, full_g2 = build_graph(data_2)
    g3, key2node3, door2node3, door2neighbors3, start_pos3, vprops3, full_g3 = build_graph(data_3)
    g4, key2node4, door2node4, door2neighbors4, start_pos4, vprops4, full_g4 = build_graph(data_4)

    gs = [g1, g2, g3, g4]
    key2node = Dict{Char, Tuple{Int, Int}}()    # value is (num of graph, num of vertex)
    for (i, j) in enumerate([key2node1, key2node2, key2node3, key2node4])
        for (key, pos) in j
            key2node[key] = (i, pos)
        end
    end
    door2node = Dict{Char, Tuple{Int, Int}}()    # value is (num of graph, num of vertex)
    for (i, j) in enumerate([door2node1, door2node2, door2node3, door2node4])
        for (key, pos) in j
            door2node[key] = (i, pos)
        end
    end
    door2neighbors = Dict{Char, Tuple{Int, Vector{Int}}}()    # value is (num of graph, num of vertex)
    for (i, j) in enumerate([door2neighbors1, door2neighbors2, door2neighbors3, door2neighbors4])
        for (key, pos) in j
            door2neighbors[key] = (i, pos)
        end
    end
    start_poses = [start_pos1, start_pos2, start_pos3, start_pos4]

    graph2door = Dict{Int, Set{Char}}(1=>Set(), 2=>Set(), 3=>Set(), 4=>Set())
    for (letter, (num, pos)) in door2node
        push!(graph2door[num], letter)
    end

    full_gs = [full_g1, full_g2, full_g3, full_g4]
    gs, key2node, door2node, door2neighbors, start_poses, graph2door, full_gs
end

DistCache = Dict{Tuple{Set{Char}, Int}, Vector{Int}}  # cache for (have_keys, cur_pos)
HeurCache = Dict{Vector{Int}, Int}
GraphCache = Dict{Set{Char}, AbstractGraph}
NodeRepr = Tuple{Set{Int}, Set{Char}, Int}

DistCache2 = Dict{Tuple{Int, Set{Char}, Int}, Vector{Int}}  # cache for (graph_num, have_keys, cur_pos)
GraphCache2 = Dict{Tuple{Int, Set{Char}}, AbstractGraph}
NodeRepr2 = Tuple{Vector{Int}, Set{Char}, Int}
HeurCache2 = Dict{Tuple{Int, Set{Int}}, Int}

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
    graphs::Vector{SimpleGraph}
    cur_poses::Vector{Int}
    dist_so_far::Int
    heur::Int
end

function shortest_paths(node::SingleNode, dist_cache::DistCache)
    @timeit to "shortest_paths cache key" dist_cache_key = (Set(node.taken_keys), node.cur_pos)
    if !haskey(dist_cache, dist_cache_key)
        @timeit to "dijkstra" states = dijkstra_shortest_paths(node.graph, node.cur_pos)
        @timeit to "copy(states.dists)" dist_cache[dist_cache_key] = copy(states.dists)
    end
    dist_cache[dist_cache_key]
end

function shortest_paths(node::MultiNode, dist_cache::DistCache2, door2node, graph2door)
    all_dists = Vector{Vector{Int}}(undef, length(node.graphs))
    for (i, (graph, cur_pos)) in enumerate(zip(node.graphs, node.cur_poses))
        @timeit to "shortest_paths cache key" dist_cache_key = (i, Set(key for key in node.taken_keys if uppercase(key) ∈ graph2door[i]), cur_pos)
        if !haskey(dist_cache, dist_cache_key)
            @timeit to "dijkstra" states = dijkstra_shortest_paths(graph, cur_pos)
            @timeit to "copy(states.dists)" dists = copy(states.dists)
            dist_cache[dist_cache_key] = dists
        end
        all_dists[i] = dist_cache[dist_cache_key]
    end
    all_dists
end

function get_avail_keys(dists::Vector{Int}, node::SingleNode, key2node)
    let2dist = Dict(letter=>dists[node] for (letter, node) in key2node if dists[node] < typemax(Int))
    let2dist
end

function get_avail_keys(dists::Vector{Vector{Int}}, node::MultiNode, key2node)
    let2dist = Dict(letter=>(dists[part_num][pos], part_num) for (letter, (part_num, pos)) in key2node if dists[part_num][pos] < typemax(Int))
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
        next_door = uppercase(next_key)
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

function build_neighbor(node::MultiNode, next_key::Char, dist_traveled, from_idx, key2node, door2neighbors, door2node,
        graph_cache, heur_cache, graph2door, full_dists)
    next_pos = key2node[next_key][2]
    @timeit to "copy(node.taken_keys)" next_taken_keys = copy(node.taken_keys)
    # copying graph is costly, both time and memory-wise
    push!(next_taken_keys, next_key)
    next_graphs = Vector{SimpleGraph}(undef, length(node.graphs))
    for (i, graph) in enumerate(node.graphs)
        cache_key = (i, Set(key for key in next_taken_keys if uppercase(key) ∈ graph2door[i]))
        if !haskey(graph_cache, cache_key)
            @timeit to "copy(node.graph)" next_graph = copy(graph)
            next_door = uppercase(next_key)
            if next_door ∈ graph2door[i]
                next_door_part, next_door_neighbors = door2neighbors[next_door]
                door_node = door2node[next_door]
                for neighbor in next_door_neighbors
                    add_edge!(next_graph, door_node[2], neighbor)
                end
            end
            graph_cache[cache_key] = next_graph
        end
        next_graphs[i] = graph_cache[cache_key]
    end
    next_poses = copy(node.cur_poses)
    next_poses[from_idx] = next_pos
    # @timeit to "calc_heuristic" h_val = heuristic!(next_taken_keys, next_poses, key2node, full_dists, heur_cache)
    h_val = heuristic!(next_taken_keys, next_poses, key2node, full_dists, heur_cache)
    # todo: here adjust the update of positions and dist by cached dists
    MultiNode(next_taken_keys, next_graphs, next_poses, node.dist_so_far + dist_traveled, min(h_val, node.heur))
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

# based on minimal spanning tree
function heuristic!(taken_keys::Vector{Char}, cur_poses::Vector{Int}, key2node, full_dists, heur_cache)
    heur_sum = 0
    for i in 1:length(cur_poses)
        cur_pos = cur_poses[i]
        nodes_in_graph = [(key, pos) for (key, (part, pos)) in key2node if part == i]
        @timeit to "nodes_to_go" nodes_to_go = [pos for (key, pos) in nodes_in_graph if i ∉ taken_keys]
        if isempty(nodes_to_go)    # heur is sum and thus nothing is added
            continue
        end
        @timeit to "push! nodes_to_go" push!(nodes_to_go, cur_pos)
        cache_key = (i, Set(nodes_to_go))
        if !haskey(heur_cache, cache_key)
            @timeit to "obtain key_dists" keys_dists = full_dists[i][nodes_to_go, nodes_to_go]
            @timeit to "kruskal mst sum" mst_sum = kruskal_mst(SimpleWeightedGraph(keys_dists)) .|> (x->x.weight) |> sum
            heur_cache[cache_key] = mst_sum
        end
        heur_sum += heur_cache[cache_key]
    end
    heur_sum
end

function make_neighbor_repr(node::SingleNode, letter, dist, key2node)::NodeRepr
    next_pos = key2node[letter]
    next_taken_keys = copy(node.taken_keys)
    push!(next_taken_keys, letter)
    Set(next_pos), Set(next_taken_keys), node.dist_so_far + dist
end

function make_neighbor_repr(node::MultiNode, letter, dist, from_idx, key2node)::NodeRepr2
    next_pos = key2node[letter][2]
    next_taken_keys = copy(node.taken_keys)
    push!(next_taken_keys, letter)
    next_poses = copy(node.cur_poses)
    next_poses[from_idx] = next_pos
    copy(next_poses), Set(next_taken_keys), node.dist_so_far + dist
end

function get_neighbors(node::SingleNode, dist_cache, graph_cache, key2node, door2neighbors, door2node, full_dists,
        heur_cache, open_configs)
    @timeit to "shortest_paths" dists = shortest_paths(node, dist_cache)
    @timeit to "get_avail_keys" avail_keys = get_avail_keys(dists, node, filter(x->x[1] ∉ node.taken_keys, key2node))
    @timeit to "prepare_neighbors" neighbors, neighbor_reprs = prepare_neighbors(node, key2node, door2neighbors,
        door2node, open_configs, avail_keys, graph_cache, full_dists, heur_cache)
    for (letter, neighbor_repr) in neighbor_reprs
        if neighbor_repr ∉ open_configs
            push!(open_configs, neighbor_repr)
        end
    end
    neighbors
end

function get_neighbors(node::MultiNode, dist_cache, graph_cache, key2node, door2neighbors, door2node, heur_cache,
        open_configs, graph2door, full_dists)
    @timeit to "shortest_paths" dists = shortest_paths(node, dist_cache, door2node, graph2door)
    @timeit to "get_avail_keys" avail_keys = get_avail_keys(dists, node, filter(x->x[1] ∉ node.taken_keys, key2node))
    @timeit to "prepare_neighbors" neighbors, neighbor_reprs = prepare_neighbors(node, key2node, door2neighbors,
        door2node, door2neighbors, door2node, open_configs, avail_keys, graph_cache, heur_cache, graph2door, full_dists)
    for (letter, neighbor_repr) in neighbor_reprs
        if neighbor_repr ∉ open_configs
            push!(open_configs, neighbor_repr)
        end
    end
    neighbors
end

function prepare_neighbors(node::SingleNode, key2node, door2neighbors, door2node, open_configs, avail_keys, graph_cache, full_dists, heur_cache)
    @timeit to "neighbor_repr" neighbor_reprs = Dict(letter=>make_neighbor_repr(node, letter, dist, key2node) for (letter, dist) in avail_keys)
    @timeit to "build_neighbor arr" neighbors = [
        (dist, build_neighbor(node, letter, dist, key2node, door2neighbors, door2node, graph_cache, full_dists, heur_cache))
        for (letter, dist) in avail_keys if neighbor_reprs[letter] ∉ open_configs]
    neighbors, neighbor_reprs
end

function prepare_neighbors(node::MultiNode, key2node, door2neighbors, door2node, open_configs, avail_keys, graph_cache, heur_cache,
        graph2door, full_dists)
    @timeit to "neighbor_repr" neighbor_reprs = Dict(letter=>make_neighbor_repr(node, letter, dist, from_idx, key2node) for (letter, (dist, from_idx)) in avail_keys)
    neighbors = [(dist, build_neighbor(node, letter, dist, from_idx, key2node, door2neighbors, door2node, graph_cache,
        heur_cache, graph2door, full_dists)) for (letter, (dist, from_idx)) in avail_keys if neighbor_reprs[letter] ∉ open_configs]
    neighbors, neighbor_reprs
end

function make_init_node(g, start_pos::Int)
    SingleNode([], copy(g), start_pos, 0, typemax(Int) ÷ 10)
end

function make_init_node(g, start_poses::Vector{Int})
    MultiNode([], copy(g), start_poses, 0, typemax(Int) ÷ 10)
end

function astar(g::AbstractGraph, start_pos::Int, key2node, door2neighbors, door2node, full_graph)
    dist_cache = DistCache()
    heur_cache = HeurCache()
    graph_cache = GraphCache()
    open_nodes = PriorityQueue{Node, Int}()
    open_configs = Set{NodeRepr}()  # set of tuples (position, set of taken keys, dist)
    start_node = make_init_node(g, start_pos)
    # maximum dist with some multiplicative margin
    @timeit to "init_floyd_warshall" full_dists = floyd_warshall_shortest_paths(full_graph).dists
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

function astar(gs::Vector{<:AbstractGraph}, start_poses::Vector{Int}, key2node, door2neighbors, door2node, graph2door,
        full_gs)
    dist_cache = DistCache2()
    heur_cache = HeurCache2()
    graph_cache = GraphCache2()
    open_nodes = PriorityQueue{Node, Int}()
    open_configs = Set{NodeRepr2}()  # set of tuples (position, set of taken keys, dist)
    start_node = make_init_node(gs, start_poses)
    full_dists = [floyd_warshall_shortest_paths(full_g).dists for full_g in full_gs]
    # maximum dist with some multiplicative margin
    max_size = 0
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
            door2neighbors, door2node, heur_cache, open_configs, graph2door, full_dists)
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
    g, key2node, door2node, door2neighbors, start_poses, graph2door, full_gs = build_graph_part_2(data)
    astar(g, start_poses, key2node, door2neighbors, door2node, graph2door, full_gs)
end

# println(part1())
# # submit(part1(), cur_day, 1)
# println(part2())
# # submit(part2(), cur_day, 2)
