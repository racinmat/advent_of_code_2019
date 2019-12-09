using DrWatson
quickactivate(@__DIR__)
include(projectdir("misc.jl"))
include(projectdir("interpret.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->read_numbers(x, ',')
# data = cur_day |> test_input |> x->read_numbers(x, ',')

function part1()
    run_program!(copy(data), 1)
end

function part2()
    run_program!(copy(data), 5)
end

using BenchmarkTools

println(part1())
@btime part1()
#submit(part1(), cur_day, 1)
println(part2())
@btime part2()
submit(part2(), cur_day, 2)

run_program("3,9,8,9,10,9,4,9,99,-1,8" |> x->read_numbers(x, ','), 7) == 0
run_program("3,9,8,9,10,9,4,9,99,-1,8" |> x->read_numbers(x, ','), 8) == 1
run_program("3,9,8,9,10,9,4,9,99,-1,8" |> x->read_numbers(x, ','), 9) == 0
run_program("3,9,7,9,10,9,4,9,99,-1,8" |> x->read_numbers(x, ','), 7) == 1
run_program("3,9,7,9,10,9,4,9,99,-1,8" |> x->read_numbers(x, ','), 8) == 0
run_program("3,9,7,9,10,9,4,9,99,-1,8" |> x->read_numbers(x, ','), 9) == 0
run_program("3,3,1108,-1,8,3,4,3,99" |> x->read_numbers(x, ','), 7) == 0
run_program("3,3,1108,-1,8,3,4,3,99" |> x->read_numbers(x, ','), 8) == 1
run_program("3,3,1108,-1,8,3,4,3,99" |> x->read_numbers(x, ','), 9) == 0
run_program("3,3,1107,-1,8,3,4,3,99" |> x->read_numbers(x, ','), 7) == 1
run_program("3,3,1107,-1,8,3,4,3,99" |> x->read_numbers(x, ','), 8) == 0
run_program("3,3,1107,-1,8,3,4,3,99" |> x->read_numbers(x, ','), 9) == 0

run_program("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9" |> x->read_numbers(x, ','), -1) == 1
run_program("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9" |> x->read_numbers(x, ','), 0) == 0
run_program("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9" |> x->read_numbers(x, ','), 1) == 1

run_program("3,3,1105,-1,9,1101,0,0,12,4,12,99,1" |> x->read_numbers(x, ','), -1) == 1
run_program("3,3,1105,-1,9,1101,0,0,12,4,12,99,1" |> x->read_numbers(x, ','), 0) == 0
run_program("3,3,1105,-1,9,1101,0,0,12,4,12,99,1" |> x->read_numbers(x, ','), 1) == 1

run_program("3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99" |> x->read_numbers(x, ','), 7) == 999
run_program("3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99" |> x->read_numbers(x, ','), 8) == 1000
run_program("3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99" |> x->read_numbers(x, ','), 9) == 1001
