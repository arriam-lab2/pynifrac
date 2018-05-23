#cython: language_level=3, infer_types=True, c_string_type=unicode, c_string_encoding=utf8


cdef extern from "<numeric>" namespace "std" nogil:
    T accumulate[InputIterator, T](InputIterator first, InputIterator last, T init)
