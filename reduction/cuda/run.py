import json
import subprocess
import sys
import time
from dataclasses import dataclass, asdict, field
from pathlib import Path


BIN_DIR = Path("./bin")
BIN_DIR.mkdir(exist_ok = True)

RESULT_DIR = Path("./results")
RESULT_DIR.mkdir(exist_ok = True)


@dataclass
class BenchmarkCase:
    compile_cmd : str
    run_cmds    : list[str]
    N_list      : list[int]

@dataclass
class BenchmarkResult:
    run_cmd       : str
    N_list        : list[int]
    elapsed_times : list[float] = field(default_factory=list)


def load_cases() -> list[BenchmarkCase]:
    cfg_file = "cases.json"
    with open(cfg_file, "r") as f:
        raw = json.load(f)

    cases = []
    for item in raw:
        cases.append( BenchmarkCase(
            compile_cmd = item["compile_cmd"],
            run_cmds    = item["run_cmds"   ],
            N_list      = item["N_list"     ] ))
    return cases


def compile_case(case: BenchmarkCase) -> None:
    print(f"[{Path(__file__).name}] {case.compile_cmd}")
    try:
        result = subprocess.run(case.compile_cmd.split(), capture_output = True, text = True, check = True)
    except subprocess.CalledProcessError as e:
        print(e.stderr, file = sys.stderr)
        sys.exit(1)


def run_case(
        case: BenchmarkCase,
        results_all_cases: list[BenchmarkResult] ) -> None:
    for cmd_base in case.run_cmds:
        result_this_case = BenchmarkResult( run_cmd = cmd_base, N_list = case.N_list )
        for N in case.N_list:
            cmd = cmd_base + f" -N {N}"
            print(f"[{Path(__file__).name}] {cmd}")
            try:
                result = subprocess.run(cmd.split(), capture_output = True, text = True, check = True)
            except subprocess.CalledProcessError as e:
                print(e.stdout, file = sys.stderr)
                print(e.stderr, file = sys.stderr)
                sys.exit(1)
            elapsed = float(result.stdout)
            result_this_case.elapsed_times.append(elapsed)
        results_all_cases.append(result_this_case)


def save_results(results_all_cases: list[BenchmarkResult]) -> None:
    out_json = RESULT_DIR / "elapsed_time.json"
    with open(out_json, "w") as f:
        json.dump([asdict(result) for result in results_all_cases], f, indent="\t")


def main():
    cases = load_cases()
    results_all_cases = []
    for case in cases:
        compile_case(case)
        run_case(case, results_all_cases)
    save_results(results_all_cases)


if __name__ == "__main__":
    main()

