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

    ## building smaller graph
    num_nodes = 1+length(key2node)+length(door2node)
    # num_nodes = 1+length(key2node)
    small_g = MetaGraph(SimpleGraph(num_nodes), 1.)
    start_node_small = 1
    key2node_small = Dict(key => 1+val for (val, key) in enumerate(keys(key2node)))
    door2node_small = Dict(key => 1+length(key2node)+val for (val, key) in enumerate(keys(door2node)))
    small2g = Dict(1=>start_node)
    g2small = Dict(start_node=>1)
    for key in keys(key2node)
        small2g[key2node_small[key]] = key2node[key]
        g2small[key2node[key]] = key2node_small[key]
    end
    for door in keys(door2node)
        small2g[door2node_small[door]] = door2node[door]
        g2small[door2node[door]] = door2node_small[door]
    end
    # adding start to key and doors edges
    for (small_node, node) in small2g
        node2others = dijkstra_shortest_paths(g, node)
        for (small_other, other) in small2g
            if node == other
                continue
            end
            iter = node2others.parents[other]
            sth_in_way = false
            while iter != node
                if iter ∈ keys(g2small) # there are all interesting nodes
                    sth_in_way = true
                    break
                end
                iter = node2others.parents[iter]
            end
            # println(dist_so_far, ' ', node2others.dists[other])
            if !sth_in_way
                add_edge!(small_g, small_node, small_other)
                set_prop!(small_g, small_node, small_other, :weight, node2others.dists[other])
            end
        end
    end

    # need to remap vertices, theirs numbering is changed after removal
    full_graph = copy(small_g)

    # for each door, I will be manipulating only those edges that are "behind" that door, by testing adjacency of neighbors
    door2neighbors = Dict{Char, Vector{Tuple{Int, Int}}}()
    for (letter, node) in door2node_small
        neighbors_list = neighbors(full_graph, node) .|> (x->(x, get_prop(full_graph, node, x, :weight))) |> collect
        door2neighbors[letter] = neighbors_list
    end

    node2str = Dict(1=>"start")
    for (letter, node) in key2node_small
        node2str[node] = string(letter)
    end
    for (letter, node) in door2node_small
        node2str[node] = string(letter)
    end

    door_near_edges = Dict{Char, Vector{Tuple{Int, Int}}}()
    door_far_edges = Dict{Char, Vector{Tuple{Int, Int}}}()
    seen_nodes = Set([1])
    while length(seen_nodes) < nv(full_graph)
        seen_nodes = union(seen_nodes, Set([neighbors(full_graph, i) for i in seen_nodes] |> Iterators.flatten |> collect))
        # in_frontier = setdiff(Set([neighbors(full_graph, i) for i in seen_nodes] |> Iterators.flatten |> collect), seen_nodes)
        for (door, neighbours) in door2neighbors
            door_node = door2node_small[door]
            door_node ∉ seen_nodes && continue
            door ∈ keys(door_far_edges) && continue
            door_near_edges[door] = []
            door_far_edges[door] = []
            for (node, e_weight) in neighbours
                if node ∈ seen_nodes
                    push!(door_near_edges[door], (node, e_weight))
                else
                    push!(door_far_edges[door], (node, e_weight))
                end
            end
        end
    end

    for (door, neighbors) in door_far_edges
        for (n, edge_weight) in neighbors
            rem_edge!(small_g, door2node_small[door], n)
        end
    end

    small_g, key2node_small, door2node_small, door_far_edges, start_node_small, full_graph
end

function build_graph_part_2(data)
    start_pos = findfirst(x->x=='@', data)
    multi_robot_setting = hcat(['@', '#', '@'], ['#', '#', '#'], ['@', '#', '@'])
    data[start_pos[1]-1:start_pos[1]+1, start_pos[2]-1:start_pos[2]+1] = multi_robot_setting
    data_1 = data[1:start_pos[1], 1:start_pos[2]]
    data_2 = data[start_pos[1]:end, 1:start_pos[2]]
    data_3 = data[1:start_pos[1], start_pos[2]:end]
    data_4 = data[start_pos[1]:end, start_pos[2]:end]

    g1, key2node1, door2node1, door2neighbors1, start_pos1, full_g1 = build_graph(data_1)
    g2, key2node2, door2node2, door2neighbors2, start_pos2, full_g2 = build_graph(data_2)
    g3, key2node3, door2node3, door2neighbors3, start_pos3, full_g3 = build_graph(data_3)
    g4, key2node4, door2node4, door2neighbors4, start_pos4, full_g4 = build_graph(data_4)

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
    door2neighbors = Dict{Char, Tuple{Int, Vector{Tuple{Int, Int}}}}()    # value is (num of graph, num of vertex)
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

DistCache = Dict{Tuple{Set{Char}, Int}, Vector{<:Real}}  # cache for (have_keys, cur_pos)
HeurCache = Dict{Vector{Int}, Int}
GraphCache = Dict{Set{Char}, AbstractGraph}
NodeReprWithDist = Tuple{Int, Set{Char}, Int}
NodeRepr = Tuple{Int, Set{Char}}

DistCache2 = Dict{Tuple{Int, Set{Char}, Int}, Vector{<:Real}}  # cache for (graph_num, have_keys, cur_pos)
GraphCache2 = Dict{Tuple{Int, Set{Char}}, AbstractGraph}
NodeReprWithDist2 = Tuple{Vector{Int}, Set{Char}, Int}
NodeRepr2 = Tuple{Vector{Int}, Set{Char}}
HeurCache2 = Dict{Tuple{Int, Set{Int}}, Int}

abstract type Node end

struct SingleNode <: Node
    taken_keys::Vector{Char}
    graph::MetaGraph
    cur_pos::Int
    dist_so_far::Int
    heur::Int
end

struct MultiNode <: Node
    taken_keys::Vector{Char}
    graphs::Vector{MetaGraph}
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
    all_dists = Vector{Vector{Real}}(undef, length(node.graphs))
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

function get_avail_keys(dists::Vector{<:Real}, key2node)
    let2dist = Dict(letter=>dists[node] for (letter, node) in key2node if dists[node] < Inf)
    let2dist
end

function get_avail_keys(dists::Vector{<:Vector{<:Real}}, key2node)
    let2dist = Dict(letter=>(dists[part_num][pos], part_num) for (letter, (part_num, pos)) in key2node if dists[part_num][pos] < Inf)
    let2dist
end

function build_neighbor(node::SingleNode, next_key::Char, dist_traveled, key2node, door2neighbors, door2node, graph_cache,
        full_dists, heur_cache)
    next_pos = key2node[next_key]
    @timeit to "copy(node.taken_keys)" next_taken_keys = copy(node.taken_keys)
    push!(next_taken_keys, next_key)
    cache_key = Set(next_taken_keys)
    if !haskey(graph_cache, cache_key)
        @timeit to "copy(node.graph)" next_graph = copy(node.graph)
        next_door = uppercase(next_key)
        @timeit to "modifying graph" if haskey(door2neighbors, next_door)   # for the last key there is no door
            for (neighbor, edge_weight) in door2neighbors[next_door]
                add_edge!(next_graph, door2node[next_door], neighbor)
                set_prop!(next_graph, door2node[next_door], neighbor, :weight, edge_weight)
            end
        end
        graph_cache[cache_key] = next_graph
    end
    next_graph = graph_cache[cache_key]
    @timeit to "calc_heuristic" h_val = heuristic!(next_taken_keys, next_pos, key2node, full_dists, heur_cache)
    # @debug "building node: $(next_taken_keys |> join), parent dist so far: $(node.dist_so_far), dist from parent: $dist_traveled"
    SingleNode(next_taken_keys, next_graph, next_pos, node.dist_so_far + dist_traveled, min(h_val, node.heur))
end

function build_neighbor(node::MultiNode, next_key::Char, dist_traveled, from_idx, key2node, door2neighbors, door2node,
        graph_cache, heur_cache, graph2door, full_dists)
    next_pos = key2node[next_key][2]
    @timeit to "copy(node.taken_keys)" next_taken_keys = copy(node.taken_keys)
    # copying graph is costly, both time and memory-wise
    push!(next_taken_keys, next_key)
    next_graphs = Vector{MetaGraph}(undef, length(node.graphs))
    for (i, graph) in enumerate(node.graphs)
        cache_key = (i, Set(key for key in next_taken_keys if uppercase(key) ∈ graph2door[i]))
        if !haskey(graph_cache, cache_key)
            @timeit to "copy(node.graph)" next_graph = copy(graph)
            next_door = uppercase(next_key)
            if next_door ∈ graph2door[i]
                next_door_part, next_door_neighbors = door2neighbors[next_door]
                door_node = door2node[next_door]
                for (neighbor, edge_weight) in next_door_neighbors
                    @debug neighbor, edge_weight
                    add_edge!(next_graph, door_node[2], neighbor)
                    set_prop!(next_graph, door_node[2], neighbor, :weight, edge_weight)
                end
            end
            graph_cache[cache_key] = next_graph
        end
        next_graphs[i] = graph_cache[cache_key]
    end
    next_poses = copy(node.cur_poses)
    next_poses[from_idx] = next_pos
    @timeit to "calc_heuristic" h_val = heuristic!(next_taken_keys, next_poses, key2node, full_dists, heur_cache)
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

function make_neighbor_repr(node::SingleNode, letter, dist, key2node)::Tuple{NodeReprWithDist, NodeRepr}
    next_pos = key2node[letter]
    next_taken_keys = copy(node.taken_keys)
    push!(next_taken_keys, letter)
    (next_pos, Set(next_taken_keys), node.dist_so_far + dist), (next_pos, Set(next_taken_keys))
end

function make_neighbor_repr(node::MultiNode, letter, dist, from_idx, key2node)::Tuple{NodeReprWithDist2, NodeRepr2}
    next_pos = key2node[letter][2]
    next_taken_keys = copy(node.taken_keys)
    push!(next_taken_keys, letter)
    next_poses = copy(node.cur_poses)
    next_poses[from_idx] = next_pos
    (copy(next_poses), Set(next_taken_keys), node.dist_so_far + dist), (copy(next_poses), Set(next_taken_keys))
end

function get_neighbors(node::SingleNode, dist_cache, graph_cache, key2node, door2neighbors, door2node, full_dists,
        heur_cache, open_configs_with_dist)
    @timeit to "shortest_paths" dists = shortest_paths(node, dist_cache)
    # @debug "dists: $(dists |> x->join(x, ',')), from node $(node.taken_keys |> join), $(node.cur_pos)"
    @timeit to "get_avail_keys" avail_keys = get_avail_keys(dists, filter(x->x[1] ∉ node.taken_keys, key2node))
    # @debug "avail_keys: $avail_keys, from node $(node.taken_keys |> join), $(node.cur_pos)"
    @timeit to "prepare_neighbors" neighbors, neighbor_reprs = prepare_neighbors(node, key2node, door2neighbors,
        door2node, open_configs_with_dist, avail_keys, graph_cache, heur_cache, full_dists)
    for (letter, neighbor_repr) in neighbor_reprs
        if neighbor_repr[1] ∉ open_configs_with_dist
            push!(open_configs_with_dist, neighbor_repr[1])
        end
    end
    neighbors, Dict(key => val[2] for (key, val) in neighbor_reprs)
end

function get_neighbors(node::MultiNode, dist_cache, graph_cache, key2node, door2neighbors, door2node, heur_cache,
        open_configs_with_dist, graph2door, full_dists)
    @timeit to "shortest_paths" dists = shortest_paths(node, dist_cache, door2node, graph2door)
    @timeit to "get_avail_keys" avail_keys = get_avail_keys(dists, filter(x->x[1] ∉ node.taken_keys, key2node))
    @timeit to "prepare_neighbors" neighbors, neighbor_reprs = prepare_neighbors(node, key2node, door2neighbors,
        door2node, open_configs_with_dist, avail_keys, graph_cache, heur_cache, graph2door, full_dists)
    for (letter, neighbor_repr) in neighbor_reprs
        if neighbor_repr[1] ∉ open_configs_with_dist
            push!(open_configs_with_dist, neighbor_repr[1])
        end
    end
    neighbors, Dict(key => val[2] for (key, val) in neighbor_reprs)
end

function prepare_neighbors(node::SingleNode, key2node, door2neighbors, door2node, open_configs_with_dist, avail_keys,
        graph_cache, heur_cache, full_dists)
    @timeit to "neighbor_repr" neighbor_reprs = Dict(letter=>make_neighbor_repr(node, letter, dist, key2node) for (letter, dist) in avail_keys)
    @timeit to "build_neighbor arr" neighbors = [
        (dist, build_neighbor(node, letter, dist, key2node, door2neighbors, door2node, graph_cache, full_dists, heur_cache))
        for (letter, dist) in avail_keys if neighbor_reprs[letter][1] ∉ open_configs_with_dist]
    neighbors, neighbor_reprs
end

function prepare_neighbors(node::MultiNode, key2node, door2neighbors, door2node, open_configs_with_dist, avail_keys,
        graph_cache, heur_cache, graph2door, full_dists)
    @timeit to "neighbor_repr" neighbor_reprs = Dict(letter=>make_neighbor_repr(node, letter, dist, from_idx, key2node) for (letter, (dist, from_idx)) in avail_keys)
    neighbors = [(dist, build_neighbor(node, letter, dist, from_idx, key2node, door2neighbors, door2node, graph_cache,
        heur_cache, graph2door, full_dists)) for (letter, (dist, from_idx)) in avail_keys if neighbor_reprs[letter][1] ∉ open_configs_with_dist]
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
    open_configs = Set{NodeReprWithDist}()  # set of tuples (position, set of taken keys, dist)
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

function astar(g::AbstractGraph, start_pos::Int, key2node, door2neighbors, door2node, full_graph)
    dist_cache = DistCache()
    heur_cache = HeurCache()
    graph_cache = GraphCache()
    open_nodes = PriorityQueue{Node, Int}()
    open_configs_with_dist = Set{NodeReprWithDist}()  # set of tuples (position, set of taken keys, dist)
    open_configs = Dict{NodeRepr, Tuple{Int, Int}}()  # set of tuples (position, set of taken keys, dist)
    repr_with_dist2node = Dict{NodeReprWithDist, Node}()
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
        @timeit to "get_neighbors" node_neighbors, neighbor_reprs = get_neighbors(cur_node, dist_cache, graph_cache, key2node,
            door2neighbors, door2node, full_dists, heur_cache, open_configs_with_dist)
        for (dist, neighbor) in node_neighbors
            neighbor_repr = neighbor_reprs[neighbor.taken_keys[end]]
            if haskey(open_configs, neighbor_repr)
                @debug "hit same point for $(neighbor.taken_keys |> join), old dist so far $(open_configs[neighbor_repr]), new dist so far $(neighbor.dist_so_far), new heur: $(neighbor.heur)"
                if neighbor.dist_so_far < open_configs[neighbor_repr][1]   # if I got here cheaper than original
                    old_repr_with_dist = neighbor_repr[1], neighbor_repr[2], sum(open_configs[neighbor_repr])
                    old_node = repr_with_dist2node[old_repr_with_dist]
                    if haskey(open_nodes, old_node)     # sometimes duplicated node was already visited because of the heuristics
                        delete!(open_nodes, old_node)    # heur is same, using it as key
                    end
                else    # else skipping this node
                    continue
                end
            end
            f = neighbor.dist_so_far + neighbor.heur
            open_configs[neighbor_repr] = neighbor.dist_so_far, neighbor.heur
            @debug "enqueing node: $(neighbor.taken_keys |> join) with dist_so_far: $(neighbor.dist_so_far |> join) and h: $(neighbor.heur)"
            @timeit to "enqueue" enqueue!(open_nodes, neighbor, f)
            repr_with_dist2node[neighbor_repr[1], neighbor_repr[2], f] = neighbor
        end
    end
end

function astar(gs::Vector{<:AbstractGraph}, start_poses::Vector{Int}, key2node, door2neighbors, door2node, graph2door,
        full_gs)
    dist_cache = DistCache2()
    heur_cache = HeurCache2()
    graph_cache = GraphCache2()
    open_nodes = PriorityQueue{Node, Int}()
    open_configs = Dict{NodeRepr2, Tuple{Int, Int}}()  # set of tuples (position, set of taken keys, dist)
    open_configs_with_dist = Set{NodeReprWithDist2}()  # set of tuples (position, set of taken keys, dist)
    repr_with_dist2node = Dict{NodeReprWithDist2, Node}()
    start_node = make_init_node(gs, start_poses)
    full_dists = [floyd_warshall_shortest_paths(full_g).dists for full_g in full_gs]
    for full_dist in full_dists
        max_val = maximum([i for i in full_dist if i < typemax(Int)])
        max_size = 0
        for i in 1:size(full_dist)[1]
            full_dist[i, i] = max_val * 100
        end
    end
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
        @timeit to "get_neighbors" node_neighbors, neighbor_reprs = get_neighbors(cur_node, dist_cache, graph_cache, key2node,
            door2neighbors, door2node, heur_cache, open_configs_with_dist, graph2door, full_dists)
        for (dist, neighbor) in node_neighbors
            neighbor_repr = neighbor_reprs[neighbor.taken_keys[end]]
            if haskey(open_configs, neighbor_repr)
                @debug "hit same point for $(neighbor.taken_keys |> join), old dist so far $(open_configs[neighbor_repr]), new dist so far $(neighbor.dist_so_far), new heur: $(neighbor.heur)"
                if neighbor.dist_so_far < open_configs[neighbor_repr][1]   # if I got here cheaper than original
                    old_repr_with_dist = neighbor_repr[1], neighbor_repr[2], sum(open_configs[neighbor_repr])
                    old_node = repr_with_dist2node[old_repr_with_dist]
                    if haskey(open_nodes, old_node)     # sometimes duplicated node was already visited because of the heuristics
                        delete!(open_nodes, old_node)    # heur is same, using it as key
                    end
                else    # else skipping this node
                    continue
                end
            end
            f = neighbor.dist_so_far + neighbor.heur
            open_configs[neighbor_repr] = neighbor.dist_so_far, neighbor.heur
            @debug "enqueing node: $(neighbor.taken_keys |> join) with dist_so_far: $(neighbor.dist_so_far |> join) and h: $(neighbor.heur)"
            @timeit to "enqueue" enqueue!(open_nodes, neighbor, f)
            repr_with_dist2node[neighbor_repr[1], neighbor_repr[2], f] = neighbor
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
# verbose = false

function part1()
    g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
    astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
end

function part2()
    g, key2node, door2node, door2neighbors, start_poses, graph2door, full_gs = build_graph_part_2(data)
    astar(g, start_poses, key2node, door2neighbors, door2node, graph2door, full_gs)
end

println(part1())
# submit(part1(), cur_day, 1)
println(part2())
# submit(part2(), cur_day, 2)
