# Core utility tests

# Header decode tests
add_executable(header_decode_test header_decode_test.cpp)
target_link_libraries(header_decode_test PRIVATE vrtio GTest::gtest_main)
add_test(NAME header_decode_test COMMAND header_decode_test)

# Set C++20 standard
set_target_properties(header_decode_test PROPERTIES
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF
)
