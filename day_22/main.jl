using DrWatson
quickactivate(@__DIR__)
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->split(x, '\n')

row = data[1]

function cut_deck(deck, i)
    if i > 0
        return vcat(deck[i+1:end], deck[1:i])
    else
        return vcat(deck[end+i+1:end], deck[1:end+i])
    end
end

function deal_new_stack(deck)
    reverse(deck)
end

function deal_increment(deck, i)
    new_deck = copy(deck)
    iter = 1
    for num in deck
        new_deck[iter] = num
        iter += i
        iter = iter > length(deck) ? iter % length(deck) : iter
    end
    new_deck
end

function process_instruction(deck, row)
    if match(r"cut -?\d+", row) != nothing
        return cut_deck(deck, parse(Int, match(r"cut (-?\d+)", row)[1]))
    elseif match(r"deal into new stack", row) != nothing
        return deal_new_stack(deck)
    elseif match(r"deal with increment \d+", row) != nothing
        return deal_increment(deck, parse(Int, match(r"deal with increment (\d+)", row)[1]))
    else
        println("unknown")
    end
    # todo: implement me
end

function part1()
    deck = collect(0:10006)
    for row in data
        deck = process_instruction(deck, row)
    end
    findfirst(x->x==2019, deck)-1
end

function part2()
    deck = collect(0:10006)
    for row in data
        deck = process_instruction(deck, row)
    end
    findfirst(x->x==2019, deck)-1
end

using BenchmarkTools
#1685 is too low
#4127 is too low
println(part1())
@btime part1()
submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
