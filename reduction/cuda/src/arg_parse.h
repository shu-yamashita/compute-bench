#pragma once

#include <algorithm>
#include <cassert>
#include <map>
#include <string>
#include <vector>


struct Args {
	std::map<std::string, std::string> options;
	std::vector<std::string> flags;
	std::vector<std::string> positional;
};


// --abc-de -> abc-de
inline
void remove_front_bars( std::string& s )
{
	std::reverse( s.begin(), s.end() );
	while ( !s.empty() && s.back() == '-' ) s.pop_back();
	std::reverse( s.begin(), s.end() );
}


inline
Args parse_args(int argc, char* argv[])
{
	Args result;

	for (int i = 1; i < argc; ++i)
	{
		std::string arg = argv[i];

		if ( arg[0] == '-' )
		{
			remove_front_bars( arg );
			assert( !arg.empty() );

			auto eq = arg.find('=');
			if ( eq != std::string::npos )
			{
				// format: --key=value
				std::string key = arg.substr(0, eq);
				std::string value = arg.substr(eq + 1);
				result.options[key] = value;
			}
			else if (i + 1 < argc && std::string(argv[i + 1])[0] != '-')
			{
				// format: --key value
				result.options[arg] = argv[++i];
			}
			else
			{
				// format = --flag
				result.flags.push_back(arg);
			}
		}
		else
		{
			result.positional.push_back(arg);
		}
	}

	return result;
}

