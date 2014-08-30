project(pixelpulse)
cmake_minimum_required(VERSION 2.8.11)
SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt5Qml REQUIRED)
find_package(Qt5Quick REQUIRED)
find_package(Qt5Gui REQUIRED)

add_subdirectory(libsmu)
add_subdirectory(Plot)

add_executable(pixelpulse main.cpp SMU.h SMU.cpp)
target_link_libraries(pixelpulse smu Plot Qt5::Qml Qt5::Gui)
