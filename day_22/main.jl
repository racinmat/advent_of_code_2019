using DrWatson
quickactivate(@__DIR__)
using TimerOutputs
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->split(x, '\n')

abstract type Instruction end
struct CutInstruction <: Instruction
    i::Signed
end
struct DealNewInstruction <: Instruction end
struct DealIncrementInstruction <: Instruction
    i::Signed
end

process_instruction(card::Signed, arr_len, i::CutInstruction) = mod(card - i.i, arr_len)
process_instruction(card::Signed, arr_len, i::DealNewInstruction) = arr_len - card - 1
process_instruction(card::Signed, arr_len, i::DealIncrementInstruction) = mod(card * i.i, arr_len)

process_instruction_rev(card::Signed, arr_len, i::CutInstruction) = mod(card + i.i, arr_len)
process_instruction_rev(card::Signed, arr_len, i::DealNewInstruction) = arr_len - card - 1
process_instruction_rev(card::Signed, arr_len, i::DealIncrementInstruction) = mod(invmod(i.i, arr_len) * card, arr_len)

struct ModuloParams <: Instruction
    a::Signed
    b::Signed
end

process_instruction(card::Signed, arr_len, i::ModuloParams) = mod(i.a * card + i.b, arr_len)

function merge_instructions(x, arr_len, instructions::Vector{Instruction})
    y = x
    println("x: $x, y: $y")
    for row in instructions
        y = process_instruction(y, arr_len, row)
    end
    z = y
    println("x: $x, y: $y, z: $z")
    for row in instructions
        z = process_instruction(z, arr_len, row)
    end
    println("x: $x, y: $y, z: $z")
    a = mod((y - z) * invmod(x - y, arr_len), arr_len)
    b = mod(y - a * x, arr_len)
    ModuloParams(a, b)
end

function merge_instructions_rev(x, arr_len, instructions::Vector{Instruction})
    y = x
    println("x: $x, y: $y")
    for row in instructions
        y = process_instruction_rev(y, arr_len, row)
    end
    z = y
    println("x: $x, y: $y, z: $z")
    for row in instructions
        z = process_instruction_rev(z, arr_len, row)
    end
    println("x: $x, y: $y, z: $z")
    a = mod((y - z) * invmod(x - y, arr_len), arr_len)
    b = mod(y - a * x, arr_len)
    ModuloParams(a, b)
end

function parse_instruction(row)
    if match(r"cut -?\d+", row) != nothing
        return CutInstruction(parse(Int128, match(r"cut (-?\d+)", row)[1]))
    elseif match(r"deal into new stack", row) != nothing
        return DealNewInstruction()
    elseif match(r"deal with increment \d+", row) != nothing
        return DealIncrementInstruction(parse(Int128, match(r"deal with increment (\d+)", row)[1]))
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

function part12()
    card = 2_019
    instructions = parse_instruction.(data)
    instruction = merge_instructions(card, 10_007, instructions)
    process_instruction(card, 10_007, instruction)
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

function part2()
    instructions = reverse(parse_instruction.(data))
    # card = 2_020
    card = 6978
    # for i in 1:101_741_582_076_661
    # for i in 1:76_661
        for row in instructions
            # card = process_instruction_rev(card, 119_315_717_514_047, row)
            # card = process_instruction_rev(card, 119_315_71, row)
            card = process_instruction_rev(card, 10_007, row)
        end
    # end
    card
end

function part21()
    instructions = reverse(parse_instruction.(data))
    # card = 2_020
    card = 6978
    # arr_size = 119_315_717_514_047
    # arr_size = 119_315_71
    arr_size = 10_007
    instruction = merge_instructions_rev(card, arr_size, instructions)
    # for i in 1:101_741_582_076_661
    card = 2_020
    card = process_instruction(card, arr_size, instruction)
    # for i in 1:76_661
    #     card = process_instruction(card, 119_315_717_514_047, instruction)
    # end
    card
end

using BenchmarkTools

to = TimerOutput()
part1()
part12()
display(to)

to = TimerOutput()
part2()
part21()
display(to)

@btime part1()
@btime part2()
@btime part21()
submit(part1(), cur_day, 1)
println(part2())
submit(part2(), cur_day, 2)
