#cython: language_level=3, infer_types=True, c_string_type=unicode, c_string_encoding=utf8

from skbio.tree import TreeNode
import numpy as np

from libcpp.vector cimport vector
from libcpp.string cimport string
cimport numpy as np
from numpy cimport int64_t, float64_t, uint32_t, uint64_t


cdef class TreeIndex:
    cdef:
        dict leafcodes
        vector[float64_t] lengths
        vector[vector[uint32_t]] decompositions

    def __init__(self, tree: TreeNode):
        self.leafcodes = {}
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
        return self.leafcodes

    cdef void decompose(self, tree):
        cdef:
            list names = []
            vector[uint32_t] trace
            set visited = set()
            uint32_t nleaves = len(list(tree.tips()))
        node = tree
        while len(names) != nleaves:
            if node.is_tip():
                names.append(node.name)
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
        self.leafcodes = {name: i for i, name in enumerate(names)}
