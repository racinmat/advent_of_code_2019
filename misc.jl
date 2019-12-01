using DrWatson
quickactivate(@__DIR__)
using Pkg

if Sys.iswindows()
	python_installation = read(`where python`, String) |> split |> x->x[1]
	ENV["PYTHON"] = python_installation
	Pkg.build("PyCall")
elseif Sys.islinux()
	python_installation = read(`which python`, String) |> split |> x->x[1]
	ENV["PYTHON"] = python_installation
	Pkg.build("PyCall")
end

using PyCall

function read_input(day::Int)
	misc = pyimport("misc")
	misc.read_day(day)
end

function submit(answer, day::Int, part::Int)
	misc = pyimport("misc")
	misc.submit_day(answer, day, part)
end
