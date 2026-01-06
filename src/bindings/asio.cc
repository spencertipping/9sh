#include <boost/asio.hpp>

extern "C" {

void*
w_asio_context_new()
{
  return new boost::asio::io_context();
}

void
w_asio_context_run(void* ctx)
{
  static_cast<boost::asio::io_context*>(ctx)->run();
}

void
w_asio_context_delete(void* ctx)
{
  delete static_cast<boost::asio::io_context*>(ctx);
}

void*
w_asio_timer_new(void* ctx)
{
  return new boost::asio::steady_timer(*static_cast<boost::asio::io_context*>(ctx));
}

}
