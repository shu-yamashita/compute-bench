#pragma once

#include "arg_parse.h"

double gpu_max(
		const double *d_array,
		const int N,
		double *d_tmp_array1,
		double *d_tmp_array2,
		const Args& args);

