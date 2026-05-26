cmake_minimum_required(VERSION 3.22.1)

project(native_inference)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)

# Directorios
set(LLAMA_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp")
set(WHISPER_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/whisper.cpp")

# Opciones para llama.cpp
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS ON CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)

# Agregar subdirectorios
add_subdirectory(${LLAMA_CPP_DIR} llama_build)
# Nota: Esto asumirá que ya descargaste whisper.cpp en la carpeta
if(EXISTS "${WHISPER_CPP_DIR}/CMakeLists.txt")
    add_subdirectory(${WHISPER_CPP_DIR} whisper_build)
endif()

# Crear librería JNI única
add_library(llm SHARED
    llama_jni.cpp
)

target_include_directories(llm PRIVATE
    ${LLAMA_CPP_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Si whisper.cpp fue añadido como subdirectorio, agregar include y linkear
if(EXISTS "${WHISPER_CPP_DIR}/CMakeLists.txt")
    target_include_directories(llm PRIVATE ${WHISPER_CPP_DIR}/include)
    target_link_libraries(llm PRIVATE whisper)
endif()

target_link_libraries(llm PRIVATE
    llama
    ggml
    android
    log
    c++_shared
)

if(ANDROID)
    target_compile_options(llm PRIVATE -fPIC)
endif()
