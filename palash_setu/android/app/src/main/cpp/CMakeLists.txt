cmake_minimum_required(VERSION 3.4.1)

project(onnx_inference)

# Add our source file
add_library(onnx_inference SHARED
            onnx_inference.cpp)

# Find Android logging library
find_library(log-lib log)

# Link everything together
target_link_libraries(onnx_inference
                      ${log-lib})
