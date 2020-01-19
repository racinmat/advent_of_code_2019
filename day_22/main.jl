using DrWatson
quickactivate(@__DIR__)
using TimerOutputs
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->split(x, '\n')

function cut_deck!(deck, i)
    if i > 0
        deck[1:end-i], deck[end-i+1:end] = deck[i+1:end], deck[1:i]
    else
        deck[1:-i], deck[-i+1:end] = deck[end+i+1:end], deck[1:end+i]
    end
    deck
end

function deal_new_stack!(deck)
    reverse!(deck)
end

function deal_increment!(deck, i)
    temp_deck = copy(deck)
    deck_len = length(deck)
    iter = 1
    for num in temp_deck
        deck[iter] = num
        iter += i
        iter = iter > deck_len ? iter % deck_len : iter
    end
    deck
end

function process_instruction!(deck, row)
    if match(r"cut -?\d+", row) != nothing
        @timeit to "cut_deck" return cut_deck!(deck, parse(Int, match(r"cut (-?\d+)", row)[1]))
    elseif match(r"deal into new stack", row) != nothing
        @timeit to "deal_new_stack" return deal_new_stack!(deck)
    elseif match(r"deal with increment \d+", row) != nothing
        @timeit to "deal_increment" return deal_increment!(deck, parse(Int, match(r"deal with increment (\d+)", row)[1]))
    else
        println("unknown")
    end
end

function part1()
    deck = collect(0:10006)
    for row in data
        deck = process_instruction!(deck, row)
    end
    findfirst(x->x==2019, deck)-1
end

function part11()
    deck = collect(0:10006)
    for i in 1:1000
        for row in data
            deck = process_instruction!(deck, row)
        end
    end
    findfirst(x->x==2019, deck)-1
end

function part2()
    deck = collect(0:119315717514046)
    for i in 1:101741582076661
        for row in data
            deck = process_instruction(deck, row)
        end
    end
    findfirst(x->x==2019, deck)-1
end

using BenchmarkTools

to = TimerOutput()
println(part1())
display(to)

to = TimerOutput()
println(part11())
display(to)

@btime part1()
submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
