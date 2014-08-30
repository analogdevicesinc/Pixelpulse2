cmake_minimum_required(VERSION 2.8.11)
SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

add_library(Plot
  FloatBuffer.h
  FloatBuffer.cpp
  PhosphorRender.h
  PhosphorRender.cpp
  plugin.h
)

target_link_libraries(Plot
  Qt5::Qml
  Qt5::Quick
  GL
)
