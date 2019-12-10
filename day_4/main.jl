using DrWatson
quickactivate(@__DIR__)
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input
lower, upper = parse.(Int, split(data, '-'))

function part_1_cond(i::Int)::Bool
    same_digits = false
    rising = true
    i_digs = digits(i)
    for j in 2:6
        if i_digs[j] == i_digs[j-1]
            same_digits = true
        end
        if i_digs[j] > i_digs[j-1]
            rising = false
        end
    end
    same_digits && rising
end

function part1()
    tot = 0
    @inbounds for i in lower:upper
        if part_1_cond(i)
            tot += 1
        end
    end
    tot
end

function part_2_cond(i::Int)::Bool
    same_digits = false
    i_digs = digits(i)
    if @inbounds i_digs[1] == i_digs[2] != i_digs[3]
        same_digits = true
    elseif @inbounds i_digs[6] == i_digs[5] != i_digs[4]
        same_digits = true
    else
        @inbounds for j in 3:5
            if @inbounds i_digs[j+1] != i_digs[j] == i_digs[j-1] != i_digs[j-2]
                same_digits = true
            end
        end
    end

    rising = true
    @inbounds for j in 2:6
        if @inbounds i_digs[j] > i_digs[j-1]
            rising = false
            break
        end
    end
    same_digits && rising
end

function part2()
    tot = 0
    for i in lower:upper
        if part_2_cond(i)
            tot += 1
        end
    end
    tot
end

using BenchmarkTools

println(part1())
@btime part1()  # orig 85.300 ms (1847289 allocations: 84.56 MiB)
# submit(part1(), cur_day, 1)
println(part2())
@btime part2()  # orig 77.754 ms (1847289 allocations: 84.56 MiB)
# submit(part2(), cur_day, 2)
