cmake_minimum_required(VERSION 3.10)
project(PyLuaCorePoC)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
# Output .so library straight to the Python script dir
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR})

find_package(Python3 COMPONENTS Interpreter Development REQUIRED)
find_package(pybind11 REQUIRED)
find_package(Boost REQUIRED)

find_path(LUA_INCLUDE_DIR NAMES lauxlib.h PATH_SUFFIXES luajit-2.1 luajit-2.0)
find_library(LUA_LIBRARY NAMES luajit-5.1)

if (NOT LUA_INCLUDE_DIR OR NOT LUA_LIBRARY)
    message(FATAL_ERROR "LuaJIT not found")
endif()

pybind11_add_module(core main.cc)
target_include_directories(core PRIVATE ${LUA_INCLUDE_DIR} ${Boost_INCLUDE_DIRS})
target_link_libraries(core PRIVATE ${LUA_LIBRARY} pthread)
