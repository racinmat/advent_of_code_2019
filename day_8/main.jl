using DrWatson
quickactivate(@__DIR__)
using Images
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = read_input(cur_day) |> x->split(x, "") |> x->parse.(Int, x) |> x->reshape(x, (25, 6, :))

function part1()
    mxval, mxindx = findmin(sum(data .== 0, dims=[1, 2]))
    sum(data[:, :, mxindx[3]] .== 1) * sum(data[:, :, mxindx[3]] .== 2)
end

function part2()
    mxval, mxindx = findmax(data .< 2, dims=3)
    res_matrix = data[mxindx]
    save("day-8-img.png", colorview(Gray, convert.(Float64, res_matrix[:, :, 1])))
end

println(part1())
# submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
