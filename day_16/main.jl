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
    if (multiplier * 3) <= length(data)
        base_pattern = [1,0,-1,0]
        return @inbounds abs(sum(base_pattern[mod_index(i, multiplier)]*data[i] for i in multiplier:length(data)) % 10)
    elseif (multiplier * 2) <= length(data)
        # in the second thirs, the only non-zero coefficient are 1, simple summing should do
        return abs(sum(data[multiplier:(multiplier * 2 -1)]) % 10)
    else
        # in the second half, the only coefficients after padding are 1, simple summing should do
        return abs(sum(data[multiplier:end]) % 10)
    end
end

fourier(data) = [fourier_line(data, i) for i in 1:length(data)]
fourier_2(data) = [fourier_line_2(data, i) for i in 1:length(data)]
fourier_2_time(data) = [@time fourier_line_2(data, i) for i in 1:length(data)]
fourier_2_part_1(data) = [fourier_line_2(data, i) for i in 1:(length(data) ÷ 2)]
fourier_2_part_2(data) = [fourier_line_2(data, i) for i in (length(data) ÷ 2):length(data)]

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
    offset = data[1:7] |> join |> x->parse(Int, x)
    for i in 1:100
        temp_data = fourier(temp_data, offset)
    end

    temp_data[offset+1:offset+8] |> join
end

using BenchmarkTools

length(temp_data)
length(temp_data) - offset
length(repeat(data, 100))
length(repeat(data, 1000))
(length(temp_data) - offset) / length(temp_data)

data_10 = repeat(data, 10)
@time fourier_2_part_1(data_10)
@time fourier_2_part_2(data_10)

fourier_2_time(data)
all(fourier(data) .== fourier_2(data))
@btime fourier(data)
@btime fourier_2(data)
@time fourier(repeat(data, 1))
@time fourier(repeat(data, 10))
@time fourier(repeat(data, 10), 1000)
@time fourier(repeat(data, 100))
@time fourier(repeat(data, 1000))
@btime fourier_2(data)
@time fourier_2(repeat(data, 1))
@time fourier_2(repeat(data, 10))
@time fourier_2(repeat(data, 100))

fourier(data)[100:end]
fourier(data)
fourier_2(data)

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
