bench:
	julia --project=./benchmark benchmark/fibonacci.jl

build:
	julia --project=./compile compile/compile.jl
	ln -s build/bin/monkey .

clean:
	rm -rf build monkey
