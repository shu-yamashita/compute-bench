#pragma once

#include <cassert>
#include <utility>
#include "../arg_parse.h"
#include "../cuda_macro.h"
#include "kernel.h"


// Loop unrolling
// Reference: Mark Harris, Optimizing Parallel Reduction in CUDA (p. 22)
template <typename T, typename BinaryOperation>
__device__
void warp_reduce(volatile T* sdata, const int tid, BinaryOperation op)
{
	sdata[tid] = op(sdata[tid], sdata[tid + 32]);
	sdata[tid] = op(sdata[tid], sdata[tid + 16]);
	sdata[tid] = op(sdata[tid], sdata[tid +  8]);
	sdata[tid] = op(sdata[tid], sdata[tid +  4]);
	sdata[tid] = op(sdata[tid], sdata[tid +  2]);
	sdata[tid] = op(sdata[tid], sdata[tid +  1]);
}


template <typename T, typename BinaryOperation>
__global__
void reduce_kernel(
		const T* input, T* output, const int N,
		BinaryOperation op, T identity )
{
	extern __shared__ unsigned char smem[];
	T* sdata = reinterpret_cast<T*>(smem);

	const int tid = threadIdx.x;
	const int i   = blockIdx.x * blockDim.x * 2 + threadIdx.x;

	T tmp = ( i < N ) ? input[i] : identity;
	if ( i + blockDim.x < N ) tmp = op( tmp, input[i + blockDim.x] );

	sdata[tid] = tmp;
	__syncthreads();

	for ( int s = blockDim.x/2; s > 32; s>>=1 )
	{
		if( tid < s ) sdata[tid] = op( sdata[tid], sdata[tid + s] );
		__syncthreads();
	}

	if ( tid < 32 ) warp_reduce(sdata, tid, op);

	if ( tid == 0 ) output[blockIdx.x] = sdata[0];
}


template <typename T, typename BinaryOperation>
T device_reduce(
		const T *d_array, const int N,
		T *d_tmp_array1, T *d_tmp_array2,
		BinaryOperation op, T identity,
		const Args& args)
{
	const auto iter = args.options.find("seg-size");
	assert( iter != args.options.end() );
	const int seg_size = stoi( iter->second );
	assert( seg_size >= 128 );

	int size = N;
	CUDA_CHECK( cudaMemcpy(d_tmp_array1, d_array, sizeof(T) * N, cudaMemcpyDeviceToDevice) );

	while( size > 1 ){ 
		dim3 block( seg_size / 2, 1, 1 );
		dim3 grid(( size + seg_size - 1 ) / seg_size, 1, 1);
		reduce_kernel<<<grid, block, seg_size / 2 * sizeof(T)>>>( d_tmp_array1, d_tmp_array2, size, op, identity );
		CUDA_CHECK( cudaDeviceSynchronize() );
		size = grid.x;
		std::swap(d_tmp_array1, d_tmp_array2);
	}

	T result;
	CUDA_CHECK( cudaMemcpy( &result, &(d_tmp_array1[0]), sizeof(T), cudaMemcpyDeviceToHost ) );
	return result;
}

