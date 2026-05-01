#include <iostream>
#include <cassert>
#include <string>

int main(int argc, char* argv[])
{
	int N = -1;
	float x = 0.0f;

	for (int i = 1; i < argc - 1; i++)
	{
		if ( std::string(argv[i]) == "-N" )
		{
			assert(i + 1 < argc);
			N = stoi(std::string(argv[i + 1]));
			i++;
		}
		else if ( std::string(argv[i]) == "-x" )
		{
			assert(i + 1 < argc);
			x = stoi(std::string(argv[i + 1]));
			i++;
		}
	}

	assert( N > 0 );

	std::cout << x * N * N << std::endl;
	return 0;
}
