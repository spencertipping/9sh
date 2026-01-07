#pragma once
#include "base.h"

struct Args final
{
  Args(int argc, ch **argv);

  St   eval_script_;
  St   script_file_;
  bool eval_flag_ = false;
  bool file_flag_ = false;
};
