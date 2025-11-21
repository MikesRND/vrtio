cmake_minimum_required(VERSION 3.24)
project(
    vrtio
    VERSION 0.0.1
    DESCRIPTION "Header-only C++20 library for VRT (VITA 49.2) packets"
    LANGUAGES CXX
)

if(MSVC AND NOT CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    message(FATAL_ERROR "MSVC (cl) toolchain is not yet supported. Please use Clang or GCC.")
endif()

include(GNUInstallDirs)

# Header-only library
add_library(vrtio INTERFACE)
add_library(vrtio::vrtio ALIAS vrtio)
target_include_directories(vrtio INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

# Generate version header
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/version.hpp.in
    ${CMAKE_CURRENT_BINARY_DIR}/include/vrtio/version.hpp
    @ONLY
)

# Require C++20 for consumers
target_compile_features(vrtio INTERFACE cxx_std_20)
set_property(TARGET vrtio PROPERTY CXX_EXTENSIONS OFF)

# Compiler warnings
target_compile_options(vrtio INTERFACE
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wall -Wextra -Wpedantic>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)

# I/O helpers are always available (no optional toggle)

# Optional: Build tests
option(VRTIO_BUILD_TESTS "Build tests" OFF)
# Allow fetching optional dependencies (e.g., GTest) via FetchContent
option(VRTIO_FETCH_DEPENDENCIES "Fetch optional dependencies when not found locally" OFF)
if(VRTIO_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

# Optional: Build examples
option(VRTIO_BUILD_EXAMPLES "Build examples" OFF)
if(VRTIO_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

# Custom target: Extract quickstart snippets to docs
add_custom_target(quickstart ALL
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/extract_quickstart.sh
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Extracting quickstart code snippets to docs/quickstart.md"
    VERBATIM
)

# Installation
install(DIRECTORY include/vrtio
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILES_MATCHING PATTERN "*.hpp"
)

install(FILES include/vrtio.hpp
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/include/vrtio/version.hpp
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/vrtio
)

install(TARGETS vrtio
    EXPORT vrtioTargets
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(EXPORT vrtioTargets
    FILE vrtioTargets.cmake
    NAMESPACE vrtio::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/vrtio
)

# Configure and install package config files
include(CMakePackageConfigHelpers)

configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/vrtioConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/vrtioConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/vrtio
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/vrtioConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/vrtioConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/vrtioConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/vrtio
)
