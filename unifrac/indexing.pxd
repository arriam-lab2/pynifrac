#cython: language_level=3, infer_types=True, c_string_type=unicode, c_string_encoding=utf8

from typing import Iterable, Sized
import numpy as np

cimport numpy as np
from libcpp.vector cimport vector
from libcpp.string cimport string
from numpy cimport float64_t, uint32_t
from sparsepp cimport sparse_hash_map


ctypedef uint32_t branchid_t
ctypedef float64_t branchlen_t


cdef class TreeIndex:
    cdef:
        sparse_hash_map[string, branchid_t] leafcodes
        vector[branchlen_t] lengths
        vector[vector[branchid_t]] decompositions
        branchlen_t lensum

    cdef void decompose(self, tree)

    cpdef np.ndarray ordering(self, names: Union[Iterable[str], Sized])


cdef class SampleIndex:
    cdef:
        sparse_hash_map[branchid_t, branchlen_t] fractions
        branchid_t depth

    cdef void expand(self, const vector[vector[branchid_t]]& decompositions,
                     branchid_t[:] ordering, branchid_t[:] counts)

    cdef vector[branchid_t] branch_union(self, SampleIndex other) nogil
    cdef vector[branchid_t] branch_symdiff(self, SampleIndex other) nogil
    cdef float64_t fraction(self, branchid_t branchid) nogil