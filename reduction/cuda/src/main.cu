#include <algorithm>
#include <cassert>
#include <chrono>
#include <iostream>
#include <limits>
#include <numeric>
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
	std::uniform_real_distribution<T> dist(-10.0, 10.0);
	for (int i = 0; i < N; i++) array[i] = dist(mt);
}


template <>
void init_host_array( int* array, int N )
{
	std::mt19937 mt(0);
	std::uniform_int_distribution<int> dist(-10, 10);
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
	CUDA_CHECK( cudaMemcpy(d_array, h_array, sizeof(T) * N, cudaMemcpyHostToDevice) );

	assert( args.options.find("op") != args.options.end() );
	const std::string op_str = args.options["op"];
	assert( op_str == "add" || op_str == "max" );

	T answer = -1;
	if      ( op_str == "add" ) answer = std::accumulate(h_array, h_array + N, T(0));
	else if ( op_str == "max" ) answer = *std::max_element(h_array, h_array + N);
	else                        assert(false);

	auto lambda_add = [] __host__ __device__ (T a, T b) { return a + b; };
	auto lambda_max = [] __host__ __device__ (T a, T b) { return (a > b ? a : b); };
	T add_identity = 0;
	T max_identity = std::numeric_limits<T>::lowest();

	std::vector<float> elapsed_times;
	for (int trial = 0; trial < NUM_TRIAL; trial++)
	{
		using namespace std::chrono;

		const auto start = high_resolution_clock::now();

		T result;
		if ( op_str == "add" )
		{
			result = device_reduce<T>(
					d_array, N, d_tmp_array1, d_tmp_array2,
					lambda_add, add_identity, args );
		}
		else if ( op_str == "max" )
		{
			result = device_reduce<T>(
					d_array, N, d_tmp_array1, d_tmp_array2,
					lambda_max, max_identity, args );
		}
		else assert(false);

		const auto end   = high_resolution_clock::now();

		const auto elapsed = duration_cast<microseconds>(end - start);
		elapsed_times.push_back(elapsed.count());

		assert( result == answer );
	}

	std::sort( elapsed_times.begin(), elapsed_times.end() );
	std::cout << "{\"time\": " << elapsed_times[NUM_TRIAL / 2] << "}" << std::endl;

	delete[] h_array;
	CUDA_CHECK( cudaFree(d_array)      );
	CUDA_CHECK( cudaFree(d_tmp_array1) );
	CUDA_CHECK( cudaFree(d_tmp_array2) );

	return 0;
}

