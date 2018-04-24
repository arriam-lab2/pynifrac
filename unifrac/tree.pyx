#cython: language_level=3, infer_types=True



def decompose(tree):
    cdef list names = []
    cdef list lengths = []
    cdef list trace = []
    cdef set visited = set()
    cdef list decomposed = []
    cdef int nleaves = len(list(tree.tips()))
    node = tree
    while len(names) != nleaves:
        if node.is_tip():
            names.append(node.name)
            decomposed.append(trace[:])
        child = next((n for n in node.children if n not in visited), None)
        if child is None:
            trace.pop()
            node = node.parent
        else:
            trace.append(len(lengths))
            lengths.append(child.length)
            visited.add(child)
            node = child
    return {name: i for i, name in enumerate(names)}, lengths, decomposed