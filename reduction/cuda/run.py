import json
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path


RESULT_DIR = Path("results")
RESULT_DIR.mkdir(exist_ok = True)


@dataclass
class BenchmarkCase:
    name        : str
    compile_cmd : str
    run_cmd     : str


def load_cases() -> list[BenchmarkCase]:
    cfg_file = "cases.json"
    with open(cfg_file, "r") as f:
        raw = json.load(f)

    cases = []
    for item in raw:
        cases.append( BenchmarkCase(
            name        = item["name"       ], 
            compile_cmd = item["compile_cmd"],
            run_cmd     = item["run_cmd"    ] ) )
    return cases


def compile_case(case: BenchmarkCase) -> None:
    print(f"[{Path(__file__).name}] {case.compile_cmd}")
    try:
        result = subprocess.run(case.compile_cmd.split(), capture_output = True, text = True, check = True)
    except subprocess.CalledProcessError as e:
        print(e.stderr, file = sys.stderr)
        sys.exit(1)


def run_case(case: BenchmarkCase) -> dict[str, str]:
    print(f"[{Path(__file__).name}] {case.run_cmd}")

    try:
        result = subprocess.run(case.run_cmd.split(), capture_output = True, text = True, check = True)
    except subprocess.CalledProcessError as e:
        print(e.stdout, file = sys.stderr)
        print(e.stderr, file = sys.stderr)
        sys.exit(1)
    elapsed_time = float(result.stdout)

    return {
            "name": case.name,
            "time": elapsed_time
            }


def save_results(results):
    out_json = RESULT_DIR / "elapsed_time.json"
    with open(out_json, "w") as f:
        json.dump(results, f, indent="\t")


def main():
    cases = load_cases()
    results = []
    for case in cases:
        compile_case(case)
        result = run_case(case)
        results.append(result)
    save_results(results)


if __name__ == "__main__":
    main()

