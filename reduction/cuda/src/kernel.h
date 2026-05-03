#pragma once

#include "arg_parse.h"

template <typename T>
T gpu_max(
		const T *d_array,
		const int N,
		T *d_tmp_array1,
		T *d_tmp_array2,
		const Args& args);

