#cython: language_level=3, infer_types=True, c_string_type=unicode, c_string_encoding=utf8

from skbio.tree import TreeNode
import numpy as np

from libcpp.vector cimport vector
from libcpp.string cimport string
cimport numpy as np
from numpy cimport int64_t, float64_t, uint32_t, uint64_t
from sparsepp cimport sparse_hash_map


cdef class TreeIndex:
    cdef:
        sparse_hash_map[string, uint64_t] leafcodes
        vector[float64_t] lengths
        vector[vector[uint32_t]] decompositions

    def __init__(self, tree: TreeNode):
        self.decompose(tree)

    @property
    def nleaves(self):
        return self.decompositions.size()

    @property
    def nbranches(self):
        return self.lengths.size()

    @property
    def branch_lengths(self):
        cdef:
            np.ndarray[float64_t, ndim=1] lengths = np.zeros(self.nbranches, np.float64)
            uint64_t i
        for i in range(self.nbranches):
            lengths[i] = self.lengths[i]
        return lengths

    @property
    def leaves(self):
        retval = {}
        for item in self.leafcodes:
            retval[item.first] = item.second
        return retval

    cdef void decompose(self, tree):
        cdef:
            vector[uint32_t] trace
            set visited = set()
            uint32_t nleaves = len(list(tree.tips()))
        node = tree
        while self.leafcodes.size() != nleaves:
            if node.is_tip():
                self.leafcodes[node.name.encode('utf8')] = self.leafcodes.size()
                self.decompositions.push_back(trace)
            child = next((n for n in node.children if n not in visited), None)
            if child is None:
                trace.pop_back()
                node = node.parent
            else:
                trace.push_back(self.lengths.size())
                self.lengths.push_back(child.length or 0)
                visited.add(child)
                node = child
