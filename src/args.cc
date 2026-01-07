#include <iostream>
#include <cstring>

#include "args.h"

Args::Args(int argc, ch **argv)
{
  for (int i = 1; i < argc; ++i)
    if (std::strcmp(argv[i], "-e") == 0 && i + 1 < argc)
    {
      eval_script_ = argv[++i];
      eval_flag_   = true;
    }
    else if (argv[i][0] != '-')
    {
      script_file_ = argv[i];
      file_flag_   = true;
      // TODO: Handle script arguments
      break;
    }
    else
    {
      std::cerr << "Unknown argument: " << argv[i] << std::endl;
      exit(1);
    }
}
