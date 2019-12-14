using DrWatson
quickactivate(@__DIR__)
include(projectdir("misc.jl"))

matchall(r::Regex,s::AbstractString; overlap::Bool=false) = collect((m.match for m=eachmatch(r, s, overlap=overlap)))

function parse_row(str)
    m = matchall(r"(\d+ [A-Z]+)", str)
    res = [match(r"(\d+) ([A-Z]+)", i).captures for i in m]
    res = res .|> x->(parse(Int, x[1]), x[2])
    res[1:end-1], res[end]
end

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
const data = cur_day |> read_input |> x->split(x, '\n') .|> parse_row
const data = cur_day |> test_input|> x->rstrip(x, '\n')  |> x->split(x, '\n') .|> parse_row

ingredients = Dict{String, Vector{String}}(key[2] => getindex.(vals, 2) for (vals, key) in data)
in_volumes = Dict{String, Vector{Int}}(key[2] => getindex.(vals, 1) for (vals, key) in data)
out_volumes = Dict{String, Int}(key[2] => key[1] for (vals, key) in data)

function calc_production!(required::Dict{String, Int}, produced::Dict{String, Int}, ingredients, in_volumes, out_volumes, material, amount)
    required[material] += amount
    if material == "ORE"
        produced[material] += amount
        return
    end
    while required[material] > produced[material]
        in_stuff = ingredients[material]
        in_amounts = in_volumes[material]
         @inbounds for (i_stuff, i_volume) in zip(in_stuff, in_amounts)
            calc_production!(required, produced, ingredients, in_volumes, out_volumes, i_stuff, i_volume)
        end
        produced[material] += out_volumes[material]
    end
end

function part1()
    required = Dict{String, Int}(key => 0 for key in keys(ingredients))
    produced = Dict{String, Int}(key => 0 for key in keys(ingredients))
    required["ORE"] = 0
    produced["ORE"] = 0
    calc_production!(required, produced, ingredients, in_volumes, out_volumes, "FUEL", 1)
    produced["ORE"]
end

function part2()
    required = Dict{String, Int}(key => 0 for key in keys(ingredients))
    produced = Dict{String, Int}(key => 0 for key in keys(ingredients))
    required["ORE"] = 0
    produced["ORE"] = 0
    calc_production!(required, produced, ingredients, in_volumes, out_volumes, "FUEL", 1)
    1_000_000_000_000 ÷ produced["ORE"]
end

using BenchmarkTools

println(part1())
@btime part1()
# submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
1000000000000 ÷ 13312
