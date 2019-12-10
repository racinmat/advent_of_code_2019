using DrWatson
quickactivate(@__DIR__)
include(projectdir("misc.jl"))

using LightGraphs, MetaGraphs
using Base.Iterators: flatten

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
split_r = ")"
strip_r(x) = replace(x, "\r"=>"")
data = cur_day |> read_input |> strip_r |> rstrip |> x->split(x, '\n') .|> x->split(x, split_r)
# data = cur_day |> test_input |> strip_r |> rstrip |> x->split(x, '\n') .|> x->split(x, split_r)


function part1()
    nodes = data |> flatten |> unique
    g = DiGraph(length(nodes))
    int2name = nodes |> enumerate |> Dict
    name2int = Dict(v=>k for (k, v) in int2name)
    for (node1, node2) in data
        add_edge!(g, name2int[node1], name2int[node2])
    end
    toposorted = topological_sort_by_dfs(g)
    states = floyd_warshall_shortest_paths(g)
    tot_paths = (0 .< states.dists .< typemax(Int)) |> sum
    tot_paths
end

function part2()
    nodes = data |> flatten |> unique
    g = Graph(length(nodes))
    int2name = nodes |> enumerate |> Dict
    name2int = Dict(v=>k for (k, v) in int2name)
    for (node1, node2) in data
        add_edge!(g, name2int[node1], name2int[node2])
    end
    paths = dijkstra_shortest_paths(g, name2int["YOU"])
    paths.dists[paths.parents[name2int["SAN"]]] - 1
end

using BenchmarkTools

println(part1())
@btime part1()
#submit(part1(), cur_day, 1)
println(part2())
@btime part2()
# submit(part2(), cur_day, 2)
