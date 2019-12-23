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
    next_taken_keys = copy(node.taken_keys)
    next_graph = copy(node.graph)
    push!(next_taken_keys, next_key)
    next_door = uppercase(next_key)
    if haskey(door2neighbors, next_door)   # for the last key there is no door
        for neighbor in door2neighbors[next_door]
            add_edge!(next_graph, door2node[next_door], neighbor)
        end
    end
    Node(next_taken_keys, next_graph, next_node, node.dist_so_far + dist_traveled)
end

function heuristic(node::Node, key2node, full_dists)
    nodes_to_go = [j for (i, j) in key2node if i ∉ node.taken_keys]
    push!(nodes_to_go, node.cur_pos)
    keys_dists = full_dists[nodes_to_go, nodes_to_go]
    max_val = maximum(keys_dists)   # maximum dist with some multipúlicative margin
    for i in 1:length(nodes_to_go)
        keys_dists[i, i] = max_val * 100
    end
    minimum_match_cost = Hungarian.hungarian(keys_dists)[2]
    minimum_match_cost
end

function get_neighbors(node::Node, dist_cache, key2node, door2neighbors, door2node)
    dists = shortest_paths(node, dist_cache)
    avail_keys = get_avail_keys(dists, node, filter(x->x[1] ∉ node.taken_keys, key2node))
    neighbors = [(dist, build_neighbor(node, letter, dist, key2node, door2neighbors, door2node)) for (letter, dist) in avail_keys]
    neighbors
end

function a_star(g, start_pos, key2node, door2neighbors, door2node, full_graph)
    # from the tree-like structure of greaph being searched, I don't need closed list
    dist_cache = DistCache()
    sol_cache = SolCache()
    open_nodes = PriorityQueue{Node, Int}()
    start_node = Node([], copy(g), start_pos, 0)
    full_dists = floyd_warshall_shortest_paths(full_graph).dists

    enqueue!(open_nodes, start_node, 1)
    while !isempty(open_nodes)
        cur_node = dequeue!(open_nodes)
        @debug "dequeued node: $(cur_node.taken_keys |> join) with dist_so_far: $(cur_node.dist_so_far |> join)"
        if length(cur_node.taken_keys) == length(key2node)
            return cur_node.dist_so_far
        end
        for (dist, neighbor) in get_neighbors(cur_node, dist_cache, key2node, door2neighbors, door2node)
            h_val = heuristic(neighbor, key2node, full_dists)
            f = neighbor.dist_so_far + h_val
            @debug "enqueing node: $(neighbor.taken_keys |> join) with dist_so_far: $(neighbor.dist_so_far |> join) and h: $h_val"
            enqueue!(open_nodes, neighbor, f)
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

using BenchmarkTools
@time solve_branch(g, start_node, key2node, door2neighbors, door2node)
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)

function simple_fmt(level, _module, group, id, file, line)
    color = Logging.default_logcolor(level)
    prefix = (level == Logging.Warn ? "Warning" : string(level))*':'
    suffix = "line: $line"
    color, prefix, suffix
end

function try_logging()
    with_logger(my_debug_logger) do
    # with_logger(global_logger()) do
        do_log()
    end
    # do_log()
end

function do_log()
    @debug "oh hi mark"
end

base_stream = global_logger().stream

my_debug_logger = ConsoleLogger(base_stream, Logging.Debug, meta_formatter=simple_fmt, show_limited=true, right_justify=100)

try_logging()
do_log()

# global_logger(SimpleLogger(stdout, Logging.Debug))
# SimpleLogger(stdout, Logging.Info)

shortcuts = false
shortcuts = true
with_logger(my_debug_logger) do
    solve_branch(g, start_node, key2node, door2neighbors, door2node)
end

a = PriorityQueue{Char, Int}()
enqueue!(a, 'a', Int('a'))
enqueue!(a, 'b', Int('b'))
enqueue!(a, 'c', Int('c'))
enqueue!(a, 'd', Int('d'))

'a' ∈ keys(a)
haskey(a, 'a')
enqueue!(a, 'a', Int('a') + 5)
#testing
data = read_file(cur_day, "test_input_44.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_node, vprops = build_graph(data)
@time solve_branch(g, start_node, key2node, door2neighbors, door2node) == 44
shortcuts = false
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)
shortcuts = true
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)

data = read_file(cur_day, "test_input_60.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_node, vprops = build_graph(data)
@time solve_branch(g, start_node, key2node, door2neighbors, door2node) == 60
shortcuts = false
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)
shortcuts = true
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)

data = read_file(cur_day, "test_input_72.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_node, vprops = build_graph(data)
@time solve_branch(g, start_node, key2node, door2neighbors, door2node) == 72
shortcuts = false
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)
shortcuts = true
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)

data = read_file(cur_day, "test_input_76.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_node, vprops = build_graph(data)
@time solve_branch(g, start_node, key2node, door2neighbors, door2node) == 76
shortcuts = false
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)
shortcuts = true
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)

data = read_file(cur_day, "test_input_81.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_node, vprops = build_graph(data)
@time solve_branch(g, start_node, key2node, door2neighbors, door2node) == 81
shortcuts = false
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)
shortcuts = true
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)

data = read_file(cur_day, "test_input_86.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_node, vprops = build_graph(data)
@time solve_branch(g, start_node, key2node, door2neighbors, door2node) == 86
shortcuts = false
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)
shortcuts = true
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)

data = read_file(cur_day, "test_input_132.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_node, vprops = build_graph(data)
@time solve_branch(g, start_node, key2node, door2neighbors, door2node) == 132
shortcuts = false
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)
shortcuts = true
@btime solve_branch(g, start_node, key2node, door2neighbors, door2node)

data = read_file(cur_day, "test_input_136.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_node, vprops = build_graph(data)
@time solve_branch(g, start_node, key2node, door2neighbors, door2node) == 136

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
