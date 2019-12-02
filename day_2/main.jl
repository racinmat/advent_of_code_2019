using DrWatson
quickactivate(@__DIR__)
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->read_numbers(x, ',')
# data = cur_day |> test_input |> x->read_numbers(x, ',')

function run_program(arr)
    i = 1
    while arr[i] != 99
        if arr[i] == 1
            arr[arr[i+3]+1] = arr[arr[i+1]+1] + arr[arr[i+2]+1]
        elseif arr[i] == 2
            arr[arr[i+3]+1] = arr[arr[i+1]+1] * arr[arr[i+2]+1]
        else
            throw("fuck it")
        end
        i += 4
    end
    arr[1]
end

function part1()
    arr = copy(data)
    arr[2] = 12
    arr[3] = 2
    run_program(arr)
end

function part2()
    for (i, j) in Iterators.product(0:99, 0:99)
        arr = copy(data)
        arr[2] = i
        arr[3] = j
        res = run_program(arr)
        if res == 19690720
            return 100 * arr[2] + arr[3]
        end
    end
end

println(part1())
#submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
