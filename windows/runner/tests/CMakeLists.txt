cmake_minimum_required(VERSION 3.14)
project(windows_secure_store_tests LANGUAGES CXX)

if(NOT WIN32)
  message(FATAL_ERROR "The secure store tests require Windows and DPAPI.")
endif()

enable_testing()
add_executable(secure_store_test
  secure_store_test.cpp
  ../secure_store_windows.cpp
)
target_compile_features(secure_store_test PRIVATE cxx_std_17)
target_compile_definitions(secure_store_test PRIVATE UNICODE _UNICODE NOMINMAX)
target_compile_options(secure_store_test PRIVATE /W4 /WX /EHsc)
# Match the production translation unit; the test harness itself uses C++
# exceptions only to report assertion failures and restore its temporary state.
set_source_files_properties(../secure_store_windows.cpp PROPERTIES
  COMPILE_DEFINITIONS _HAS_EXCEPTIONS=0)
target_include_directories(secure_store_test PRIVATE ..)
target_link_libraries(secure_store_test PRIVATE crypt32)
add_test(NAME secure_store COMMAND secure_store_test)
