import os
import os.path as osp
for i in range(1, 26):
    os.makedirs(f'day_{i}', exist_ok=True)
    open(f'day_{i}/input.txt', 'w+').close()
    with open(f'day_{i}/main.jl', 'w+') as f:
        f.write("""using DrWatson
quickactivate(@__DIR__)
""")
