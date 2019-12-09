using DrWatson
quickactivate(@__DIR__)
include(projectdir("misc.jl"))
include(projectdir("interpret.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->read_numbers(x, ',')

function part1()
    run_program_last_out!(copy(data), 1)
    run_program_all_out!(copy(data), 1)
end

function part2()
    data
end

println(part1())
submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)

arr = "109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99" |> x->read_numbers(x, ',')
arr = "104,1125899906842624,99" |> x->read_numbers(x, ',')
run_program!("109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99" |> x->read_numbers(x, ','))
run_program_all_out!("109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99" |> x->read_numbers(x, ','))
run_program_last_out!("109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99" |> x->read_numbers(x, ','))
run_program!("1102,34915192,34915192,7,4,7,99,0" |> x->read_numbers(x, ','))
run_program!("104,1125899906842624,99" |> x->read_numbers(x, ','))
