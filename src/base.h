#pragma once
#include <iostream>
#include <vector>
#include <string>
#include <span>
#include <cstdint>
#include <cassert>
#include <cmath>
#include <cstring>
#include <memory>
#include <algorithm>

using u8 = uint8_t;
using uN = size_t;
using St = std::string;
template<typename T> using Sn = std::span<T>;

#define let auto const
#define A(x) assert(x)
