using DrWatson
quickactivate(@__DIR__)
using Combinatorics
include(projectdir("misc.jl"))
include(projectdir("interpret.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->read_numbers(x, ',')
data = cur_day |> test_input |> x->read_numbers(x, ',')

function run_sequence(data, seq)
    channels = [Channel(2) for i in 1:5]
    put!.(channels, seq)
    put!(channels[1], 0)
    programs = [@async run_program!(copy(data), channels[i], channels[i == 5 ? 1 : i+1]) for i in 1:5]
    wait.(programs)
    take!(channels[1])
end

function part1()
    maximum(run_sequence(data, seq) for seq in permutations(0:4))
end

function part2()
    maximum(run_sequence(data, seq) for seq in permutations(5:9))
end


println(part1())
# submit(part1(), cur_day, 1)
println(part2())
# submit(part2(), cur_day, 2)

run_sequence("3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0" |> x->read_numbers(x, ','), [4, 3, 2, 1, 0])
run_sequence("3,23,3,24,1002,24,10,24,1002,23,-1,23,101,5,23,23,1,24,23,23,4,23,99,0,0" |> x->read_numbers(x, ','), [0, 1, 2, 3, 4])
run_sequence("3,31,3,32,1002,32,10,32,1001,31,-2,31,1007,31,0,33,1002,33,7,33,1,33,31,31,1,32,31,31,4,31,99,0,0,0" |> x->read_numbers(x, ','), [1, 0, 4, 3, 2])

run_loop("3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5" |> x->read_numbers(x, ','), [9, 8, 7, 6, 5])

seq = [4, 3, 2, 1, 0]
