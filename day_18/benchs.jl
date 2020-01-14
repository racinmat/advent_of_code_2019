using DrWatson
quickactivate(@__DIR__)
using LightGraphs, Combinatorics, TimerOutputs, MetaGraphs, Logging, DataStructures, SimpleWeightedGraphs, Dates
include(projectdir("misc.jl"))
include(projectdir("day_18", "main.jl"))

my_debug_logger = ConsoleLogger(open("output_input_to_o_orig.log", "w+"), Logging.Debug, meta_formatter=simple_fmt, show_limited=true, right_justify=120)

with_logger(my_debug_logger) do
    astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
end

my_debug_logger = ConsoleLogger(open("output_input_to_o_new.log", "w+"), Logging.Debug, meta_formatter=simple_fmt, show_limited=true, right_justify=120)

with_logger(my_debug_logger) do
    astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)
end

to = TimerOutput()
astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
display(to)

to = TimerOutput()
astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)
display(to)

to = TimerOutput()
astar(g, start_poses, key2node, door2neighbors, door2node)
display(to)

#testing
data = read_file(cur_day, "test_input_44.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 44
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 44
# 1.077 ms (9546 allocations: 682.23 KiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "test_input_60.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 60
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 60
# 4.720 ms (39755 allocations: 2.57 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "test_input_72.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 72
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 72
# 20.894 ms (160216 allocations: 10.33 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "test_input_76.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 76
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 76
# 62.721 ms (437752 allocations: 27.47 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "test_input_81.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 81
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 81
# 12.219 ms (98127 allocations: 6.04 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "test_input_86.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 86
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 86
# 130.116 ms (815637 allocations: 50.09 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "test_input_102.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 102
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 102
# 982.014 ms (5477406 allocations: 340.61 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
# 1.199 s (6274355 allocations: 364.47 MiB)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "test_input_132.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 132
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 132
# 1.189 ms (10143 allocations: 801.34 KiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "test_input_136.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 136
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 136
# 10.355 s (44466044 allocations: 2.60 GiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
# 4.986 s (18345195 allocations: 1.00 GiB)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "input_to_d.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 1162
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 1162
# 1.939 s (45467 allocations: 291.79 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
# 913.501 μs (5267 allocations: 416.94 KiB)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "input_to_h.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 1616
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 1616
# 1.765 s (283428 allocations: 323.14 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
# 7.613 ms (44084 allocations: 3.57 MiB)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

# todo: I found a bug that same (have keys, cur pos) nodes, but all of them are explored, the longer is not cut
data = read_file(cur_day, "input_to_i.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 1696
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 1696
# 1.802 s (434369 allocations: 341.65 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
# 12.399 ms (70630 allocations: 5.97 MiB)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "input_to_j.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 2572
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 2572
# 2.129 s (548312 allocations: 370.33 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
# 39.375 ms (214761 allocations: 14.64 MiB)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "input_to_l.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 3628
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 3628
# 1.928 s (174271 allocations: 312.62 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
# 15.403 ms (83643 allocations: 5.87 MiB)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "input_to_n.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 3656
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 3656
# 2.877 s (2616988 allocations: 577.06 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
# 54.462 ms (281233 allocations: 18.78 MiB)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "input_to_o.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 3764
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 3764
# 2.005 s (919923 allocations: 417.43 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
# 169.934 ms (879667 allocations: 52.68 MiB)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "input_to_p.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 3764
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 3764
# 2.005 s (919923 allocations: 417.43 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
# 169.934 ms (879667 allocations: 52.68 MiB)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "input_to_q.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 3848
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 3848
# 2.667 s (2581620 allocations: 582.86 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "input_to_u.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 4034
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 4034
# 2.667 s (2581620 allocations: 582.86 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "input.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 4042
g_2, key2node_2, door2node_2, door2neighbors_2, start_poses_2, full_graph_2 = build_graph_2(data)
@time astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2) == 4042
# 150.099 s (364478501 allocations: 25.58 GiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
# 25.15 s (355501363 allocations: 5.09 GiB)
@btime astar_2(g_2, start_poses_2[1], key2node_2, door2neighbors_2, door2node_2, full_graph_2)

data = read_file(cur_day, "test_input_24.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, graph2door, full_gs = build_graph_part_2(data)
@time astar(g, start_poses, key2node, door2neighbors, door2node, graph2door, full_gs) == 24
# 282.300 μs (3172 allocations: 181.84 KiB)
@btime astar(g, start_poses, key2node, door2neighbors, door2node, graph2door, full_gs)

data = read_file(cur_day, "input_to_h.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, graph2door, full_gs = build_graph_part_2(data)
@time astar(g, start_poses, key2node, door2neighbors, door2node, graph2door, full_gs) == 1136
# 217.700 ms (89814 allocations: 46.50 MiB)
@btime astar(g, start_poses, key2node, door2neighbors, door2node, graph2door, full_gs)

data = read_file(cur_day, "input_to_q.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, graph2door, full_gs = build_graph_part_2(data)
@time astar(g, start_poses, key2node, door2neighbors, door2node, graph2door, full_gs) == 1898
# 1.230 s (6872589 allocations: 413.36 MiB)
@btime astar(g, start_poses, key2node, door2neighbors, door2node, graph2door, full_gs)

data = read_file(cur_day, "input_to_u.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, graph2door, full_gs = build_graph_part_2(data)
@time astar(g, start_poses, key2node, door2neighbors, door2node, graph2door, full_gs) == 2006
# 41.071 s (212560860 allocations: 11.47 GiB)
@btime astar(g, start_poses, key2node, door2neighbors, door2node, graph2door, full_gs)

data = read_file(cur_day, "input.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 4042
# 2.046 s (280100 allocations: 322.94 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)



key2node_2
door2node_2
key2node_2['i']
key2node_2['a']
key2node_2['a']
weights(full_graph_2)[key2node_2['i'], 12]
weights(full_graph_2)[12, 18]
weights(full_graph_2)[18, 15]
weights(full_graph_2)[15, 5]
weights(full_graph_2)[5, 4]
neighbors(full_graph_2, key2node_2['i'])
neighbors(full_graph_2, 3)
neighbors(full_graph_2, 12)
neighbors(full_graph_2, key2node_2['a'])
neighbors(full_graph_2, 5)
neighbors(full_graph_2, 15)
neighbors(full_graph_2, 18)
neighbors(full_graph_2, 17)
dijkstra_shortest_paths(full_graph_2, key2node_2['i']).dists[key2node_2['a']]
