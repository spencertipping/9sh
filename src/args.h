#pragma once
#include "base.h"

struct Args final
{
  Args(int argc, ch **argv);

  St   eval_script_;
  bool execute_flag_ = false;
};
