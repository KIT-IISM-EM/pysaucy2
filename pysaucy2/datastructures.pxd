
cdef class IntArray:
    cdef:
        int* _array
        int _n

    cdef void  _init_array(self, const int n) except *
    @staticmethod
    cdef IntArray from_ptr(const int *ptr, const int n)
