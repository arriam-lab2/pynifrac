#cython: language_level=3, infer_types=True


from itertools import chain

import numpy as np
cimport numpy as np

from libc.math cimport log2, fabs


cpdef dict combine(tuple index, dict sample):
    names, lengths, decomposed = index
    cdef list components = [decomposed[names[n]] for n in sample]
    cdef list counts = list(sample.values())
    cdef dict combination = {}
    cdef list component
    cdef int count
    cdef int edge
    for component, count in zip(components, counts):
        for edge in component:
            combination.setdefault(edge, 0)
            combination[edge] += count
    return combination


cpdef set bincombine(tuple index, dict sample):
    names, lengths, decomposed = index
    cdef list components = [decomposed[names[n]] for n in sample]
    return set(chain.from_iterable(components))


cdef inline np.float64_t infdif(np.float64_t x, np.float64_t y) nogil:
    return fabs((log2(x) if x else 0) - (log2(y) if y else 0))


def infunifrac(index: tuple, a: dict, b: dict):
    cdef list lengths = index[1]
    cdef np.float64_t total_length = sum(lengths)
    cdef dict a_ = combine(index, a)
    cdef int sum_a = sum(a_.values())
    cdef dict b_ = combine(index, b)
    cdef int sum_b = sum(b_.values())
    cdef set edges = set(a_) | set(b_)
    cdef np.float64_t dist = 0
    cdef int edge
    cdef np.float64_t l
    for edge in edges:
        l = lengths[edge]
        dist += (l / total_length) * infdif(
            a_[edge]/sum_a if edge in a_ else 0,
            b_[edge]/sum_b if edge in b_ else 0
        )
    return dist


def wunifrac(index: tuple, a: dict, b: dict):
    cdef list lengths = index[1]
    cdef np.float64_t total_length = sum(lengths)
    cdef dict a_ = combine(index, a)
    cdef int sum_a = sum(a_.values())
    cdef dict b_ = combine(index, b)
    cdef int sum_b = sum(b_.values())
    cdef set edges = set(a_) | set(b_)
    cdef np.float64_t dist = 0
    cdef int edge
    cdef np.float64_t l
    for edge in edges:
        l = lengths[edge]
        dist += (l / total_length) * fabs(
            (a_[edge]/sum_a if edge in a_ else 0) -
            (b_[edge]/sum_b if edge in b_ else 0)
        )
    return dist


def uwunifrac(index: tuple, a: dict, b: dict):
    cdef list lengths = index[1]
    cdef np.float64_t total_length = sum(lengths)
    cdef set a_ = bincombine(index, a)
    cdef set b_ = bincombine(index, b)
    cdef set setdiff = (a_ - b_) | (b_ - a_)
    cdef np.float64_t shared_length = 0
    cdef int edge
    for edge in setdiff:
        shared_length += lengths[edge]
    return shared_length / total_length
