import json
import subprocess
import sys
import time
from dataclasses import dataclass, asdict, field
from pathlib import Path


RESULT_DIR = Path("results")
RESULT_DIR.mkdir(exist_ok = True)


@dataclass
class BenchmarkCase:
    name          : str
    compile_cmd   : str
    run_cmds      : list[str]
    elapsed_times : list[float] = field(default_factory = list)


def load_cases() -> list[BenchmarkCase]:
    cfg_file = "cases.json"
    with open(cfg_file, "r") as f:
        raw = json.load(f)

    cases = []
    for item in raw:
        cases.append( BenchmarkCase(
            name        = item["name"       ], 
            compile_cmd = item["compile_cmd"],
            run_cmds    = item["run_cmds"   ] ) )
    return cases


def compile_case(case: BenchmarkCase) -> None:
    print(f"[{Path(__file__).name}] {case.compile_cmd}")
    try:
        result = subprocess.run(case.compile_cmd.split(), capture_output = True, text = True, check = True)
    except subprocess.CalledProcessError as e:
        print(e.stderr, file = sys.stderr)
        sys.exit(1)


def run_case(case: BenchmarkCase):
    for cmd in case.run_cmds:
        print(f"[{Path(__file__).name}] {cmd}")
        try:
            result = subprocess.run(cmd.split(), capture_output = True, text = True, check = True)
        except subprocess.CalledProcessError as e:
            print(e.stdout, file = sys.stderr)
            print(e.stderr, file = sys.stderr)
            sys.exit(1)
        elapsed = float(result.stdout)
        case.elapsed_times.append(elapsed)


def save_results(cases: list[BenchmarkCase]) -> None:
    out_json = RESULT_DIR / "elapsed_time.json"
    with open(out_json, "w") as f:
        json.dump([asdict(case) for case in cases], f, indent="\t")


def main():
    cases = load_cases()
    for case in cases:
        compile_case(case)
        run_case(case)
    save_results(cases)


if __name__ == "__main__":
    main()

