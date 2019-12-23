using DrWatson
quickactivate(@__DIR__)
using LightGraphs, Combinatorics, TimerOutputs, MetaGraphs, Logging, DataStructures, Hungarian
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

DistCache = Dict{Set{Char}, Array{Int, 2}}
HeurCache = Dict{Vector{Int}, Int}
SolCache = Dict{Tuple{Int, Set{Char}}, Int} # cache of shortest paths to goal from (cur_position, have_keys)
Dists = Array{Int, 2}

struct Node
    taken_keys::Vector{Char}
    graph::SimpleGraph
    cur_pos::Int
    dist_so_far::Int
end

function shortest_paths(node::Node, dist_cache::DistCache)
    have_keys = Set(node.taken_keys)
    if !haskey(dist_cache, have_keys)
        states = floyd_warshall_shortest_paths(node.graph)
        dist_cache[have_keys] = copy(states.dists)
    end
    dist_cache[have_keys]
end

function get_avail_keys(dists::Array{Int, 2}, node::Node, key2node)
    cur_pos = node.cur_pos
    dist_from_node = dists[cur_pos, :]
    let2dist = Dict(letter=>dist_from_node[node] for (letter, node) in key2node if dist_from_node[node] < typemax(Int))
    let2dist
end

function build_neighbor(node::Node, next_key::Char, dist_traveled, key2node, door2neighbors, door2node)
    next_node = key2node[next_key]
    @timeit to "copy(node.taken_keys)" next_taken_keys = copy(node.taken_keys)
    @timeit to "copy(node.graph)" next_graph = copy(node.graph)
    push!(next_taken_keys, next_key)
    @timeit to "uppercase(next_key))" next_door = uppercase(next_key)
    @timeit to "modifying graph" if haskey(door2neighbors, next_door)   # for the last key there is no door
        for neighbor in door2neighbors[next_door]
            add_edge!(next_graph, door2node[next_door], neighbor)
        end
    end
    Node(next_taken_keys, next_graph, next_node, node.dist_so_far + dist_traveled)
end

function heuristic(node::Node, key2node, full_dists, heur_cache)
#     pro test input 81 a node acfidgb dává heuristiku 40, což je moc, to by nemělo: fixnout
# todo: try out if sorting kaes sense, seems like takes lots of time?
    @timeit to "nodes_to_go" nodes_to_go = [j for (i, j) in key2node if i ∉ node.taken_keys]
    @timeit to "push! nodes_to_go" push!(nodes_to_go, node.cur_pos)
    if !haskey(heur_cache, nodes_to_go)
        @timeit to "obtain key_dists" keys_dists = full_dists[nodes_to_go, nodes_to_go]
        @timeit to "find min_rows sum" min_rows_sum = minimum(keys_dists, dims=1) |> sum
        heur_cache[nodes_to_go] = min_rows_sum
    end
    heur_cache[nodes_to_go]
end

# function heuristic(node::Node, key2node, full_dists)
#     length(key2node) - length(node.taken_keys)
# end

function get_neighbors(node::Node, dist_cache, key2node, door2neighbors, door2node)
    @timeit to "shortest_paths" dists = shortest_paths(node, dist_cache)
    @timeit to "get_avail_keys" avail_keys = get_avail_keys(dists, node, filter(x->x[1] ∉ node.taken_keys, key2node))
    @timeit to "build_neighbor arr" neighbors = [(dist, build_neighbor(node, letter, dist, key2node, door2neighbors, door2node)) for (letter, dist) in avail_keys]
    neighbors
end

function a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph)
    # from the tree-like structure of greaph being searched, I don't need closed list
    dist_cache = DistCache()
    sol_cache = SolCache()
    heur_cache = HeurCache()
    open_nodes = PriorityQueue{Node, Int}()
    start_node = Node([], copy(g), start_pos, 0)
    full_dists = floyd_warshall_shortest_paths(full_graph).dists
    # maximum dist with some multiplicative margin
    max_val = maximum([i for i in full_dists if i < typemax(Int)])
    for i in 1:size(full_dists)[1]
        full_dists[i, i] = max_val * 100
    end

    enqueue!(open_nodes, start_node, 1)
    while !isempty(open_nodes)
        @timeit to "dequeue" cur_node = dequeue!(open_nodes)
        @debug "dequeued node: $(cur_node.taken_keys |> join) with dist_so_far: $(cur_node.dist_so_far |> join)"
        if length(cur_node.taken_keys) == length(key2node)
            return cur_node.dist_so_far
        end
        @timeit to "get_neighbors" node_neighbors = get_neighbors(cur_node, dist_cache, key2node, door2neighbors, door2node)
        for (dist, neighbor) in node_neighbors
            @timeit to "calc_heuristic" h_val = heuristic(neighbor, key2node, full_dists, heur_cache)
            f = neighbor.dist_so_far + h_val
            @debug "enqueing node: $(neighbor.taken_keys |> join) with dist_so_far: $(neighbor.dist_so_far |> join) and h: $h_val"
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

function part1()
    g, key2node, door2node, door2neighbors, start_pos, vprops, full_graph = build_graph(data)
    a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph)
    # solve_branch(g, start_pos, key2node, door2neighbors, door2node)
end

base_stream = global_logger().stream
my_debug_logger = ConsoleLogger(base_stream, Logging.Debug, meta_formatter=simple_fmt, show_limited=true, right_justify=100)
with_logger(my_debug_logger) do
    a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph)
end

to = TimerOutput()
a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph)
display(to)

using BenchmarkTools
@time solve_branch(g, start_node, key2node, door2neighbors, door2node)
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)

full_dists = floyd_warshall_shortest_paths(full_graph).dists
key_dists = full_dists[key_nodes, key_nodes]
# seq = "acidgbfeh"
seq = "acfidgbeh"
[full_dists[key2node[seq[i-1]], key2node[seq[i]]] for i in 2:length(seq)]
[full_dists[key2node[seq[i-1]], key2node[seq[i]]] for i in 2:length(seq)] |> sum
full_dists[start_pos, key2node[seq[1]]]
# print lengths of path for some sequence

#testing
data = read_file(cur_day, "test_input_44.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_pos, vprops, full_graph = build_graph(data)
@time a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph) == 44
@btime a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "test_input_60.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_pos, vprops, full_graph = build_graph(data)
@time a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph) == 60
@btime a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "test_input_72.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_pos, vprops, full_graph = build_graph(data)
@time a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph) == 72
@btime a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "test_input_76.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_pos, vprops, full_graph = build_graph(data)
@time a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph) == 76
@btime a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "test_input_81.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_pos, vprops, full_graph = build_graph(data)
@time a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph) == 81
@btime a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "test_input_86.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_pos, vprops, full_graph = build_graph(data)
@time a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph) == 86
@btime a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "test_input_132.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_pos, vprops, full_graph = build_graph(data)
@time a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph) == 132
@btime a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "test_input_136.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_pos, vprops, full_graph = build_graph(data)
@time a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph) == 136

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
