using DrWatson
quickactivate(@__DIR__)
using BenchmarkTools
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = read_input(cur_day)

function add_fuel(mass::Int)::Int
     mass ÷ 3 - 2
end

function part1()
    split(data, "\n") .|> (x->parse(Int, x) |> add_fuel) |> sum
end

function add_fuel_till_0(mass::Int)::Int
    fuel_mass = add_fuel(mass)
    tot_mass = 0
    while fuel_mass > 0
        tot_mass += fuel_mass
        fuel_mass = add_fuel(fuel_mass)
    end
    tot_mass
end

function part2()
    split(data, "\n") .|> (x->parse(Int, x) |> add_fuel_till_0) |> sum
end

println(part1())
@btime part1()
#submit(part1(), cur_day, 1)
println(part2())
@btime part2()
#submit(part2(), cur_day, 2)
