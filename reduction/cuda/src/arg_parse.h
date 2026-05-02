#pragma once

#include <map>
#include <string>
#include <vector>

struct Args {
	std::map<std::string, std::string> options;
	std::vector<std::string> flags;
	std::vector<std::string> positional;
};

// --abc-de -> abc-de
void remove_front_bars( std::string& s );

Args parse_args(int argc, char* argv[]);

