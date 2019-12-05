using DrWatson
quickactivate(@__DIR__)
include(projectdir("misc.jl"))

cur_day = parse(Int, splitdir(@__DIR__)[end][5:end])
data = cur_day |> read_input |> x->read_numbers(x, ',')
# data = cur_day |> test_input |> x->read_numbers(x, ',')

function parse_inst(inst)
    nums = inst |> digits |> reverse
    instruction = inst % 100
    if length(nums) == 1
        mode3 = mode2 = mode1 = 0
    elseif length(nums) == 2
        mode3 = mode2 = mode1 = 0
    elseif length(nums) == 3
        mode1 = nums[1]
        mode3 = mode2 = 0
    elseif length(nums) == 4
        mode2, mode1 = nums[1:end-2]
        mode3 = 0
    elseif length(nums) > 4
        mode3, mode2, mode1 = nums[1:end-2]
    end
    instruction, mode1, mode2, mode3
end

function run_program(arr, in_var)
    out_var = 0
    i = 1
    jump = 4
    while arr[i] != 99
        inst, m1, m2, m3 = parse_inst(arr[i])
        op(arr, j, m) = m == 1 ? arr[j] : arr[arr[j]+1]
        if inst == 1
            if arr[i+1] == -1553
                println(i)
            end
            operand1 = op(arr, i+1, m1)
            operand2 = op(arr, i+2, m2)
            arr[arr[i+3]+1] = operand1 + operand2
            jump = i+4
        elseif inst == 2
            operand1 = op(arr, i+1, m1)
            operand2 = op(arr, i+2, m2)
            arr[arr[i+3]+1] = operand1 * operand2
            jump = i+4
        elseif inst == 3
            arr[arr[i+1]+1] = in_var
            jump = i+2
        elseif inst == 4
            operand1 = op(arr, i+1, m1)
            out_var = operand1
            jump = i+2
        elseif inst == 5
            operand1 = op(arr, i+1, m1)
            operand2 = op(arr, i+2, m2)
            if operand1 != 0
                jump = operand2+1
            else
                jump = i+3
            end
        elseif inst == 6
            operand1 = op(arr, i+1, m1)
            operand2 = op(arr, i+2, m2)
            if operand1 == 0
                jump = operand2+1
            else
                jump = i+3
            end
        elseif inst == 7
            operand1 = op(arr, i+1, m1)
            operand2 = op(arr, i+2, m2)
            arr[arr[i+3]+1] = operand1 < operand2 ? 1 : 0
            jump = i+4
        elseif inst == 8
            operand1 = op(arr, i+1, m1)
            operand2 = op(arr, i+2, m2)
            arr[arr[i+3]+1] = operand1 == operand2 ? 1 : 0
            jump = i+4
        else
            throw("unknown instruction: $inst on step $i")
        end
        i = jump
        # println(arr)
    end
    out_var
end

function part1()
    run_program(copy(data), 1)
end

function part2()
    run_program(copy(data), 5)
end

using BenchmarkTools

println(part1())
@btime part1()
#submit(part1(), cur_day, 1)
println(part2())
@btime part2()
submit(part2(), cur_day, 2)

run_program("3,9,8,9,10,9,4,9,99,-1,8" |> x->read_numbers(x, ','), 7) == 0
run_program("3,9,8,9,10,9,4,9,99,-1,8" |> x->read_numbers(x, ','), 8) == 1
run_program("3,9,8,9,10,9,4,9,99,-1,8" |> x->read_numbers(x, ','), 9) == 0
run_program("3,9,7,9,10,9,4,9,99,-1,8" |> x->read_numbers(x, ','), 7) == 1
run_program("3,9,7,9,10,9,4,9,99,-1,8" |> x->read_numbers(x, ','), 8) == 0
run_program("3,9,7,9,10,9,4,9,99,-1,8" |> x->read_numbers(x, ','), 9) == 0
run_program("3,3,1108,-1,8,3,4,3,99" |> x->read_numbers(x, ','), 7) == 0
run_program("3,3,1108,-1,8,3,4,3,99" |> x->read_numbers(x, ','), 8) == 1
run_program("3,3,1108,-1,8,3,4,3,99" |> x->read_numbers(x, ','), 9) == 0
run_program("3,3,1107,-1,8,3,4,3,99" |> x->read_numbers(x, ','), 7) == 1
run_program("3,3,1107,-1,8,3,4,3,99" |> x->read_numbers(x, ','), 8) == 0
run_program("3,3,1107,-1,8,3,4,3,99" |> x->read_numbers(x, ','), 9) == 0

run_program("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9" |> x->read_numbers(x, ','), -1) == 1
run_program("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9" |> x->read_numbers(x, ','), 0) == 0
run_program("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9" |> x->read_numbers(x, ','), 1) == 1

run_program("3,3,1105,-1,9,1101,0,0,12,4,12,99,1" |> x->read_numbers(x, ','), -1) == 1
run_program("3,3,1105,-1,9,1101,0,0,12,4,12,99,1" |> x->read_numbers(x, ','), 0) == 0
run_program("3,3,1105,-1,9,1101,0,0,12,4,12,99,1" |> x->read_numbers(x, ','), 1) == 1

run_program("3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99" |> x->read_numbers(x, ','), 7) == 999
run_program("3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99" |> x->read_numbers(x, ','), 8) == 1000
run_program("3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99" |> x->read_numbers(x, ','), 9) == 1001
