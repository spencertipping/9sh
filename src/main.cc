#include <luajit-2.1/lua.hpp>
#include <readline/readline.h>
#include <readline/history.h>

#include "args.h"
#include "lua.h"

#include "base.h"


struct REPL final
{
  REPL(Lua &l) : lua_(l) {}

  void run()
  {
    std::cout << "Welcome to 9sh (Skeletal)" << std::endl;
    for (ch *input; (input = readline("9sh> ")) != nullptr; free(input))
      if (*input)
      {
        if (*input != ' ') add_history(input);
        eval(input);
      }
  }

  void eval(Stc &input)
  {
    lua_.eval(input, false);
  }

protected:
  Lua &lua_;
};


int main(int argc, ch **argv)
{
  Args args(argc, argv);
  Lua  lua;

  if (args.eval_flag_)
    lua.eval(args.eval_script_);

  else if (args.file_flag_)
  {
    St cmd = "(fennel.dofile \"" + args.script_file_ + "\")";
    lua.eval(cmd);
  }

  else
  {
    REPL repl(lua);
    repl.run();
  }

  return 0;
}
