using DrWatson
quickactivate(@__DIR__)
include(projectdir("misc.jl"))
include(projectdir("interpret.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->read_numbers(x, ',')
# data = cur_day |> test_input |> x->read_numbers(x, ',')

function part1()
    arr = copy(data)
    arr[2] = 12
    arr[3] = 2
    arr = run_program!(arr)
    arr[1]
end

function part2()
    for (i, j) in Iterators.product(0:99, 0:99)
        arr = data
        arr[2], arr[3] = i, j
        arr = run_program!(arr)
        arr[1] == 19690720 && return 100 * arr[2] + arr[3]
    end
end

using BenchmarkTools

println(part1())
@btime part1()
#submit(part1(), cur_day, 1)
println(part2())
@btime part2()
# submit(part2(), cur_day, 2)
