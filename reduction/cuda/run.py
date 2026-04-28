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
	name           : str
	source         : str
	compiler       : str
	compiler_flags : str
	run_args       : str


def load_cases() -> list[BenchmarkCase]:
	cfg_file = "cases.json"
	with open(cfg_file, "r") as f:
		raw = json.load(f)

	cases = []
	for item in raw:
		cases.append( BenchmarkCase(
			name           = item["name"    ], 
			source         = item["source"  ], 
			compiler       = item["compiler"],
			compiler_flags = item["flags"   ],
			run_args       = item["run_args"] ) )
	return cases


def compile_case(case: BenchmarkCase) -> Path:
	src = case.source
	exe = case.name
	cmd = f"{case.compiler} {case.compiler_flags} {src} -o {exe}"
	print(f"[{Path(__file__).name}] {cmd}")
	try:
		result = subprocess.run(f"{cmd}".split(), capture_output = True, text = True, check = True)
	except subprocess.CalledProcessError as e:
		print(e.stderr, file = sys.stderr)
		sys.exit(1)
	return Path(exe)


def run_case(case: BenchmarkCase, exe: Path):
	cmd = f"./{exe} {case.run_args}"
	print(f"[{Path(__file__).name}] {cmd}")

	try:
		result = subprocess.run(cmd.split(), capture_output = True, text = True, check = True)
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
		exe = compile_case(case)
		result = run_case(case, exe)
		results.append(result)
	save_results(results)


if __name__ == "__main__":
	main()

