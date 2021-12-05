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

inst2params(arr_len, i::CutInstruction) = ModuloParams(1, -i.i)
inst2params(arr_len, i::DealNewInstruction) = ModuloParams(-1, -1)
inst2params(arr_len, i::DealIncrementInstruction) = ModuloParams(i.i, 0)

inst2params_rev(arr_len, i::CutInstruction) = ModuloParams(1, i.i)
inst2params_rev(arr_len, i::DealNewInstruction) = ModuloParams(-1, -1)
inst2params_rev(arr_len, i::DealIncrementInstruction) = ModuloParams(invmod(i.i, arr_len), 0)

struct ModuloParams <: Instruction
    a::Signed
    b::Signed
end

process_instruction(card::Signed, arr_len, i::ModuloParams) = mod(i.a * card + i.b, arr_len)
merge_ops(m1, m2, arr_len) = ModuloParams(mod(m1.a*m2.a, arr_len), mod(m1.b*m2.a+m2.b, arr_len))

function merge_instructions(arr_len, instructions::Vector{ModuloParams})
    merged = ModuloParams(1, 0)
    for row in instructions
        merged = merge_ops(merged, row, arr_len)
    end
    merged
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

function part2()
    arr_size = 119_315_717_514_047
    # arr_size = 119_315_71
    # arr_size = 10_007
    instructions = reverse(parse_instruction.(data))
    modulo_params = inst2params_rev.(arr_size, instructions)
    card = 2_020
    instruction = merge_instructions(arr_size, modulo_params)
    n_inter = 101_741_582_076_661
    # n_inter = 82_076_661
    pm = powermod(instruction.a, n_inter, arr_size)
    c = mod(mod(pm - 1, arr_size) * invmod(instruction.a - 1, arr_size), arr_size)
    card = mod(pm * card + instruction.b * c, arr_size)
    card
end

using BenchmarkTools

println(part1())
@btime part1()
# submit(part1(), cur_day, 1)
println(part2())
@btime part2()
# submit(part2(), cur_day, 2)
