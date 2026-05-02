#include <algorithm>
#include <cassert>
#include <chrono>
#include <cstdio>
#include <iostream>
#include <random>
#include <string>
#include <utility>
#include <vector>

constexpr int NUM_TRIAL  = 10;
constexpr int BLOCK_SIZE = 128;


#define CUDA_CHECK(call)                                                 \
	do {                                                                 \
		cudaError_t err = call;                                          \
		if (err != cudaSuccess) {                                        \
			fprintf(stderr, "CUDA error at %s:%d: %s\\n",                \
					__FILE__, __LINE__, cudaGetErrorString(err));        \
			exit(EXIT_FAILURE);                                          \
		}                                                                \
	} while (0)


__global__
void max_reduce_kernel(const double* input, double* output, const int N)
{
	__shared__ double sdata[BLOCK_SIZE / 2];

	const int tid = threadIdx.x;
	const int i   = blockIdx.x * BLOCK_SIZE + threadIdx.x;

	double mymax = ( i < N ) ? input[i] : -1e100;
	if( i + blockDim.x < N ) mymax = fmax( mymax, input[i + blockDim.x] );

	sdata[tid] = mymax;
	__syncthreads();

	for( int s = blockDim.x/2; s > 0; s>>=1 ) {
		if( tid < s ) sdata[tid] = fmax( sdata[tid], sdata[tid + s] );
		__syncthreads();
	}

	if( tid == 0 ){
		output[blockIdx.x] = sdata[0];
	}
}


double gpu_max(
		const double *d_array, int N,
		double *d_tmp_array1, double *d_tmp_array2 )
{
	int size = N;

	CUDA_CHECK( cudaMemcpy(d_tmp_array1, d_array, sizeof(double) * N, cudaMemcpyDeviceToDevice) );

	while( size > 1 ){ 
		dim3 block( BLOCK_SIZE / 2, 1, 1 );
		dim3 grid(( size + BLOCK_SIZE - 1 ) / BLOCK_SIZE, 1, 1);
		max_reduce_kernel<<<grid, block>>>( d_tmp_array1, d_tmp_array2, size );
		CUDA_CHECK( cudaDeviceSynchronize() );
		size = grid.x;
		std::swap(d_tmp_array1, d_tmp_array2);
	}

	double max_vel;
	CUDA_CHECK( cudaMemcpy( &max_vel, &(d_tmp_array1[0]), sizeof(double), cudaMemcpyDeviceToHost ) );
	return max_vel;
}


int main(int argc, char** argv)
{
	assert( argc == 3 );
	const int N = std::stoi( std::string(argv[2]) );

	double *h_array = new double[N];
	double *d_array;
	double *d_tmp_array1;
	double *d_tmp_array2;
	CUDA_CHECK( cudaMalloc(&d_array     , sizeof(double) * N) );
	CUDA_CHECK( cudaMalloc(&d_tmp_array1, sizeof(double) * N) );
	CUDA_CHECK( cudaMalloc(&d_tmp_array2, sizeof(double) * N) );

	std::mt19937 mt(0);
	std::uniform_real_distribution<double> dist(0.0, 1000.0);
	for (int i = 0; i < N; i++) h_array[i] = dist(mt);

	CUDA_CHECK( cudaMemcpy(d_array, h_array, sizeof(double) * N, cudaMemcpyHostToDevice) );

	std::vector<float> elapsed_times_ms;
	for (int trial = 0; trial < NUM_TRIAL; trial++)
	{
		using namespace std::chrono;

		auto begin = high_resolution_clock::now();
		double maxval = gpu_max(d_array, N, d_tmp_array1, d_tmp_array2);
		auto end   = high_resolution_clock::now();
		auto elapsed_us = duration_cast<microseconds>(end - begin);
		elapsed_times_ms.push_back(elapsed_us.count() / 1000.0);

		assert( maxval == *std::max_element(h_array, h_array + N) );
	}

	std::sort( elapsed_times_ms.begin(), elapsed_times_ms.end() );
	std::printf("%.6f\n", elapsed_times_ms[NUM_TRIAL / 2]);

	delete[] h_array;
	CUDA_CHECK( cudaFree(d_array)      );
	CUDA_CHECK( cudaFree(d_tmp_array1) );
	CUDA_CHECK( cudaFree(d_tmp_array2) );

	return 0;
}

