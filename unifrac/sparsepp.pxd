#cython: language_level=3, infer_types=True, c_string_type=unicode, c_string_encoding=utf8


from libcpp.pair cimport pair
from libcpp cimport bool as bool_t
from numpy cimport uint64_t


cdef extern from "sparsepp/spp.h" namespace "spp" nogil:
    cdef cppclass sparse_hash_map[A, B]:
        cppclass iterator:
            pair[A, B] operator*()
            iterator operator++()
            bint operator==(iterator)
            bint operator!=(iterator)
        sparse_hash_map()
        void reserve(uint64_t cnt)
        uint64_t size() const
        bool_t contains(const A& key) const
        B& operator[](const A& key)
        iterator begin()
        iterator end()


cdef extern from "sparsepp/spp.h" namespace "spp" nogil:
    cdef cppclass sparse_hash_set[A]:
        cppclass iterator:
            A operator*()
            iterator operator++()
            bint operator==(iterator)
            bint operator!=(iterator)
        sparse_hash_set()
        void reserve(uint64_t cnt)
        uint64_t size() const
        bool_t contains(const A& key) nogil const
        iterator begin()
        iterator end()