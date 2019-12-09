
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

function run_program!(arr, in_channel::Channel, out_channel::Channel)
    i = 1
    jump = 4
    while arr[i] != 99
        inst, m1, m2, m3 = parse_inst(arr[i])
        op(arr, j, m) = m == 1 ? arr[j] : arr[arr[j]+1]
        if inst == 1
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
            arr[arr[i+1]+1] = take!(in_channel)
            println("taking from in channel, value $(arr[arr[i+1]+1])")
            jump = i+2
        elseif inst == 4
            operand1 = op(arr, i+1, m1)
            println("putting to out channel, value $operand1")
            put!(out_channel, operand1)
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
    end
end

function run_program!(arr, input::Int)
    channel_in = Channel(1)
    channel_out = Channel(Inf)
    put!(channel_in, input)
    program = @async run_program!(arr, channel_in, channel_out)
    val = take!(channel_out)
    while val == 0
        val = take!(channel_out)
    end
    val
end

function run_program!(arr)
    channel_in = Channel()
    channel_out = Channel()
    program = run_program!(arr, channel_in, channel_out)
end
