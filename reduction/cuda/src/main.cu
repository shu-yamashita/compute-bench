#include <algorithm>
#include <cassert>
#include <chrono>
#include <iostream>
#include <random>
#include <type_traits>
#include <vector>
#include "arg_parse.h"
#include "cuda_macro.h"
#include "kernel.h"


using T = REDUCTION_TYPE;


constexpr int NUM_TRIAL  = 10;


template <typename T>
void init_host_array( T* array, int N )
{
	std::mt19937 mt(0);
	std::uniform_real_distribution<T> dist(0.0, 10.0);
	for (int i = 0; i < N; i++) array[i] = dist(mt);
}


template <>
void init_host_array( int* array, int N )
{
	std::mt19937 mt(0);
	std::uniform_int_distribution<int> dist(0, 10);
	for (int i = 0; i < N; i++) array[i] = dist(mt);
}


int main(int argc, char** argv)
{
	Args args = parse_args(argc, argv);

	assert( args.options.find("N") != args.options.end() );
	const int N = stoi( args.options["N"] );

	T *h_array = new T[N];
	T *d_array;
	T *d_tmp_array1;
	T *d_tmp_array2;
	CUDA_CHECK( cudaMalloc(&d_array     , sizeof(T) * N) );
	CUDA_CHECK( cudaMalloc(&d_tmp_array1, sizeof(T) * N) );
	CUDA_CHECK( cudaMalloc(&d_tmp_array2, sizeof(T) * N) );

	init_host_array<T>( h_array, N );
	const T max_val_answer = *std::max_element(h_array, h_array + N);

	CUDA_CHECK( cudaMemcpy(d_array, h_array, sizeof(T) * N, cudaMemcpyHostToDevice) );

	std::vector<float> elapsed_times;
	for (int trial = 0; trial < NUM_TRIAL; trial++)
	{
		using namespace std::chrono;
		const auto start = high_resolution_clock::now();
		const T max_val = gpu_max<T>( d_array, N, d_tmp_array1, d_tmp_array2, args );
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

