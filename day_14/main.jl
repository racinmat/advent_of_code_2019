using DrWatson
quickactivate(@__DIR__)
using Base.Iterators: flatten
include(projectdir("misc.jl"))

matchall(r::Regex,s::AbstractString; overlap::Bool=false) = collect((m.match for m=eachmatch(r, s, overlap=overlap)))

function parse_row(str)
    m = matchall(r"(\d+ [A-Z]+)", str)
    res = [match(r"(\d+) ([A-Z]+)", i).captures for i in m]
    res = res .|> x->(parse(Int, x[1]), x[2])
    res[1:end-1], res[end]
end

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
# data = cur_day |> read_input |> x->split(x, '\n') .|> parse_row
data = cur_day |> test_input|> x->rstrip(x, '\n')  |> x->split(x, '\n') .|> parse_row

# todo: try to rewrite it to arrays, translate in the beginning and benchmark
# translating to arrays
materials = data |> x->getindex.(x, 2) |> x->getindex.(x, 2) |> unique
push!(materials, "ORE")
name2idx = Dict(name => idx for (idx, name) in enumerate(materials))

data_int = [([(i, name2idx[j]) for (i, j) in in_data], (out_data[1], name2idx[out_data[2]])) for (in_data, out_data) in data]

ingredients = Dict{String, Vector{String}}(key[2] => getindex.(vals, 2) for (vals, key) in data)
in_volumes = Dict{String, Vector{Int}}(key[2] => getindex.(vals, 1) for (vals, key) in data)
out_volumes = Dict{String, Int}(key[2] => key[1] for (vals, key) in data)

sort(collect(out_volumes), by=x->x[2])
Dict(key[2] => key[1] for (vals, key) in data_int)
Dict(key[2] => key[1] for (vals, key) in data_int)
[key[1] for (vals, key) in data_int]
values.(values(data_int))

ingredients_int = Dict(key[2] => getindex.(vals, 2) for (vals, key) in data_int) |> collect |> sort .|> x->x.second
in_volumes_int = Dict(key[2] => getindex.(vals, 1) for (vals, key) in data_int) |> collect |> sort .|> x->x.second
out_volumes_int = Dict(key[2] => key[1] for (vals, key) in data_int) |> collect |> sort .|> x->x.second

function calc_production!(required::Vector{Int}, produced::Vector{Int}, ingredients, in_volumes, out_volumes, material, amount)
    @inbounds required[material] += amount
    @inbounds if material == name2idx["ORE"]
        produced[material] += amount
        return
    end
    # todo: here could be probably some optimization, propagating I need to run sth e.g. 10 times
    in_stuff = ingredients[material]
    in_amounts = in_volumes[material]
    # daster heuristics
    @inbounds mults = (required[material] - produced[material]) ÷ out_volumes[material]
    if mults > 0
        for i in 1:length(in_stuff)
            calc_production!(required, produced, ingredients, in_volumes, out_volumes, in_stuff[i], in_amounts[i] * mults)
        end
        produced[material] += out_volumes[material] * mults
    end

    @inbounds while required[material] > produced[material]
        for i in 1:length(in_stuff)
            calc_production!(required, produced, ingredients, in_volumes, out_volumes, in_stuff[i], in_amounts[i])
        end
        produced[material] += out_volumes[material]
    end
end

function part1()
    required = zeros(Int, length(name2idx))
    produced = zeros(Int, length(name2idx))
    calc_production!(required, produced, ingredients_int, in_volumes_int, out_volumes_int, name2idx["FUEL"], 1)
    produced[name2idx["ORE"]]
end

function part2()
    required = zeros(Int, length(name2idx))
    produced = zeros(Int, length(name2idx))
    calc_production!(required, produced, ingredients_int, in_volumes_int, out_volumes_int, name2idx["FUEL"], 1)
    max_ore = 1_000_000_000_000
    lower_bound = max_ore ÷ produced[name2idx["ORE"]]
    calc_production!(required, produced, ingredients_int, in_volumes_int, out_volumes_int, name2idx["FUEL"], lower_bound)
    while produced[name2idx["ORE"]] <= max_ore
        calc_production!(required, produced, ingredients_int, in_volumes_int, out_volumes_int, name2idx["FUEL"], 1)
    end
    produced[name2idx["FUEL"]]
end

using BenchmarkTools

println(part1())
@btime part1()
# submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
