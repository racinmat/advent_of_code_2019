using DrWatson
quickactivate(@__DIR__)
using LightGraphs, MetaGraphs
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
# data = cur_day |> read_input |> x->split(x, '\n') .|> collect |>
#     x->hcat(x...) |> x->permutedims(x, [2, 1])
data = cur_day |> test_input |> x->split(x, '\n') .|> collect |>
    x->hcat(x...) |> x->permutedims(x, [2, 1])

function build_graph(data)
    g = LightGraphs.SimpleGraphs.grid(data |> size |> collect)
    g = MetaGraph(g)
    letter2node = Dict{Char, Int}()
    portal2node = Dict{String, Int}()
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
            letter2node[data[coords]] = vertex
        end
    end

    [(letter, neighbors(g, vertex)) for (letter, vertex) in letter2node]
    [(letter, get_prop(g, v, :coords), data[get_prop(g, v, :coords)]) for (letter, vertex) in letter2node  for v in neighbors(g, vertex)]
    [(letter, degree(g, vertex)) for (letter, vertex) in letter2node]
    for (letter, vertex) in letter2node
        degree(g, vertex) != 1 && continue
        v_coords = get_prop(g, vertex, :coords)
        other_v = first(neighbors(g, vertex))
        other_v_coords = get_prop(g, other_v, :coords)
        other_letter = data[other_v_coords]
        if sum(Tuple(v_coords)) < sum(Tuple(other_v_coords))
            portal = letter * other_letter
        else
            portal = letter * other_letter
        end
        portal2node[portal] = vertex
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

function part1()
    data
end

function part2()
    data
end

println(part1())
submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
