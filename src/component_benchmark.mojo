from benchmark import Bench, BenchConfig, Bencher, keep, BenchId

from custom_benchmark import DefaultBench

from component_test import FlexibleDummyComponentType
from component import ComponentManager

alias FullManager = ComponentManager[
    FlexibleDummyComponentType[0],
    FlexibleDummyComponentType[1],
    FlexibleDummyComponentType[2],
    FlexibleDummyComponentType[3],
    FlexibleDummyComponentType[4],
    FlexibleDummyComponentType[5],
    FlexibleDummyComponentType[6],
    FlexibleDummyComponentType[7],
    FlexibleDummyComponentType[8],
    FlexibleDummyComponentType[9],
    FlexibleDummyComponentType[10],
    FlexibleDummyComponentType[11],
    FlexibleDummyComponentType[12],
    FlexibleDummyComponentType[13],
    FlexibleDummyComponentType[14],
    FlexibleDummyComponentType[15],
    FlexibleDummyComponentType[16],
    FlexibleDummyComponentType[17],
    FlexibleDummyComponentType[18],
    FlexibleDummyComponentType[19],
    FlexibleDummyComponentType[20],
    FlexibleDummyComponentType[21],
    FlexibleDummyComponentType[22],
    FlexibleDummyComponentType[23],
    FlexibleDummyComponentType[24],
    FlexibleDummyComponentType[25],
    FlexibleDummyComponentType[26],
    FlexibleDummyComponentType[27],
    FlexibleDummyComponentType[28],
    FlexibleDummyComponentType[29],
    FlexibleDummyComponentType[30],
    FlexibleDummyComponentType[31],
    FlexibleDummyComponentType[32],
    FlexibleDummyComponentType[33],
    FlexibleDummyComponentType[34],
    FlexibleDummyComponentType[35],
    FlexibleDummyComponentType[36],
    FlexibleDummyComponentType[37],
    FlexibleDummyComponentType[38],
    FlexibleDummyComponentType[39],
    FlexibleDummyComponentType[40],
    FlexibleDummyComponentType[41],
    FlexibleDummyComponentType[42],
    FlexibleDummyComponentType[43],
    FlexibleDummyComponentType[44],
    FlexibleDummyComponentType[45],
    FlexibleDummyComponentType[46],
    FlexibleDummyComponentType[47],
    FlexibleDummyComponentType[48],
    FlexibleDummyComponentType[49],
    FlexibleDummyComponentType[50],
    FlexibleDummyComponentType[51],
    FlexibleDummyComponentType[52],
    FlexibleDummyComponentType[53],
    FlexibleDummyComponentType[54],
    FlexibleDummyComponentType[55],
    FlexibleDummyComponentType[56],
    FlexibleDummyComponentType[57],
    FlexibleDummyComponentType[58],
    FlexibleDummyComponentType[59],
    FlexibleDummyComponentType[60],
    FlexibleDummyComponentType[61],
    FlexibleDummyComponentType[62],
    FlexibleDummyComponentType[63],
    FlexibleDummyComponentType[64],
    FlexibleDummyComponentType[65],
    FlexibleDummyComponentType[66],
    FlexibleDummyComponentType[67],
    FlexibleDummyComponentType[68],
    FlexibleDummyComponentType[69],
    FlexibleDummyComponentType[70],
    FlexibleDummyComponentType[71],
    FlexibleDummyComponentType[72],
    FlexibleDummyComponentType[73],
    FlexibleDummyComponentType[74],
    FlexibleDummyComponentType[75],
    FlexibleDummyComponentType[76],
    FlexibleDummyComponentType[77],
    FlexibleDummyComponentType[78],
    FlexibleDummyComponentType[79],
    FlexibleDummyComponentType[80],
    FlexibleDummyComponentType[81],
    FlexibleDummyComponentType[82],
    FlexibleDummyComponentType[83],
    FlexibleDummyComponentType[84],
    FlexibleDummyComponentType[85],
    FlexibleDummyComponentType[86],
    FlexibleDummyComponentType[87],
    FlexibleDummyComponentType[88],
    FlexibleDummyComponentType[89],
    FlexibleDummyComponentType[90],
    FlexibleDummyComponentType[91],
    FlexibleDummyComponentType[92],
    FlexibleDummyComponentType[93],
    FlexibleDummyComponentType[94],
    FlexibleDummyComponentType[95],
    FlexibleDummyComponentType[96],
    FlexibleDummyComponentType[97],
    FlexibleDummyComponentType[98],
    FlexibleDummyComponentType[99],
    FlexibleDummyComponentType[100],
    FlexibleDummyComponentType[101],
    FlexibleDummyComponentType[102],
    FlexibleDummyComponentType[103],
    FlexibleDummyComponentType[104],
    FlexibleDummyComponentType[105],
    FlexibleDummyComponentType[106],
    FlexibleDummyComponentType[107],
    FlexibleDummyComponentType[108],
    FlexibleDummyComponentType[109],
    FlexibleDummyComponentType[110],
    FlexibleDummyComponentType[111],
    FlexibleDummyComponentType[112],
    FlexibleDummyComponentType[113],
    FlexibleDummyComponentType[114],
    FlexibleDummyComponentType[115],
    FlexibleDummyComponentType[116],
    FlexibleDummyComponentType[117],
    FlexibleDummyComponentType[118],
    FlexibleDummyComponentType[119],
    FlexibleDummyComponentType[120],
    FlexibleDummyComponentType[121],
    FlexibleDummyComponentType[122],
    FlexibleDummyComponentType[123],
    FlexibleDummyComponentType[124],
    FlexibleDummyComponentType[125],
    FlexibleDummyComponentType[126],
    FlexibleDummyComponentType[127],
    FlexibleDummyComponentType[128],
    FlexibleDummyComponentType[129],
    FlexibleDummyComponentType[130],
    FlexibleDummyComponentType[131],
    FlexibleDummyComponentType[132],
    FlexibleDummyComponentType[133],
    FlexibleDummyComponentType[134],
    FlexibleDummyComponentType[135],
    FlexibleDummyComponentType[136],
    FlexibleDummyComponentType[137],
    FlexibleDummyComponentType[138],
    FlexibleDummyComponentType[139],
    FlexibleDummyComponentType[140],
    FlexibleDummyComponentType[141],
    FlexibleDummyComponentType[142],
    FlexibleDummyComponentType[143],
    FlexibleDummyComponentType[144],
    FlexibleDummyComponentType[145],
    FlexibleDummyComponentType[146],
    FlexibleDummyComponentType[147],
    FlexibleDummyComponentType[148],
    FlexibleDummyComponentType[149],
    FlexibleDummyComponentType[150],
    FlexibleDummyComponentType[151],
    FlexibleDummyComponentType[152],
    FlexibleDummyComponentType[153],
    FlexibleDummyComponentType[154],
    FlexibleDummyComponentType[155],
    FlexibleDummyComponentType[156],
    FlexibleDummyComponentType[157],
    FlexibleDummyComponentType[158],
    FlexibleDummyComponentType[159],
    FlexibleDummyComponentType[160],
    FlexibleDummyComponentType[161],
    FlexibleDummyComponentType[162],
    FlexibleDummyComponentType[163],
    FlexibleDummyComponentType[164],
    FlexibleDummyComponentType[165],
    FlexibleDummyComponentType[166],
    FlexibleDummyComponentType[167],
    FlexibleDummyComponentType[168],
    FlexibleDummyComponentType[169],
    FlexibleDummyComponentType[170],
    FlexibleDummyComponentType[171],
    FlexibleDummyComponentType[172],
    FlexibleDummyComponentType[173],
    FlexibleDummyComponentType[174],
    FlexibleDummyComponentType[175],
    FlexibleDummyComponentType[176],
    FlexibleDummyComponentType[177],
    FlexibleDummyComponentType[178],
    FlexibleDummyComponentType[179],
    FlexibleDummyComponentType[180],
    FlexibleDummyComponentType[181],
    FlexibleDummyComponentType[182],
    FlexibleDummyComponentType[183],
    FlexibleDummyComponentType[184],
    FlexibleDummyComponentType[185],
    FlexibleDummyComponentType[186],
    FlexibleDummyComponentType[187],
    FlexibleDummyComponentType[188],
    FlexibleDummyComponentType[189],
    FlexibleDummyComponentType[190],
    FlexibleDummyComponentType[191],
    FlexibleDummyComponentType[192],
    FlexibleDummyComponentType[193],
    FlexibleDummyComponentType[194],
    FlexibleDummyComponentType[195],
    FlexibleDummyComponentType[196],
    FlexibleDummyComponentType[197],
    FlexibleDummyComponentType[198],
    FlexibleDummyComponentType[199],
    FlexibleDummyComponentType[200],
    FlexibleDummyComponentType[201],
    FlexibleDummyComponentType[202],
    FlexibleDummyComponentType[203],
    FlexibleDummyComponentType[204],
    FlexibleDummyComponentType[205],
    FlexibleDummyComponentType[206],
    FlexibleDummyComponentType[207],
    FlexibleDummyComponentType[208],
    FlexibleDummyComponentType[209],
    FlexibleDummyComponentType[210],
    FlexibleDummyComponentType[211],
    FlexibleDummyComponentType[212],
    FlexibleDummyComponentType[213],
    FlexibleDummyComponentType[214],
    FlexibleDummyComponentType[215],
    FlexibleDummyComponentType[216],
    FlexibleDummyComponentType[217],
    FlexibleDummyComponentType[218],
    FlexibleDummyComponentType[219],
    FlexibleDummyComponentType[220],
    FlexibleDummyComponentType[221],
    FlexibleDummyComponentType[222],
    FlexibleDummyComponentType[223],
    FlexibleDummyComponentType[224],
    FlexibleDummyComponentType[225],
    FlexibleDummyComponentType[226],
    FlexibleDummyComponentType[227],
    FlexibleDummyComponentType[228],
    FlexibleDummyComponentType[229],
    FlexibleDummyComponentType[230],
    FlexibleDummyComponentType[231],
    FlexibleDummyComponentType[232],
    FlexibleDummyComponentType[233],
    FlexibleDummyComponentType[234],
    FlexibleDummyComponentType[235],
    FlexibleDummyComponentType[236],
    FlexibleDummyComponentType[237],
    FlexibleDummyComponentType[238],
    FlexibleDummyComponentType[239],
    FlexibleDummyComponentType[240],
    FlexibleDummyComponentType[241],
    FlexibleDummyComponentType[242],
    FlexibleDummyComponentType[243],
    FlexibleDummyComponentType[244],
    FlexibleDummyComponentType[245],
    FlexibleDummyComponentType[246],
    FlexibleDummyComponentType[247],
    FlexibleDummyComponentType[248],
    FlexibleDummyComponentType[249],
    FlexibleDummyComponentType[250],
    FlexibleDummyComponentType[251],
    FlexibleDummyComponentType[252],
    FlexibleDummyComponentType[253],
    FlexibleDummyComponentType[254],
    FlexibleDummyComponentType[255],
]


fn test(manager: ComponentManager) -> None:
    print(manager.get_id[FlexibleDummyComponentType[0]]())


fn benchmark_get_first_id_1_000_000(inout bencher: Bencher) capturing:
    # create a component manager with 256 components
    manager = FullManager()
    test(manager)

    @always_inline
    @parameter
    fn bench_fn() raises capturing -> None:
        for _ in range(1_000_000):
            keep(manager.get_id[FlexibleDummyComponentType[0]]())

    try:
        bencher.iter[bench_fn]()
    except:
        print("Error")


fn benchmark_get_last_id_1_000_000(inout bencher: Bencher) capturing:
    # create a component manager with 256 components
    manager = FullManager()

    # @always_inline
    # @parameter
    # fn bench_fn(calls: Int) raises capturing -> Int:
    #     for _ in range(calls):
    #         sum += int(manager.get_id[FlexibleDummyComponentType[255]]())
    #         keep(sum)
    #     print(calls)
    #     return calls

    # bencher.iter_custom[bench_fn]()
    @always_inline
    @parameter
    fn bench_fn() raises capturing -> None:
        for _ in range(1_000_000):
            keep(manager.get_id[FlexibleDummyComponentType[255]]())

    try:
        bencher.iter[bench_fn]()
    except:
        print("Error")


def run_all_component_benchmarks():
    bench = DefaultBench()
    run_all_component_benchmarks(bench)
    bench.dump_report()


def run_all_component_benchmarks(inout bench: Bench):
    bench.bench_function[benchmark_get_first_id_1_000_000](
        BenchId("10^6 * get_id[0]")
    )
    bench.bench_function[benchmark_get_last_id_1_000_000](
        BenchId("10^6 * get_id[255]")
    )


def main():
    run_all_component_benchmarks()
