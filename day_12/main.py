import itertools
import re
import timeit

import numpy as np
from numba import jit

import misc


def parse_row(str):
    m = re.match(r"<x=(-?[0-9]+), y=(-?[0-9]+), z=(-?[0-9]+)>", str)
    return np.array([int(m.group(1)), int(m.group(2)), int(m.group(3))])


data = [parse_row(i) for i in misc.read_day(12).split('\n')]


@jit(nopython=True)
def iteration(positions, velocities, combs):
    for (idx1, idx2) in combs:
        velocities[idx1, :] += np.sign(positions[idx2, :] - positions[idx1, :])
        velocities[idx2, :] += np.sign(positions[idx1, :] - positions[idx2, :])

    positions += velocities


def part1():
    positions = np.array(data, dtype=np.int32)
    velocities = np.zeros_like(positions, dtype=np.int32)
    combs = list(itertools.combinations(range(len(positions)), 2))
    for i in range(1000):
        iteration(positions, velocities, combs)

    return sum(np.sum(np.abs(positions), axis=1) * np.sum(np.abs(velocities), axis=1))


print(part1())
print(timeit.timeit(lambda: part1(), number=1000))
# @btime part1()
# submit(part1(), cur_day, 1)
# println(part2())
# submit(part2(), cur_day, 2)
