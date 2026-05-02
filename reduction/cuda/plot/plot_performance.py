import json
import matplotlib.pyplot as plt
from dataclasses import dataclass
from pathlib import Path


RESULTS_DIR = Path(__file__).parents[1] / "results"


plt.rcParams["font.family"     ] = "Times New Roman"
plt.rcParams["mathtext.fontset"] = "cm"
plt.rcParams["font.size"       ] = 15
plt.rcParams["xtick.direction" ] = "in"
plt.rcParams["ytick.direction" ] = "in"
plt.rcParams["xtick.bottom"    ] = True
plt.rcParams["xtick.top"       ] = True
plt.rcParams["ytick.left"      ] = True
plt.rcParams["ytick.right"     ] = True


@dataclass
class BenchmarkResult:
    run_cmd      : str
    N_list       : list[int]
    elapsed_times: list[float]


def load_json():
    result_file = RESULTS_DIR / "elapsed_time.json"
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
    fig, ax = plt.subplots(figsize=(10, 6))
    fig.subplots_adjust(left=0.15, right=0.65, top=0.95, bottom=0.15)
    for case in cases:
        ax.plot(case.N_list, case.elapsed_times, marker = "o", linewidth = 1, label = case.run_cmd)
    ax.set_xlabel(r"$N$")
    ax.set_ylabel(r"Elapsed time [$\mathrm{\mu s}$]")
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.legend(loc = "lower left", bbox_to_anchor = (1.0, 0.0))
    fig.savefig(Path(__file__).parent / "elapsed_time.png")


def main():
    cases = load_json()
    plot_elapsed_time(cases)


if __name__ == "__main__":
    main()
