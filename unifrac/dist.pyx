#cython: language_level=3, infer_types=True, c_string_type=unicode, c_string_encoding=utf8


import numpy as np

cimport numpy as np
from numpy cimport uint32_t, float64_t
from libc.math cimport log2, fabs
from libcpp.vector cimport vector
from unifrac.indexing cimport TreeIndex, SampleIndex, branchid_t, branchlen_t


cdef inline np.float64_t infdif(np.float64_t x, np.float64_t y) nogil:
    return fabs(x * (log2(x) if x else 0) - y * (log2(y) if y else 0))


cpdef float64_t infunifrac(TreeIndex index, SampleIndex a , SampleIndex b):
    cdef:
        float64_t numerator = 0
        vector[branchid_t] branches
    with nogil:
        branches = a.branch_union(b)
        for branch in branches:
            # TODO optimise the sum
            numerator += (
                index.lengths[branch] * infdif(a.fraction(branch), b.fraction(branch))
            )
        return numerator / index.lensum


cpdef float64_t wunifrac(TreeIndex index, SampleIndex a , SampleIndex b):
    cdef:
        float64_t numerator = 0
        vector[branchid_t] branches
    with nogil:
        branches = a.branch_union(b)
        for branch in branches:
            # TODO optimise the sum
            numerator += (
                index.lengths[branch] * fabs(a.fraction(branch) - b.fraction(branch))
            )
        return numerator / index.lensum


cpdef float64_t uwunifrac(TreeIndex index, SampleIndex a , SampleIndex b):
    cdef:
        float64_t difflen = 0
        vector[branchid_t] branches
    with nogil:
        branches = a.branch_symdiff(b)
        for branchid in branches:
            difflen += index.lengths[branchid]
        return difflen / index.lensum
