import matplotlib.pyplot as plt
import json
from dataclasses import dataclass


plt.rcParams["font.family"    ] = "Times New Roman"
plt.rcParams["font.size"      ] = 15
plt.rcParams["xtick.direction"] = "in"
plt.rcParams["ytick.direction"] = "in"
plt.rcParams["xtick.bottom"   ] = True
plt.rcParams["xtick.top"      ] = True
plt.rcParams["ytick.left"     ] = True
plt.rcParams["ytick.right"    ] = True


@dataclass
class BenchmarkResult:
    run_cmd      : str
    N_list       : list[int]
    elapsed_times: list[float]


def load_json():
    result_file = "./results/elapsed_time.json"
    cases = []
    with open(result_file, "r") as f:
        raw = json.load(f)
        for case in raw:
            cases.append( BenchmarkResult(
                run_cmd       = case["run_cmd"],
                N_list        = case["N_list"],
                elapsed_times = case["elapsed_times"] ) )
    return cases


def plot_elapsed_time(cases: list[BenchmarkResult]) -> None:
    fig, ax = plt.subplots()
    fig.subplots_adjust(left=0.15, right=0.95, top=0.95, bottom=0.15)
    for case in cases:
        ax.plot(case.N_list, case.elapsed_times, label = case.run_cmd)
    ax.set_xlabel("N")
    ax.set_ylabel("Elapsed Time (us)")
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.legend()
    fig.savefig("elapsed_time.png")


def main():
    cases = load_json()
    plot_elapsed_time(cases)


if __name__ == "__main__":
    main()
