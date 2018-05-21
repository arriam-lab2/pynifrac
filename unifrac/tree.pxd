from libcpp.vector cimport vector
from libcpp.string cimport string
from numpy cimport float64_t, uint32_t, uint64_t
from sparsepp cimport sparse_hash_map


cdef class TreeIndex:
    cdef:
        sparse_hash_map[string, uint64_t] leafcodes
        vector[float64_t] lengths
        vector[vector[uint32_t]] decompositions
