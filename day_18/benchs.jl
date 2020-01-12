using DrWatson
quickactivate(@__DIR__)
using LightGraphs, Combinatorics, TimerOutputs, MetaGraphs, Logging, DataStructures, SimpleWeightedGraphs, Dates
include(projectdir("misc.jl"))
include(projectdir("day_18", "main.jl"))

with_logger(my_debug_logger) do
    astar(g, start_pos, key2node, door2neighbors, door2node, full_graph)
end

to = TimerOutput()
astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)
display(to)

to = TimerOutput()
astar(g, start_poses, key2node, door2neighbors, door2node)
display(to)

#testing
data = read_file(cur_day, "test_input_44.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 44
# 1.077 ms (9546 allocations: 682.23 KiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "test_input_60.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 60
# 4.720 ms (39755 allocations: 2.57 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "test_input_72.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 72
# 20.894 ms (160216 allocations: 10.33 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "test_input_76.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 76
# 62.721 ms (437752 allocations: 27.47 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "test_input_81.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 81
# 12.219 ms (98127 allocations: 6.04 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "test_input_86.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 86
# 130.116 ms (815637 allocations: 50.09 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "test_input_102.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 102
# 882.543 ms (4497198 allocations: 275.63 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "test_input_132.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 132
# 1.189 ms (10143 allocations: 801.34 KiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "test_input_136.txt") |> x->rstrip(x, '\n') |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 136
# 10.355 s (44466044 allocations: 2.60 GiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "input_to_h.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 1616
# 2.046 s (280100 allocations: 322.94 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "input_to_q.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 3848
# 2.667 s (2581620 allocations: 582.86 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)

data = read_file(cur_day, "input_to_u.txt") |> x->split(x, '\n') .|> collect |> x->hcat(x...) |> x->permutedims(x, [2, 1])
g, key2node, door2node, door2neighbors, start_poses, vprops, full_graph = build_graph(data)
@time astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph) == 4034
# 2.667 s (2581620 allocations: 582.86 MiB)
@btime astar(g, start_poses[1], key2node, door2neighbors, door2node, full_graph)

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
