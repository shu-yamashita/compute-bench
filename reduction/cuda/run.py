def load_cases():
	# TODO: read files
	pass

def compile_case():
	# TODO
	pass

def run_case():
	# TODO
	pass

def main():
	cases = load_cases()
	results = []
	for case in cases:
		compile_case()
		time = run_case()
		results.append(time)
	save_results()

if __name__ == "__main__":
	main()
