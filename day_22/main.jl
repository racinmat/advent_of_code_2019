using DrWatson
quickactivate(@__DIR__)
using TimerOutputs
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->split(x, '\n')

cut_deck(card::Int, arr_len, i) = mod(card - i, arr_len)
deal_new_stack(card::Int, arr_len) = arr_len - card - 1
deal_increment(card::Int, arr_len, i) = mod(card * i, arr_len)
process_instruction(card::Int, arr_len, i::CutInstruction) = mod(card - i.i, arr_len)
process_instruction(card::Int, arr_len, i::DealNewInstruction) = arr_len - card - 1
process_instruction(card::Int, arr_len, i::DealIncrementInstruction) = mod(card * i.i, arr_len)

abstract type Instruction end
struct CutInstruction <: Instruction
    i::Int
end
struct DealNewInstruction <: Instruction end
struct DealIncrementInstruction <: Instruction
    i::Int
end

function parse_instruction(row)
    if match(r"cut -?\d+", row) != nothing
        return CutInstruction(parse(Int, match(r"cut (-?\d+)", row)[1]))
    elseif match(r"deal into new stack", row) != nothing
        return DealNewInstruction()
    elseif match(r"deal with increment \d+", row) != nothing
        return DealIncrementInstruction(parse(Int, match(r"deal with increment (\d+)", row)[1]))
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

function part12()
    card = 2019
    for row in data
        card = process_instruction(card, 10007, row)
    end
    card
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

function part112()
    card = 2019
    instructions = parse_instruction.(data)
    for i in 1:1000
        for row in instructions
            card = process_instruction(card, 10007, row)
        end
    end
    card
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
part1()
display(to)

to = TimerOutput()
part12()
display(to)

to = TimerOutput()
part11()
display(to)

to = TimerOutput()
part112()
display(to)

@btime part1()
@btime part12()
submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
