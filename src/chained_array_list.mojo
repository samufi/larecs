from collections import InlineArray
from memory import UnsafePointer

# Note: The implentation of the list and the iterator directly
# copy code from the standard library's InlineList type.
# This should improve consistency and correctness.


# @value
# struct _ChainedArrayListIter[
#     list_mutability: Bool, //,
#     T: CollectionElementNew,
#     page_size: UInt,
#     list_origin: Origin[list_mutability],
#     forward: Bool = True,
# ]:
#     """Iterator for ChainedArrayList.

#     Parameters:
#         list_mutability: Whether the reference to the list is mutable.
#         T: The type of the elements in the list.
#         page_size: The size of the individual arrays containing the list's data.
#         list_origin: The lifetime of the List
#         forward: The iteration direction. `False` is backwards.
#     """

#     alias list_type = ChainedArrayList[T, page_size]

#     var index: Int
#     var src: Pointer[Self.list_type, list_origin]

#     fn __iter__(self) -> Self:
#         return self

#     fn __next__(
#         inout self,
#     ) -> Pointer[T, list_origin]:
#         @parameter
#         if forward:
#             self.index += 1
#             return Pointer.address_of(self.src[][self.index - 1])
#         else:
#             self.index -= 1
#             return Pointer.address_of(self.src[][self.index])

#     @always_inline
#     fn __has_next__(self) -> Bool:
#         return self.__len__() > 0

#     fn __len__(self) -> Int:
#         @parameter
#         if forward:
#             return len(self.src[]) - self.index
#         else:
#             return self.index


struct ChainedArrayList[
    ElementType: CollectionElementNew, page_size: UInt = 32
]:
    """A list whose data are stored in persistent subarrays.

    It is backed by a list of raw pointers and an `Int` to represent the size.
    This struct partially implements the API of a regular `List`,
    but some special functionality is not available.

    The main advantage of this list is that the elements
    are persistent, meaning that even if the list is
    extended, the references to the elements remain valid.

    Parameters:
        ElementType: The type of the elements in the list.
        page_size: The number of elements stored in one contiguous block of memory.
    """

    alias PageType = UnsafePointer[ElementType]

    var _pages: List[Self.PageType]
    var _size: UInt

    fn __init__(inout self):
        """Create a new empty list."""
        self._size = 0
        self._pages = List[Self.PageType]()

    fn __init__(inout self, owned *elements: ElementType):
        """Create a new empty list."""
        self = Self()
        for element in elements:
            self.append(ElementType(other=element[]))

    fn __moveinit__(inout self, owned other: Self):
        """Move the contents of another list into a new list."""
        self._size = other._size
        self._pages = other._pages

    fn __del__(owned self):
        """Destroy all the elements in the list and free the memory."""

        full_pages = self._size // Self.page_size

        for i in range(full_pages):
            if self._pages[i]:
                for j in range(Self.page_size):
                    (self._pages[i] + j).destroy_pointee()
                self._pages[i].free()

        if self._pages and self._pages[full_pages]:
            for j in range(self._size % Self.page_size):
                (self._pages[full_pages] + j).destroy_pointee()
            self._pages[full_pages].free()

    @always_inline
    fn __len__(self) -> Int:
        """Returns the length of the list.

        Returns:
            The number of elements in the list.
        """
        return self._size

    @always_inline
    fn __bool__(self) -> Bool:
        """Checks whether the list has any elements or not.

        Returns:
            `False` if the list is empty, `True` if there is at least one element.
        """
        return len(self) > 0

    @always_inline
    fn __getitem__(
        ref [_]self: Self, owned idx: Int
    ) -> ref [self] Self.ElementType:
        """Get a `Pointer` to the element at the given index.

        Args:
            idx: The index of the item.

        Returns:
            A reference to the item at the given index.
        """
        debug_assert(0 <= idx < self._size, "Index must be within bounds.")

        return (self._pages[idx // Self.page_size] + idx % Self.page_size)[]

    @always_inline
    fn get_ptr(
        ref [_]self: Self, owned idx: Int
    ) -> Pointer[Self.ElementType, __origin_of(self)]:
        """Get a `Pointer` to the element at the given index.

        Args:
            idx: The index of the item.

        Returns:
            A reference to the item at the given index.
        """
        return Pointer.address_of(self[idx])

    # @always_inline
    # fn __iter__(
    #     ref [_]self: Self,
    # ) -> _ChainedArrayListIter[ElementType, page_size, __origin_of(self)]:
    #     """Iterate over elements of the list, returning immutable references.

    #     Returns:
    #         An iterator of immutable references to the list elements.
    #     """
    #     return _ChainedArrayListIter(0, Pointer.address_of(self))

    fn append(inout self, owned value: ElementType):
        """Append an element to the list.

        Args:
            value: The element to append.
        """
        page_index = self._size // Self.page_size
        if page_index == len(self._pages):
            self._pages.append(Self.PageType.alloc(Self.page_size))
        (
            self._pages[page_index] + self._size % Self.page_size
        ).init_pointee_move(value^)
        self._size += 1
