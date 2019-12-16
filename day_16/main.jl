using DrWatson
quickactivate(@__DIR__)
using ThreadTools
using Base.Iterators: flatten
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> collect .|> x->parse(Int, x)
# data = cur_day |> test_input |> x->rstrip(x, '\n') |> collect .|> x->parse(Int, x)

# data = "12345678" |> x->rstrip(x, '\n') |> collect .|> x->parse(Int, x)
# data = "80871224585914546619083218645595" |> x->rstrip(x, '\n') |> collect .|> x->parse(Int, x)
function mod_index(i::Int, mod_i::Int)::Int
    mod_idx = (i ÷ mod_i) % 4
    mod_idx == 0 ? 4 : mod_idx
end

function fourier_line(data::Vector{Int}, multiplier::Int)::Int
    base_pattern = [1,0,-1,0]
    @inbounds abs(sum(base_pattern[mod_index(i, multiplier)]*data[i] for i in multiplier:length(data)) % 10)
end

fourier(data) = [fourier_line(data, i) for i in 1:length(data)]

function part1()
    temp_data = copy(data)
    for i in 1:100
        temp_data = fourier(temp_data)
    end
    temp_data[1:8] |> join
end

function part12()
    temp_data = copy(data)
    for i in 1:100
        temp_data = fourier(temp_data)
    end
    temp_data[1:8] |> join
end

function part2()
    temp_data = repeat(data, 10000)
    for i in 1:100
        temp_data = fourier(temp_data)
    end
    offset = data[1:7] |> join |> x->parse(Int, x)
    temp_data[offset+1:offset+8] |> join
end

using BenchmarkTools

@btime fourier(data)
@time fourier(repeat(data, 10))
@time fourier(repeat(data, 100))
@btime fourier_2(data)
@time fourier_2(repeat(data, 10))
@time fourier_2(repeat(data, 100))

@time fourier(repeat(data, 100))
@btime fourier_2(data)
@btime fourier_3(data)
fourier(data)
fourier_2(data)
all(fourier(data) .== fourier_2(data))
@time fourier(temp_data)

println(part1())
@btime part1()
# submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
