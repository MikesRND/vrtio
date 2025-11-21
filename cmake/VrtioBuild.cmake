include_guard(GLOBAL)

# Apply common compile features, warnings, and extension settings.
function(vrtio_set_target_defaults target_name)
    target_compile_features(${target_name} PRIVATE cxx_std_20)
    set_target_properties(${target_name} PROPERTIES CXX_EXTENSIONS OFF)

    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        target_compile_options(${target_name} PRIVATE -Wall -Wextra -Wpedantic)
    elseif(MSVC)
        target_compile_options(${target_name} PRIVATE /W4)
    endif()
endfunction()

# Helper for example-style executables that only need vrtio.
function(vrtio_add_example target_name)
    add_executable(${target_name} ${ARGN})
    target_link_libraries(${target_name} PRIVATE vrtio)
    vrtio_set_target_defaults(${target_name})
endfunction()

# Helper for standalone tests that do not use GoogleTest.
function(vrtio_add_test_binary target_name)
    cmake_parse_arguments(ARG "" "NAME;TEST_DATA_DIR" "" ${ARGN})

    add_executable(${target_name} ${ARG_UNPARSED_ARGUMENTS})
    target_link_libraries(${target_name} PRIVATE vrtio)
    vrtio_set_target_defaults(${target_name})

    if(ARG_TEST_DATA_DIR)
        target_compile_definitions(${target_name} PRIVATE TEST_DATA_DIR="${ARG_TEST_DATA_DIR}")
    endif()

    if(NOT ARG_NAME)
        set(ARG_NAME ${target_name})
    endif()

    add_test(NAME ${ARG_NAME} COMMAND ${target_name})
endfunction()

# Helper for GoogleTest-based executables.
function(vrtio_add_gtest target_name)
    cmake_parse_arguments(ARG "" "NAME;TEST_DATA_DIR" "" ${ARGN})

    add_executable(${target_name} ${ARG_UNPARSED_ARGUMENTS})
    target_link_libraries(${target_name} PRIVATE vrtio GTest::gtest_main)
    vrtio_set_target_defaults(${target_name})

    if(ARG_TEST_DATA_DIR)
        target_compile_definitions(${target_name} PRIVATE TEST_DATA_DIR="${ARG_TEST_DATA_DIR}")
    endif()

    if(NOT ARG_NAME)
        set(ARG_NAME ${target_name})
    endif()

    add_test(NAME ${ARG_NAME} COMMAND ${target_name})
endfunction()
