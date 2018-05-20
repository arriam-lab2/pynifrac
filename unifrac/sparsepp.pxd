from libcpp.pair cimport pair


cdef extern from "sparsepp/spp.h" namespace "spp":
    cdef cppclass sparse_hash_map[A, B]:
        cppclass iterator:
            pair[A, B] operator*()
            iterator operator++()
            bint operator==(iterator)
            bint operator!=(iterator)
        sparse_hash_map()
        B& operator[](const A& key)
        iterator begin()
        iterator end()
