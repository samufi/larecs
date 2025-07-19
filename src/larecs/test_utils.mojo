from testing import assert_true, assert_false, assert_equal, assert_not_equal
from random import random
from memory import UnsafePointer
from sys.info import sizeof
from .component import ComponentType
from .bitmask import BitMask
from .world import World
from .resource import Resources


@always_inline
fn load[
    dType: DType, //, simd_width: Int, stride: Int = 1
](ref val: SIMD[dType, 1], out simd: SIMD[dType, simd_width]):
    """
    Load multiple values from a SIMD.

    Parameters:
        dType: The data type of the SIMD.
        simd_width: The number of values to load.
        stride: The stride between the values.

    Args:
        val: The SIMD to load from.
    """
    return UnsafePointer(to=val).strided_load[width=simd_width](stride)


@always_inline
fn store[
    dType: DType, //, simd_width: Int, stride: Int = 1
](ref val: SIMD[dType, 1], simd: SIMD[dType, simd_width]):
    """
    Store the values of a SIMD into memory with a given start SIMD value.

    Parameters:
        dType: The data type of the SIMD.
        simd_width: The number of values to load.
        stride: The stride between the values.

    Args:
        val: The SIMD at the first entry where the data should be stored.
        simd: The SIMD to store.
    """
    return UnsafePointer(to=val).strided_store[width=simd_width](simd, stride)


alias load2 = load[_, 2]
alias store2 = store[_, 2]


fn is_mutable[
    mut: Bool, //, T: AnyType, origin: Origin[mut]
](ref [origin]val: T) -> Bool:
    """
    Check if the value is mutable.

    Parameters:
        mut: Whether the value is mutable.
        T: The type of the value.
        origin: The origin of the value.

    Args:
        val: The value to check.
    """
    return mut


fn get_random_bitmask_list(
    count: Int,
    range_start: Int = 0,
    range_end: Int = 1000,
    out list: List[BitMask],
):
    list = List[BitMask]()
    list.reserve(count)
    for _ in range(count):
        bytes = SIMD[DType.uint64, 4]()
        bytes[0] = Int(random.random_ui64(range_start, range_end))
        list.append(
            BitMask(
                bytes=UnsafePointer(to=bytes).bitcast[SIMD[DType.uint8, 32]]()[]
            )
        )


@always_inline
fn get_random_bitmask() -> BitMask:
    mask = BitMask()
    for i in range(BitMask.total_bits):
        if random.random_float64() < 0.5:
            mask.set(UInt8(i), True)
    return mask


fn assert_equal_lists[
    T: EqualityComparable & Copyable & Movable & Stringable
](a: List[T], b: List[T], msg: String = "") raises:
    assert_equal(len(a), len(b), msg)
    for i in range(len(a)):
        assert_equal(a[i], b[i], msg)


alias ExplicitlyCopyableComponentType = ComponentType & ExplicitlyCopyable


@fieldwise_init
struct Position(ExplicitlyCopyableComponentType):
    var x: Float64
    var y: Float64


@fieldwise_init
struct Velocity(ExplicitlyCopyableComponentType):
    var dx: Float64
    var dy: Float64


@fieldwise_init
struct LargerComponent(ExplicitlyCopyableComponentType):
    var x: Float64
    var y: Float64
    var z: Float64


@fieldwise_init
struct FlexibleComponent[i: Int](ExplicitlyCopyableComponentType):
    var x: Float64
    var y: Float32


alias SmallWorld = World[
    LargerComponent,
    Position,
    Velocity,
    FlexibleComponent[0],
    FlexibleComponent[1],
    FlexibleComponent[2],
    FlexibleComponent[3],
    FlexibleComponent[4],
    FlexibleComponent[5],
    FlexibleComponent[6],
    FlexibleComponent[7],
    FlexibleComponent[8],
    FlexibleComponent[9],
    FlexibleComponent[10],
]

alias FullWorld = World[
    LargerComponent,
    Position,
    Velocity,
    FlexibleComponent[0],
    FlexibleComponent[1],
    FlexibleComponent[2],
    FlexibleComponent[3],
    FlexibleComponent[4],
    FlexibleComponent[5],
    FlexibleComponent[6],
    FlexibleComponent[7],
    FlexibleComponent[8],
    FlexibleComponent[9],
    FlexibleComponent[10],
    FlexibleComponent[11],
    FlexibleComponent[12],
    FlexibleComponent[13],
    FlexibleComponent[14],
    FlexibleComponent[15],
    FlexibleComponent[16],
    FlexibleComponent[17],
    FlexibleComponent[18],
    FlexibleComponent[19],
    FlexibleComponent[20],
    FlexibleComponent[21],
    FlexibleComponent[22],
    FlexibleComponent[23],
    FlexibleComponent[24],
    FlexibleComponent[25],
    FlexibleComponent[26],
    FlexibleComponent[27],
    FlexibleComponent[28],
    FlexibleComponent[29],
    FlexibleComponent[30],
    FlexibleComponent[31],
    FlexibleComponent[32],
    FlexibleComponent[33],
    FlexibleComponent[34],
    FlexibleComponent[35],
    FlexibleComponent[36],
    FlexibleComponent[37],
    FlexibleComponent[38],
    FlexibleComponent[39],
    FlexibleComponent[40],
    FlexibleComponent[41],
    FlexibleComponent[42],
    FlexibleComponent[43],
    FlexibleComponent[44],
    FlexibleComponent[45],
    FlexibleComponent[46],
    FlexibleComponent[47],
    FlexibleComponent[48],
    FlexibleComponent[49],
    FlexibleComponent[50],
    FlexibleComponent[51],
    FlexibleComponent[52],
    FlexibleComponent[53],
    FlexibleComponent[54],
    FlexibleComponent[55],
    FlexibleComponent[56],
    FlexibleComponent[57],
    FlexibleComponent[58],
    FlexibleComponent[59],
    FlexibleComponent[60],
    FlexibleComponent[61],
    FlexibleComponent[62],
    FlexibleComponent[63],
    FlexibleComponent[64],
    FlexibleComponent[65],
    FlexibleComponent[66],
    FlexibleComponent[67],
    FlexibleComponent[68],
    FlexibleComponent[69],
    FlexibleComponent[70],
    FlexibleComponent[71],
    FlexibleComponent[72],
    FlexibleComponent[73],
    FlexibleComponent[74],
    FlexibleComponent[75],
    FlexibleComponent[76],
    FlexibleComponent[77],
    FlexibleComponent[78],
    FlexibleComponent[79],
    FlexibleComponent[80],
    FlexibleComponent[81],
    FlexibleComponent[82],
    FlexibleComponent[83],
    FlexibleComponent[84],
    FlexibleComponent[85],
    FlexibleComponent[86],
    FlexibleComponent[87],
    FlexibleComponent[88],
    FlexibleComponent[89],
    FlexibleComponent[90],
    FlexibleComponent[91],
    FlexibleComponent[92],
    FlexibleComponent[93],
    FlexibleComponent[94],
    FlexibleComponent[95],
    FlexibleComponent[96],
    FlexibleComponent[97],
    FlexibleComponent[98],
    FlexibleComponent[99],
    FlexibleComponent[100],
    FlexibleComponent[101],
    FlexibleComponent[102],
    FlexibleComponent[103],
    FlexibleComponent[104],
    FlexibleComponent[105],
    FlexibleComponent[106],
    FlexibleComponent[107],
    FlexibleComponent[108],
    FlexibleComponent[109],
    FlexibleComponent[110],
    FlexibleComponent[111],
    FlexibleComponent[112],
    FlexibleComponent[113],
    FlexibleComponent[114],
    FlexibleComponent[115],
    FlexibleComponent[116],
    FlexibleComponent[117],
    FlexibleComponent[118],
    FlexibleComponent[119],
    FlexibleComponent[120],
    FlexibleComponent[121],
    FlexibleComponent[122],
    FlexibleComponent[123],
    FlexibleComponent[124],
    FlexibleComponent[125],
    FlexibleComponent[126],
    FlexibleComponent[127],
    FlexibleComponent[128],
    FlexibleComponent[129],
    FlexibleComponent[130],
    FlexibleComponent[131],
    FlexibleComponent[132],
    FlexibleComponent[133],
    FlexibleComponent[134],
    FlexibleComponent[135],
    FlexibleComponent[136],
    FlexibleComponent[137],
    FlexibleComponent[138],
    FlexibleComponent[139],
    FlexibleComponent[140],
    FlexibleComponent[141],
    FlexibleComponent[142],
    FlexibleComponent[143],
    FlexibleComponent[144],
    FlexibleComponent[145],
    FlexibleComponent[146],
    FlexibleComponent[147],
    FlexibleComponent[148],
    FlexibleComponent[149],
    FlexibleComponent[150],
    FlexibleComponent[151],
    FlexibleComponent[152],
    FlexibleComponent[153],
    FlexibleComponent[154],
    FlexibleComponent[155],
    FlexibleComponent[156],
    FlexibleComponent[157],
    FlexibleComponent[158],
    FlexibleComponent[159],
    FlexibleComponent[160],
    FlexibleComponent[161],
    FlexibleComponent[162],
    FlexibleComponent[163],
    FlexibleComponent[164],
    FlexibleComponent[165],
    FlexibleComponent[166],
    FlexibleComponent[167],
    FlexibleComponent[168],
    FlexibleComponent[169],
    FlexibleComponent[170],
    FlexibleComponent[171],
    FlexibleComponent[172],
    FlexibleComponent[173],
    FlexibleComponent[174],
    FlexibleComponent[175],
    FlexibleComponent[176],
    FlexibleComponent[177],
    FlexibleComponent[178],
    FlexibleComponent[179],
    FlexibleComponent[180],
    FlexibleComponent[181],
    FlexibleComponent[182],
    FlexibleComponent[183],
    FlexibleComponent[184],
    FlexibleComponent[185],
    FlexibleComponent[186],
    FlexibleComponent[187],
    FlexibleComponent[188],
    FlexibleComponent[189],
    FlexibleComponent[190],
    FlexibleComponent[191],
    FlexibleComponent[192],
    FlexibleComponent[193],
    FlexibleComponent[194],
    FlexibleComponent[195],
    FlexibleComponent[196],
    FlexibleComponent[197],
    FlexibleComponent[198],
    FlexibleComponent[199],
    FlexibleComponent[200],
    FlexibleComponent[201],
    FlexibleComponent[202],
    FlexibleComponent[203],
    FlexibleComponent[204],
    FlexibleComponent[205],
    FlexibleComponent[206],
    FlexibleComponent[207],
    FlexibleComponent[208],
    FlexibleComponent[209],
    FlexibleComponent[210],
    FlexibleComponent[211],
    FlexibleComponent[212],
    FlexibleComponent[213],
    FlexibleComponent[214],
    FlexibleComponent[215],
    FlexibleComponent[216],
    FlexibleComponent[217],
    FlexibleComponent[218],
    FlexibleComponent[219],
    FlexibleComponent[220],
    FlexibleComponent[221],
    FlexibleComponent[222],
    FlexibleComponent[223],
    FlexibleComponent[224],
    FlexibleComponent[225],
    FlexibleComponent[226],
    FlexibleComponent[227],
    FlexibleComponent[228],
    FlexibleComponent[229],
    FlexibleComponent[230],
    FlexibleComponent[231],
    FlexibleComponent[232],
    FlexibleComponent[233],
    FlexibleComponent[234],
    FlexibleComponent[235],
    FlexibleComponent[236],
    FlexibleComponent[237],
    FlexibleComponent[238],
    FlexibleComponent[239],
    FlexibleComponent[240],
    FlexibleComponent[241],
    FlexibleComponent[242],
    FlexibleComponent[243],
    FlexibleComponent[244],
    FlexibleComponent[245],
    FlexibleComponent[246],
    FlexibleComponent[247],
    FlexibleComponent[248],
    FlexibleComponent[249],
    FlexibleComponent[250],
    FlexibleComponent[251],
    FlexibleComponent[252],
]


@fieldwise_init
struct MemTestStruct(Copyable, Movable):
    var copy_counter: UnsafePointer[Int]
    var move_counter: UnsafePointer[Int]
    var del_counter: UnsafePointer[Int]

    var simd_data: SIMD[DType.uint8, 16]
    var list_data: List[Int]

    fn __moveinit__(out self, owned other: Self):
        self.move_counter = other.move_counter
        self.del_counter = other.del_counter
        self.copy_counter = other.copy_counter
        self.move_counter[] += 1
        self.simd_data = other.simd_data
        self.list_data = other.list_data^

    fn __copyinit__(out self, other: Self):
        self.move_counter = other.move_counter
        self.del_counter = other.del_counter
        self.copy_counter = other.copy_counter
        self.copy_counter[] += 1
        self.simd_data = other.simd_data
        self.list_data = other.list_data

    fn __del__(owned self):
        self.del_counter[] += 1


fn test_copy_move_del[
    Container: Copyable & Movable, //,
    container_factory: fn (owned val: MemTestStruct) -> Container,
    get_element_ptr: fn (container: Container) raises -> UnsafePointer[
        MemTestStruct
    ],
](init_moves: Int = 0, copy_moves: Int = 0, move_moves: Int = 0) raises:
    var del_counter = 0
    var move_counter = 0
    var copy_counter = 0
    var test_del_counter = 0
    var test_move_counter = init_moves
    var test_copy_counter = 0

    test_list = [1, 5, 7, 12313]
    test_simd = SIMD[DType.uint8, 16]()
    for i in range(16):
        test_simd[i] = i

    container = container_factory(
        MemTestStruct(
            UnsafePointer(to=copy_counter),
            UnsafePointer(to=move_counter),
            UnsafePointer(to=del_counter),
            test_simd,
            test_list,
        )
    )

    assert_equal(del_counter, test_del_counter)
    assert_equal(move_counter, test_move_counter)
    assert_equal(copy_counter, test_copy_counter)
    assert_equal(get_element_ptr(container)[].simd_data, test_simd)
    assert_equal(get_element_ptr(container)[].list_data, test_list)

    container2 = container
    test_copy_counter += 1
    test_move_counter += copy_moves
    assert_equal(del_counter, test_del_counter)
    assert_equal(move_counter, test_move_counter)
    assert_equal(copy_counter, test_copy_counter)

    assert_equal(
        get_element_ptr(container2)[].simd_data,
        get_element_ptr(container)[].simd_data,
    )
    assert_equal(
        get_element_ptr(container2)[].list_data,
        get_element_ptr(container)[].list_data,
    )
    assert_not_equal(
        get_element_ptr(container2)[].list_data.unsafe_ptr(),
        get_element_ptr(container)[].list_data.unsafe_ptr(),
    )
    list_address = get_element_ptr(container)[].list_data.unsafe_ptr()

    _ = container2^
    test_del_counter += 1
    assert_equal(del_counter, test_del_counter)
    assert_equal(move_counter, test_move_counter)
    assert_equal(copy_counter, test_copy_counter)


    container2 = container^
    test_move_counter += move_moves
    assert_equal(del_counter, test_del_counter)
    assert_equal(move_counter, test_move_counter)
    assert_equal(copy_counter, test_copy_counter)

    assert_equal(get_element_ptr(container2)[].simd_data, test_simd)
    assert_equal(get_element_ptr(container2)[].list_data, test_list)
    assert_equal(
        get_element_ptr(container2)[].list_data.unsafe_ptr(),
        list_address,
    )

    _ = container2^
    test_del_counter += 1
    assert_equal(del_counter, test_del_counter)
    assert_equal(move_counter, test_move_counter)
    assert_equal(copy_counter, test_copy_counter)
