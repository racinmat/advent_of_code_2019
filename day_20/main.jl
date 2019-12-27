using DrWatson
quickactivate(@__DIR__)
using LightGraphs, MetaGraphs
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->split(x, '\n') .|> collect |>
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
