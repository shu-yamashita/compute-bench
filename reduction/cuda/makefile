kernel1_%: src/main.cu src/arg_parse.cu src/kernel1.cu
	nvcc $^ -DREDUCTION_TYPE=$* -o ./bin/kernel1_$*
