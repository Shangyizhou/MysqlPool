# 指定使用 CMake 的最低版本号
cmake_minimum_required(VERSION 3.0)

# 设置项目名称
project(ConnectionPool C CXX)

# 头文件搜索路径
include_directories(
    ${PROJECT_SOURCE_DIR}/src
    ${PROJECT_SOURCE_DIR}/thirdparty
)

# 源文件搜索路径
aux_source_directory(
    ${PROJECT_SOURCE_DIR}/src SRC_LIST
)

# 设置编译选项
set(CXX_FLAGS
    -g
    -Wall
    -std=c++11
)

# 指定可执行文件生成路径
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/bin)

# 生成可执行文件 
add_executable(main ${SRC_LIST})

# 需要链接的库
target_link_libraries(main mysqlclient pthread)
