#include <algorithm>
#include <cassert>
#include <chrono>
#include <iostream>
#include <random>
#include <vector>
#include "arg_parse.h"
#include "cuda_macro.h"
#include "kernel.h"


constexpr int NUM_TRIAL  = 10;


int main(int argc, char** argv)
{
	Args args = parse_args(argc, argv);

	assert( args.options.find("N") != args.options.end() );
	const int N = stoi( args.options["N"] );

	double *h_array = new double[N];
	double *d_array;
	double *d_tmp_array1;
	double *d_tmp_array2;
	CUDA_CHECK( cudaMalloc(&d_array     , sizeof(double) * N) );
	CUDA_CHECK( cudaMalloc(&d_tmp_array1, sizeof(double) * N) );
	CUDA_CHECK( cudaMalloc(&d_tmp_array2, sizeof(double) * N) );

	std::mt19937 mt(0);
	std::uniform_real_distribution<double> dist(0.0, 100.0);
	for (int i = 0; i < N; i++) h_array[i] = dist(mt);
	const double max_val_answer = *std::max_element(h_array, h_array + N);

	CUDA_CHECK( cudaMemcpy(d_array, h_array, sizeof(double) * N, cudaMemcpyHostToDevice) );

	std::vector<float> elapsed_times;
	for (int trial = 0; trial < NUM_TRIAL; trial++)
	{
		using namespace std::chrono;
		const auto start = high_resolution_clock::now();
		const double max_val = gpu_max(d_array, N, d_tmp_array1, d_tmp_array2);
		const auto end   = high_resolution_clock::now();

		const auto elapsed = duration_cast<microseconds>(end - start);
		elapsed_times.push_back(elapsed.count());

		assert( max_val == max_val_answer );
	}

	std::sort( elapsed_times.begin(), elapsed_times.end() );
	std::cout << "{\"time\": " << elapsed_times[NUM_TRIAL / 2] << "}" << std::endl;

	delete[] h_array;
	CUDA_CHECK( cudaFree(d_array)      );
	CUDA_CHECK( cudaFree(d_tmp_array1) );
	CUDA_CHECK( cudaFree(d_tmp_array2) );

	return 0;
}

