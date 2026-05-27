cmake_minimum_required(VERSION 3.15)
project(idle_clicker CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(raylib REQUIRED)

add_executable(idle_clicker main.cpp)
target_link_libraries(idle_clicker PRIVATE raylib)
