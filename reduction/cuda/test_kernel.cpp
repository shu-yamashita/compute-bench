#include <iostream>
#include <cassert>
#include <string>

int main(int argc, char* argv[])
{
	assert(argc == 3);
	const int N = stoi(std::string(argv[argc - 1]));
	std::cout << 2 * N << std::endl;
	return 0;
}
