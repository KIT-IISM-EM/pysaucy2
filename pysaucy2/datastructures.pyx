from cpython.mem cimport PyMem_Malloc, PyMem_Free


cdef class IntArray:
    """
    This is a simple implementation of an immutable integer
    array that supports indexing.
    """
    def __init__(self, array=None):
        """
        Create an IntArray instance.

        :param array: An iterable of integers
        """
        pass

    def __cinit__(self, array=None):
        cdef int n
        if array is not None:
            n = len(array)
            self._init_array(n)

            # Fill data
            for idx, i in enumerate(array):
                self._array[idx] = i
        else:
            self._init_array(0)

    def __dealloc__(self):
        if self._array is not NULL:
            PyMem_Free(self._array)
            self._array = NULL

    cdef void _init_array(self, const int n) except *:
        self._n = n
        self._array = <int *> PyMem_Malloc(self._n * sizeof(int))

        if self._array is NULL:
            raise MemoryError()

    @staticmethod
    cdef IntArray from_ptr(const int *ptr, const int n):
        cdef IntArray obj = IntArray.__new__(IntArray)
        obj._init_array(n)

        # Copy data
        for idx in range(n):
            obj._array[idx] = ptr[idx]

        return obj

    def __len__(self):
        """
        Get the array length
        """
        return self._n

    def __getitem__(self, int i):
        """
        Get integer at position *i*
        """
        if 0 <= i < self._n:
            return self._array[i]
        elif 0 > i >= -self._n:
            return self._array[self._n + i]
        else:
            raise IndexError('IntArray index out of range')
