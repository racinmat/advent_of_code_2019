using DrWatson
quickactivate(@__DIR__)
using TimerOutputs
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->split(x, '\n')

abstract type Instruction end
struct CutInstruction <: Instruction
    i::Int
end
struct DealNewInstruction <: Instruction end
struct DealIncrementInstruction <: Instruction
    i::Int
end

process_instruction(card::Int, arr_len, i::CutInstruction) = mod(card - i.i, arr_len)
process_instruction(card::Int, arr_len, i::DealNewInstruction) = arr_len - card - 1
process_instruction(card::Int, arr_len, i::DealIncrementInstruction) = mod(card * i.i, arr_len)

process_instruction_rev(card::Int, arr_len, i::CutInstruction) = mod(card + i.i, arr_len)
process_instruction_rev(card::Int, arr_len, i::DealNewInstruction) = arr_len - card - 1
process_instruction_rev(card::Int, arr_len, i::DealIncrementInstruction) = mod(invmod(i.i, arr_len) * card, arr_len)

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
    card = 2_019
    instructions = parse_instruction.(data)
    for row in instructions
        card = process_instruction(card, 10_007, row)
    end
    card
end

function part2()
    card = 2_020
    instructions = reverse(parse_instruction.(data))
    for i in 1:101_741_582_076_661
        for row in instructions
            card = process_instruction_rev(card, 119_315_717_514_047, row)
        end
    end
    card
end

function exec_instructions(instructions::Vector{Union{Instruction}})
    card = 2_020
    # for i in 1:101_741_582_076_661
    for i in 1:76_661
        for row in instructions
            card = process_instruction_rev(card, 119_315_717_514_047, row)
        end
    end
    card
end

function part2()
    instructions = reverse(parse_instruction.(data))
    exec_instructions(instructions)
end

using BenchmarkTools

to = TimerOutput()
part1()
display(to)

to = TimerOutput()
part2()
display(to)

@btime part1()
@btime part2()
submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
