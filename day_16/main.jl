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
        return abs(sum(data[multiplier:(multiplier * 2 - 1)]) % 10)
    else
        # in the second half, the only coefficients after padding are 1, simple summing should do
        return abs(sum(data[multiplier:end]) % 10)
    end
end

function fourier(data, offset::Int=1)
    arr_half = length(data) ÷ 2
    part_0_data = zeros(Int, offset-1)
    if offset <= arr_half
        part_1_data = [fourier_line(data, i) for i in offset:arr_half]
        last_val = data[end]
        part_2_data = zeros(Int, arr_half)
        part_2_data[end] = last_val
        @inbounds for (i, j) in enumerate(length(data)-1:-1:(length(data) ÷ 2 + 1))
            partial_sum = abs((last_val + data[j]) % 10)
            part_2_data[arr_half - i] = partial_sum
            last_val = partial_sum
        end
        return vcat(part_0_data, part_1_data, part_2_data)
    else
        start_idx = offset - arr_half
        last_val = data[end]
        part_2_data_len = length(data) - offset + 1
        part_2_data = zeros(Int, part_2_data_len)
        part_2_data[end] = last_val
        @inbounds for (i, j) in enumerate(length(data)-1:-1:length(data)-part_2_data_len+1)
            partial_sum = abs((last_val + data[j]) % 10)
            part_2_data[part_2_data_len - i] = partial_sum
            last_val = partial_sum
        end
        return vcat(part_0_data, part_2_data)
    end
end

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

println(part1())
@btime part1()
# submit(part1(), cur_day, 1)
println(part2())
@btime part2()
submit(part2(), cur_day, 2)
