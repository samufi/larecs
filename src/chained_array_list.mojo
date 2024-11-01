from collections import InlineArray
from memory.maybe_uninitialized import UnsafeMaybeUninitialized

# Note: The implentation of the list and the iterator directly
# copy code from the standard library's InlineList type.
# This should improve consistency and correctness.


@value
struct _ChainedArrayListIter[
    list_mutability: Bool, //,
    T: CollectionElementNew,
    page_size: UInt,
    list_lifetime: AnyLifetime[list_mutability].type,
    forward: Bool = True,
]:
    """Iterator for ChainedArrayList.

    Parameters:
        list_mutability: Whether the reference to the list is mutable.
        T: The type of the elements in the list.
        page_size: The size of the individual arrays containing the list's data.
        list_lifetime: The lifetime of the List
        forward: The iteration direction. `False` is backwards.
    """

    alias list_type = ChainedArrayList[T, page_size]

    var index: Int
    var src: Reference[Self.list_type, list_lifetime]

    fn __iter__(self) -> Self:
        return self

    fn __next__(
        inout self,
    ) -> Reference[T, list_lifetime]:
        @parameter
        if forward:
            self.index += 1
            return self.src[][self.index - 1]
        else:
            self.index -= 1
            return self.src[][self.index]

    fn __len__(self) -> Int:
        @parameter
        if forward:
            return len(self.src[]) - self.index
        else:
            return self.index


struct ChainedArrayList[
    ElementType: CollectionElementNew, page_size: UInt = 32
]:
    """A list whose data are stored in persistent subarrays.

    It is backed by a list of `InlineArray`s and an `Int` to represent the size.
    This struct partially implements the API of a regular `List`,
    but some special functionality is not available.

    The main advantage of this list is that the elements
    are persistent, meaning that even if the list is
    extended, the references to the elements remain valid.

    Parameters:
        ElementType: The type of the elements in the list.
        page_size: The number of elements stored in one contiguous block of memory.
    """

    alias PageType = InlineArray[
        UnsafeMaybeUninitialized[ElementType], Self.page_size
    ]

    var _pages: List[Self.PageType]
    var _size: UInt

    fn __init__(inout self):
        """Create a new empty list."""
        self._size = 0
        self._pages = List[Self.PageType]()

    fn __moveinit__(inout self, owned other: Self):
        """Move the contents of another list into a new list."""
        self._size = other._size
        self._pages = other._pages

    fn __del__(owned self):
        """Destroy all the elements in the list and free the memory."""

        full_pages = self._size // Self.page_size

        for i in range(full_pages):
            for j in range(Self.page_size):
                self._pages[i][j].assume_initialized_destroy()

        for j in range(self._size % Self.page_size):
            self._pages[full_pages][j].assume_initialized_destroy()

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

    fn __getitem__(
        ref [_]self: Self, owned idx: Int
    ) -> ref [__lifetime_of(self)] Self.ElementType:
        """Get a `Reference` to the element at the given index.

        Args:
            idx: The index of the item.

        Returns:
            A reference to the item at the given index.
        """
        debug_assert(0 <= idx < self._size, "Index must be within bounds.")

        return self._pages[idx // Self.page_size][
            idx % Self.page_size
        ].assume_initialized()

    fn __iter__(
        ref [_]self: Self,
    ) -> _ChainedArrayListIter[ElementType, page_size, __lifetime_of(self)]:
        """Iterate over elements of the list, returning immutable references.

        Returns:
            An iterator of immutable references to the list elements.
        """
        return _ChainedArrayListIter(0, self)

    fn append(inout self, owned value: ElementType):
        """Append an element to the list.

        Args:
            value: The element to append.
        """
        page_index = self._size // Self.page_size
        if page_index == len(self._pages):
            self._pages.append(Self.PageType(unsafe_uninitialized=True))
        self._pages[page_index][self._size % Self.page_size].write(value^)
        self._size += 1
