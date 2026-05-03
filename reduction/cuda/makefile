kernel1_%: src/main.cu src/arg_parse.cu
	nvcc $^ -DREDUCTION_TYPE=$* --extended-lambda -I./src/kernel1 -o ./bin/kernel1_$*

kernel2_%: src/main.cu src/arg_parse.cu
	nvcc $^ -DREDUCTION_TYPE=$* --extended-lambda -I./src/kernel2 -o ./bin/kernel2_$*
