# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)
project(pdfium_dart_library VERSION 0.0.1 LANGUAGES C)
cmake_policy(VERSION 3.14...3.25)

# Detect architecture
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x64|x86_64)")
    set(CPU_NAME "x64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86)")
    set(CPU_NAME "x86")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(ARM64|aarch64|ARM64EC|arm64ec|ARM64E|arm64e)")
    set(CPU_NAME "arm64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(ARM|armv7-a|armeabi-v7a)")
    set(CPU_NAME "arm")
else()
    message(FATAL_ERROR "Unsupported architecture \"${CMAKE_SYSTEM_PROCESSOR}\"")
endif()
message(STATUS "Target CPU Name: ${CPU_NAME}")

# Platform detection
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(PDFIUM_PLATFORM "linux")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(PDFIUM_PLATFORM "win")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Android")
    set(PDFIUM_PLATFORM "android")
else()
    message(FATAL_ERROR "Unsupported OS: ${CMAKE_SYSTEM_NAME}")
endif()

# Variables
set(PDFIUM_RELEASE chromium%2F7363)
set(PDFIUM_DIR ${CMAKE_BINARY_DIR}/pdfium)
set(PDFIUM_RELEASE_DIR ${PDFIUM_DIR}/${PDFIUM_RELEASE})
file(MAKE_DIRECTORY ${PDFIUM_RELEASE_DIR})

if(WIN32)
    set(PDFIUM_LIB_FILENAME "pdfium.dll")
elseif(APPLE)
    set(PDFIUM_LIB_FILENAME "libpdfium.dylib")
else()
    set(PDFIUM_LIB_FILENAME "libpdfium.so")
endif()

set(PDFIUM_LIB_DIR "lib")
set(PDFIUM_ABI ${CPU_NAME})
set(PDFIUM_ARCHIVE_NAME pdfium-${PDFIUM_PLATFORM}-${PDFIUM_ABI})

set(PDFIUM_SRC_LIB_FILENAME ${PDFIUM_RELEASE_DIR}/${PDFIUM_LIB_DIR}/${PDFIUM_LIB_FILENAME})
set(PDFIUM_LIBS_DIR ${CMAKE_BINARY_DIR}/.lib/${PDFIUM_RELEASE})
set(PDFIUM_LIBS_ARCH_DIR ${PDFIUM_LIBS_DIR}/${PDFIUM_ABI})
set(PDFIUM_DEST_LIB_FILENAME ${PDFIUM_LIBS_ARCH_DIR}/${PDFIUM_LIB_FILENAME})

set(PDFIUM_LATEST_DIR ${CMAKE_BINARY_DIR}/.lib/latest)
set(PDFIUM_LATEST_LIBS_ARCH_DIR ${PDFIUM_LATEST_DIR}/${PDFIUM_ABI})
set(PDFIUM_LATEST_LIB_FILENAME ${PDFIUM_LATEST_LIBS_ARCH_DIR}/${PDFIUM_LIB_FILENAME})

# Download PDFium if necessary
if(NOT EXISTS ${PDFIUM_SRC_LIB_FILENAME})
    message(STATUS "Downloading PDFium...")
    file(DOWNLOAD https://github.com/bblanchon/pdfium-binaries/releases/download/${PDFIUM_RELEASE}/${PDFIUM_ARCHIVE_NAME}.tgz ${PDFIUM_RELEASE_DIR}/${PDFIUM_ARCHIVE_NAME}.tgz)
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar zxf ${PDFIUM_RELEASE_DIR}/${PDFIUM_ARCHIVE_NAME}.tgz
        WORKING_DIRECTORY ${PDFIUM_RELEASE_DIR}
        RESULT_VARIABLE STATUS
        ERROR_QUIET
    )
    if(STATUS AND NOT STATUS EQUAL 0)
        message(FATAL_ERROR "Failed to extract PDFium: ${STATUS}")
    endif()
else()
    message(STATUS "Using existing PDFium binary.")
endif()

# Copy binaries
if (NOT EXISTS ${PDFIUM_DEST_LIB_FILENAME})
    file(MAKE_DIRECTORY ${PDFIUM_LIBS_ARCH_DIR})
    file(COPY ${PDFIUM_SRC_LIB_FILENAME} DESTINATION ${PDFIUM_LIBS_ARCH_DIR})
endif()

# Copy headers
if (NOT EXISTS ${PDFIUM_LIBS_DIR}/include)
    file(COPY ${PDFIUM_RELEASE_DIR}/include DESTINATION ${PDFIUM_LIBS_DIR})
endif()

# Create symlink or copy for latest
if(WIN32)
    file(COPY ${PDFIUM_LIBS_DIR}/ DESTINATION ${PDFIUM_LATEST_DIR})
else()
    file(REMOVE ${PDFIUM_LATEST_DIR})
    file(CREATE_LINK ${PDFIUM_LIBS_DIR} ${PDFIUM_LATEST_DIR} SYMBOLIC)
endif()

# Build target
add_library(pdfium_dart SHARED pdfium_wrapper.c)
target_include_directories(pdfium_dart PUBLIC ${PDFIUM_LATEST_DIR}/include)
target_link_libraries(pdfium_dart PRIVATE ${PDFIUM_LATEST_LIB_FILENAME})
target_compile_definitions(pdfium_dart PUBLIC DART_SHARED_LIB)

if (ANDROID)
    target_link_options(pdfium_dart PRIVATE "-Wl,-z,max-page-size=16384")
endif()
