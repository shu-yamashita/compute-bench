#include <cassert>
#include <utility>
#include "cuda_macro.h"
#include "kernel.h"


template <typename T>
__global__
void max_reduce_kernel(const T* input, T* output, const int N)
{
	extern __shared__ unsigned char smem[];
	T* sdata = reinterpret_cast<T*>(smem);

	const int tid = threadIdx.x;
	const int i   = blockIdx.x * blockDim.x * 2 + threadIdx.x;

	T mymax = ( i < N ) ? input[i] : -1e100;
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


template <typename T>
T gpu_max(
		const T *d_array, const int N,
		T *d_tmp_array1, T *d_tmp_array2,
		const Args& args )
{
	const auto iter = args.options.find("seg-size");
	assert( iter != args.options.end() );
	const int seg_size = stoi( iter->second );

	int size = N;
	CUDA_CHECK( cudaMemcpy(d_tmp_array1, d_array, sizeof(T) * N, cudaMemcpyDeviceToDevice) );

	while( size > 1 ){ 
		dim3 block( seg_size / 2, 1, 1 );
		dim3 grid(( size + seg_size - 1 ) / seg_size, 1, 1);
		max_reduce_kernel<<<grid, block, seg_size / 2 * sizeof(T)>>>( d_tmp_array1, d_tmp_array2, size );
		CUDA_CHECK( cudaDeviceSynchronize() );
		size = grid.x;
		std::swap(d_tmp_array1, d_tmp_array2);
	}

	T max_vel;
	CUDA_CHECK( cudaMemcpy( &max_vel, &(d_tmp_array1[0]), sizeof(T), cudaMemcpyDeviceToHost ) );
	return max_vel;
}


template  float gpu_max<float> ( const  float *d_array, const int N,  float *d_tmp_array1,  float *d_tmp_array2, const Args& args );
template double gpu_max<double>( const double *d_array, const int N, double *d_tmp_array1, double *d_tmp_array2, const Args& args );
