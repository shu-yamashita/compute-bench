#include <cassert>
#include <utility>
#include "cuda_macro.h"
#include "kernel.h"


__global__
void max_reduce_kernel(const double* input, double* output, const int N)
{
	extern __shared__ double sdata[];

	const int tid = threadIdx.x;
	const int i   = blockIdx.x * blockDim.x * 2 + threadIdx.x;

	double mymax = ( i < N ) ? input[i] : -1e100;
	if ( i + blockDim.x < N ) mymax = fmax( mymax, input[i + blockDim.x] );

	sdata[tid] = mymax;
	__syncthreads();

	for ( int s = blockDim.x/2; s > 0; s>>=1 )
	{
		if( tid < s ) sdata[tid] = fmax( sdata[tid], sdata[tid + s] );
		__syncthreads();
	}

	if ( tid == 0 ) output[blockIdx.x] = sdata[0];
}


double gpu_max(
		const double *d_array, const int N,
		double *d_tmp_array1, double *d_tmp_array2,
		const Args& args )
{
	const auto iter = args.options.find("seg-size");
	assert( iter != args.options.end() );
	const int seg_size = stoi( iter->second );

	int size = N;
	CUDA_CHECK( cudaMemcpy(d_tmp_array1, d_array, sizeof(double) * N, cudaMemcpyDeviceToDevice) );

	while( size > 1 ){ 
		dim3 block( seg_size / 2, 1, 1 );
		dim3 grid(( size + seg_size - 1 ) / seg_size, 1, 1);
		max_reduce_kernel<<<grid, block, seg_size / 2 * sizeof(double)>>>( d_tmp_array1, d_tmp_array2, size );
		CUDA_CHECK( cudaDeviceSynchronize() );
		size = grid.x;
		std::swap(d_tmp_array1, d_tmp_array2);
	}

	double max_vel;
	CUDA_CHECK( cudaMemcpy( &max_vel, &(d_tmp_array1[0]), sizeof(double), cudaMemcpyDeviceToHost ) );
	return max_vel;
}

