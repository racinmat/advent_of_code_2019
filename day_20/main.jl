using DrWatson
quickactivate(@__DIR__)
using LightGraphs, MetaGraphs
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->split(x, '\n') .|> collect |>
    x->hcat(x...) |> x->permutedims(x, [2, 1])
# data = cur_day |> test_input |> x->replace(x, "\r" => "") |> x->split(x, '\n') .|> collect |>
#     x->hcat(x...) |> x->permutedims(x, [2, 1])
# data = read_file(cur_day, "test_input_small.txt") |> x->replace(x, "\r" => "") |> x->split(x, '\n') .|> collect |>
#     x->hcat(x...) |> x->permutedims(x, [2, 1])

function build_base_graph(data)
    g = LightGraphs.SimpleGraphs.grid(data |> size |> collect)
    g = MetaGraph(g)
    portal_nodes = Set{Int}()
    door2node = Dict{String, Vector{Int}}()
    for (i, j) in enumerate(CartesianIndices(data))
        set_prop!(g, i, :coords, j)
        # todo: put here the property of teleport and then squish letters together
    end

    for vertex in nv(g):-1:1
        coords = get_prop(g, vertex, :coords)
        if data[coords] ∈ ['#', ' ']
            rem_vertex!(g, vertex)
        end
    end

    for vertex in vertices(g)
        coords = get_prop(g, vertex, :coords)
        if Int('A') <= Int(data[coords]) <= Int('Z')
            push!(portal_nodes, vertex)
        end
    end

    for vertex in portal_nodes
        degree(g, vertex) != 1 && continue
        v_coords = get_prop(g, vertex, :coords)
        letter = data[v_coords]
        other_v = first(neighbors(g, vertex))
        other_v_coords = get_prop(g, other_v, :coords)
        other_letter = data[other_v_coords]
        if sum(Tuple(v_coords)) < sum(Tuple(other_v_coords))
            portal = letter * other_letter
        else
            portal = other_letter * letter
        end
        if !haskey(door2node, portal)
            door2node[portal] = []
        end
        push!(door2node[portal], other_v)
    end
    start_node = door2node["AA"][1]
    goal_node = door2node["ZZ"][1]

    portal2nodes = Dict{String, Tuple{Int, Int}}()
    for (portal, nodes) in door2node
        length(nodes) != 2 && continue
        portal2nodes[portal] = (nodes[1], nodes[2])
    end


    # need to remap vertices, theirs numbering is changed after removal
    start_node_small = 1
    goal_node_small = 2
    portal2nodes_small = Dict{String, Tuple{Int, Int}}()
    small2g = Dict(start_node_small=>start_node,goal_node_small=>goal_node)
    g2small = Dict(start_node=>start_node_small,goal_node=>goal_node_small)
    i = 3
    for (portal, nodes) in portal2nodes
        portal2nodes_small[portal] = (i, i+1)
        small2g[i] = nodes[1]
        small2g[i+1] = nodes[2]
        g2small[nodes[1]] = i
        g2small[nodes[2]] = i+1
        i += 2
    end

    small_g = MetaGraph(SimpleGraph(maximum(keys(small2g))), 1.)
    for v in vertices(small_g)
         set_prop!(small_g, v, :coords, get_prop(g, small2g[v], :coords))
    end
    dijkstra_shortest_paths(g, start_node).dists[collect(keys(g2small))]
    for (small_node, node) in small2g
        node2others = dijkstra_shortest_paths(g, node)
        for (small_other, other) in small2g
            edge_weight = node2others.dists[other]
            node == other && continue
            edge_weight == Inf && continue
            add_edge!(small_g, small_node, small_other)
            set_prop!(small_g, small_node, small_other, :weight, edge_weight - 2)
        end
    end
    middle = CartesianIndex(Int.(round.(size(data)./2)))
    small_g, start_node_small, goal_node_small, portal2nodes_small, middle
end

function build_graph(data)
    small_g, start_node_small, goal_node_small, portal2nodes_small, middle = build_base_graph(data)
    for (portal, (node1, node2)) in portal2nodes_small
        add_edge!(small_g, node1, node2)
        add_edge!(small_g, node2, node1)
    end

    small_g, start_node_small, goal_node_small
end

function build_graph_part_2(data)
    small_g, start_node_small, goal_node_small, portal2nodes_small, middle = build_base_graph(data)
    max_floors =  length(portal2nodes_small)

    small_g_len = nv(small_g)
    large_g = MetaGraph(SimpleGraph(small_g_len * max_floors), 1.)
    for level in 0:max_floors-1
        for edge in edges(small_g)
            src_node = edge.src+level*small_g_len
            dst_node = edge.dst+level*small_g_len
            add_edge!(large_g, src_node, dst_node)
            set_prop!(large_g, src_node, dst_node, :weight, get_prop(small_g, edge, :weight))
        end
    end
    
    thr = (Tuple(middle)./2).+4
    for level in 1:max_floors-1
        for (portal, (node1, node2)) in portal2nodes_small
            level_in = (level-1)*small_g_len
            level_out = level*small_g_len
            in1 = minimum(abs.(Tuple(get_prop(small_g, node1, :coords)-middle)) .< thr)
            in2 = minimum(abs.(Tuple(get_prop(small_g, node2, :coords)-middle)) .< thr)
            @assert in1 != in2 "same side, wtf, $in1, $in2, $node1, $node2, $(get_prop(small_g, node1, :coords)), $(get_prop(small_g, node2, :coords)), $(Tuple(get_prop(small_g, node1, :coords)-middle)), $(Tuple(get_prop(small_g, node2, :coords)-middle))"
            level_1 = in1 ? level_in : level_out
            level_2 = in2 ? level_in : level_out
            add_edge!(large_g, node1 + level_1, node2 + level_2)
            add_edge!(large_g, node2 + level_2, node1 + level_1)
        end
    end

    large_g, start_node_small, goal_node_small
end

function part1()
    g, start_node, goal_node = build_graph(data)
    Int(dijkstra_shortest_paths(g, start_node).dists[goal_node])
end

function part2()
    g, start_node, goal_node = build_graph_part_2(data)
    Int(dijkstra_shortest_paths(g, start_node).dists[goal_node])
end

using BenchmarkTools
println(part1())
@btime part1()
submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
