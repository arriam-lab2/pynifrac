#cython: language_level=3, infer_types=True, c_string_type=unicode, c_string_encoding=utf8

from typing import Sized, Iterable, Union
from skbio.tree import TreeNode
import numpy as np

cimport numpy as np
# from libc.math cimport log2, fabs
from libcpp.vector cimport vector
from libcpp.string cimport string
from functional cimport accumulate


cdef class TreeIndex:

    def __cinit__(self, tree: TreeNode):
        self.decompose(tree)
        self.lensum = accumulate(
            self.lengths.begin(), self.lengths.end(), <branchlen_t>0
        )

    @property
    def nleaves(self):
        return self.decompositions.size()

    @property
    def nbranches(self):
        return self.lengths.size()

    cpdef np.ndarray ordering(self, names: Union[Iterable[str], Sized]):
        cdef list leafcodes = []
        for name in names:
            if not self.leafcodes.contains(name.encode('utf8')):
                raise KeyError('No leaf node {} in the index'.format(name))
            leafcodes.append(self.leafcodes[name.encode('utf8')])
        return np.array(leafcodes, dtype=np.uint32)

    cdef void decompose(self, tree: TreeNode):
        # a basic depth-first walk down the tree; take note that skbio TreeNodes
        # don't have a separate graph edge (branch) representation: nodes simply
        # carry the length of the branch connecting them to the parent node.
        cdef:
            vector[string] names  # leaf nodes' names
            vector[branchid_t] trace  # current path trace
            set visited = set()  # visited nodes
            branchid_t nleaves = len(list(tree.tips()))
        node = tree
        while names.size() != nleaves:
            if node.is_tip():
                # we've hit a leave and will thus save a copy of the trace
                names.push_back(node.name.encode('utf8'))
                self.decompositions.push_back(trace)
            # find an unvisited child node; if there are none left, move back
            # to the node's parent and cleanup the trace
            child = next((n for n in node.children if n not in visited), None)
            if child is None:
                trace.pop_back()
                node = node.parent
            else:
                trace.push_back(self.lengths.size())
                # some branch-lengths might be None (e.g. due to rooting);
                # treating Nones as zeros won't hurt due to the maths behind all
                # UniFracs
                self.lengths.push_back(child.length or 0)
                visited.add(child)
                node = child
        # create a mapping from leaf names to decomposition locations
        self.leafcodes.reserve(names.size())
        cdef branchid_t i = 0
        for i in range(names.size()):
            self.leafcodes[names[i]] = i


cdef class SampleIndex:
    # cdef:
    #     sparse_hash_map[branchid_t, branchlen_t] fractions
    #     branchid_t depth

    def __cinit__(self, TreeIndex tree, np.ndarray ordering, np.ndarray counts):

        if (ordering.ndim != counts.ndim) or (ordering.shape[0] != counts.shape[0]):
            raise ValueError
        if ordering.max() > tree.nleaves:
            raise ValueError
        self.depth = counts.sum()
        self.expand(tree.decompositions, ordering.astype(np.uint32),
                    counts.astype(np.uint32))

    @property
    def nbranches(self):
        return self.fractions.size()

    cdef void expand(self, const vector[vector[branchid_t]]& decompositions,
                     branchid_t[:] ordering, branchid_t[:] counts):
        cdef:
            uint32_t i = 0
            uint32_t j = 0
            uint32_t leaf = 0
            uint32_t branch = 0
        with nogil:
            for i in range(ordering.shape[0]):
                if not counts[i]:
                    continue
                leaf = ordering[i]
                # quite unfortunately, Cython has some problems with indirections
                # and C++ iteration, hence the manual looping
                for j in range(decompositions[leaf].size()):
                    branch = decompositions[leaf][j]
                    self.fractions[branch] = counts[i] / self.depth

    cdef vector[branchid_t] branch_union(self, SampleIndex other) nogil:
        cdef vector[branchid_t] intersection
        for item in self.fractions:
           intersection.push_back(item.first)
        for item in other.fractions:
            if not self.fractions.contains(item.first):
                intersection.push_back(item.first)
        return intersection

    cdef vector[branchid_t] branch_symdiff(self, SampleIndex other) nogil:
        cdef vector[branchid_t] difference
        for item in self.fractions:
            if not other.fractions.contains(item.first):
                difference.push_back(item.first)
        for item in other.fractions:
            if not self.fractions.contains(item.first):
                difference.push_back(item.first)
        return difference

    cdef float64_t fraction(self, branchid_t branchid) nogil:
        return self.fractions[branchid] if self.fractions.contains(branchid) else 0
