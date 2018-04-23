from libcpp cimport vector

import dendropy


def decompose(dendropy.Tree tree):
    """
    >>> tree = dendropy.Tree.get(
    ...     data='((A:2, B:3):1, C:4);',
    ...     schema="newick"
    ... )
    >>> decompose(tree) == ({'A': 0, 'B': 1, 'C': 2}, [1.0, 2.0, 3.0, 4.0], [[0, 1], [0, 2], [3]])
    True
    >>> tree.reroot_at_midpoint(update_bipartitions=True)
    >>> decompose(tree) == ({'A': 0, 'B': 1, 'C': 2}, [2.0, 3.0, 5.0], [[0], [1], [2]])
    True
    >>> tree = dendropy.Tree.get(
    ...     data='(A:1, B:2);',
    ...     schema="newick"
    ... )
    >>> tree.reroot_at_midpoint(update_bipartitions=True)
    >>> decompose(tree) == ({'B': 0, 'A': 1}, [1.5, 1.5], [[0], [1]])
    True
    """
    cdef list names = []
    cdef list lengths = []
    cdef list trace = []
    cdef set visited = set()
    cdef list decomposed = []
    cdef int nleaves = len(tree.leaf_nodes())
    node = next(iter(tree))
    while len(names) != nleaves:
        if node.is_leaf():
            names.append(node.taxon.label)
            decomposed.append(trace[:])
        edge = next((e for e in node.child_edges() if e not in visited), None)
        if not edge:
            node = node.parent_node
            trace.pop()
            continue
        trace.append(len(lengths))
        lengths.append(edge.length)
        visited.add(edge)
        node = edge.head_node
    return {name: i for i, name in enumerate(names)}, lengths, decomposed