
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
    rel_base = 0
    arr = cat(arr, zeros(Int, 1000), dims=1)
    while arr[i] != 99
        inst, m1, m2, m3 = parse_inst(arr[i])
        function op(arr, j, m)
            if m == 2
                return arr[arr[j]+1+rel_base]
            elseif m == 1
                return arr[j]
            else
                return arr[arr[j]+1]
            end
        end
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
            jump = i+2
        elseif inst == 4
            operand1 = op(arr, i+1, m1)
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
        elseif inst == 9
            operand1 = op(arr, i+1, m1)
            rel_base += operand1
            jump = i+2
        else
            throw("unknown instruction: $inst on step $i")
        end
        i = jump
    end
    arr
end

function run_program!(arr, input_val::Int)
    channel_in = Channel(1)
    channel_out = Channel(Inf)
    put!(channel_in, input_val)
    arr = run_program!(arr, channel_in, channel_out)
    val = take!(channel_out)
    while val == 0
        val = take!(channel_out)
    end
    val
end

function run_program_last_out!(arr, input_val::Int)
    channel_in = Channel(1)
    channel_out = Channel(Inf)
    put!(channel_in, input_val)
    arr = run_program!(arr, channel_in, channel_out)
    !isready(channel_out) && return nothing
    val = 0
    while isready(channel_out)
        val = take!(channel_out)
    end
    val
end

function run_program_all_out!(arr, input_val::Int)
    channel_in = Channel(1)
    channel_out = Channel(Inf)
    put!(channel_in, input_val)
    arr = run_program!(arr, channel_in, channel_out)
    !isready(channel_out) && return nothing
    out_vals = Vector{Int}()
    while isready(channel_out)
        push!(out_vals, take!(channel_out))
    end
    out_vals
end

function run_program!(arr)
    channel_in = Channel()
    channel_out = Channel(Inf)
    arr = run_program!(arr, channel_in, channel_out)
    isready(channel_out) && take!(channel_out)
end

function run_program_last_out!(arr)
    channel_in = Channel()
    channel_out = Channel(Inf)
    arr = run_program!(arr, channel_in, channel_out)
    !isready(channel_out) && return nothing
    val = 0
    while isready(channel_out)
        val = take!(channel_out)
    end
    val
end

function run_program_all_out!(arr)
    channel_in = Channel()
    channel_out = Channel(Inf)
    arr = run_program!(arr, channel_in, channel_out)
    !isready(channel_out) && return nothing
    out_vals = Vector{Int}()
    while isready(channel_out)
        push!(out_vals, take!(channel_out))
    end
    out_vals
end
