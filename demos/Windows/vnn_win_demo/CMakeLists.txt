cmake_minimum_required(VERSION 3.8.0)

add_compile_options(-std=c++11)

project(vnn_demo_proj)
	
SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

set(ROOT_PATH ${CMAKE_CURRENT_LIST_DIR})
set(BUILD_PATH ${CMAKE_BINARY_DIR})  # set the build path

set(OPENCV_PATH ${ROOT_PATH}/third/opencv/build)

include(${CMAKE_CURRENT_SOURCE_DIR}/utils.cmake)

file(GLOB_RECURSE  WINDEMO_SOURCE "demo/src/*.cpp" "demo/src/*.h" "demo/inc/*.h")
#add source group
FILE(GLOB_RECURSE PROJECT_SOURCE "demo/src/*.cpp")
FILE(GLOB_RECURSE PROJECT_HEADER "demo/inc/*.h" "demo/src/*.h" "prebuilt/inc/*.h")
assign_source_group("Source" ${PROJECT_SOURCE})
assign_source_group("Include" ${PROJECT_HEADER})

include_directories(${ROOT_PATH}/demo/inc )
include_directories(${CMAKE_CURRENT_LIST_DIR}/prebuilt/inc)

SET(CMKAE_DEBUG_POSTFIX "d" CACHE STRING "add a postfix, usually d on windows")
SET(CMAKE_RELEASE_POSTFIX "" CACHE STRING "add a postfix, usually empty on windows")

include_directories(${OPENCV_PATH}/include)

add_executable(vnn_win_demo ${WINDEMO_SOURCE})



set(VNN_LIB_PATH "${CMAKE_CURRENT_LIST_DIR}/prebuilt/lib/x64")
set(VNN_BIN_PATH "${CMAKE_CURRENT_LIST_DIR}/prebuilt/bin/x64")
set(OPENCV_BIN_PATH "${OPENCV_PATH}/x64/vc15/bin")
set(OPENCV_LIB_PATH "${OPENCV_PATH}/x64/vc15/lib")
set(OPENCV_FFMPEG "${OPENCV_BIN_PATH}/opencv_ffmpeg346_64.dll")
message(${VNN_LIB_PATH})
find_library(vnn_core-lib vnn_core PATHS ${VNN_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_kit-lib vnn_kit PATHS ${VNN_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_face-lib vnn_face PATHS ${VNN_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_faceparser-lib vnn_faceparser PATHS ${VNN_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_stylizing-lib vnn_stylizing PATHS ${VNN_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_face_reenactment-lib vnn_face_reenactment PATHS ${VNN_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_gesture-lib vnn_gesture PATHS ${VNN_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_objcount-lib vnn_objcount PATHS ${VNN_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_objtracking-lib vnn_objtracking PATHS ${VNN_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
#find_library(vnn_docrect-lib vnn_docrect PATHS ${VNN_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_general-lib vnn_general PATHS ${VNN_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_classifying-lib vnn_classifying PATHS ${VNN_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_pose-lib vnn_pose PATHS ${VNN_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
target_link_libraries(vnn_win_demo PUBLIC
		${vnn_core-lib}
        ${vnn_kit-lib}
        ${vnn_face-lib}
        ${vnn_faceparser-lib}
        ${vnn_stylizing-lib}
        ${vnn_face_reenactment-lib}
        ${vnn_gesture-lib}
        ${vnn_objcount-lib}
        ${vnn_objtracking-lib}
        #${vnn_docrect-lib}
        ${vnn_general-lib}
        ${vnn_classifying-lib}
		${vnn_pose-lib}
		)
if (WIN32)
target_compile_options( vnn_win_demo PRIVATE
    $<$<CXX_COMPILER_ID:MSVC>:/Zi>
    $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-g>
    )

if(MSVC)
    target_link_options(vnn_win_demo PUBLIC /DEBUG)
endif()
endif()

add_custom_command(TARGET vnn_win_demo
                    POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${OPENCV_FFMPEG} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<CONFIG>
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${OPENCV_BIN_PATH}/opencv_world346.dll"  ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<CONFIG>
					
					COMMAND ${CMAKE_COMMAND} -E copy_if_different "${VNN_BIN_PATH}/vnn_core.dll"   ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<CONFIG>
					COMMAND ${CMAKE_COMMAND} -E copy_if_different "${VNN_BIN_PATH}/vnn_kit.dll"   ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<CONFIG>
					COMMAND ${CMAKE_COMMAND} -E copy_if_different "${VNN_BIN_PATH}/vnn_face.dll"   ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<CONFIG>
					COMMAND ${CMAKE_COMMAND} -E copy_if_different "${VNN_BIN_PATH}/vnn_faceparser.dll"   ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<CONFIG>
					COMMAND ${CMAKE_COMMAND} -E copy_if_different "${VNN_BIN_PATH}/vnn_stylizing.dll"   ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<CONFIG>
					COMMAND ${CMAKE_COMMAND} -E copy_if_different "${VNN_BIN_PATH}/vnn_face_reenactment.dll"   ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<CONFIG>
					COMMAND ${CMAKE_COMMAND} -E copy_if_different "${VNN_BIN_PATH}/vnn_gesture.dll"   ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<CONFIG>
					COMMAND ${CMAKE_COMMAND} -E copy_if_different "${VNN_BIN_PATH}/vnn_objcount.dll"   ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<CONFIG>
					COMMAND ${CMAKE_COMMAND} -E copy_if_different "${VNN_BIN_PATH}/vnn_objtracking.dll"   ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<CONFIG>
					COMMAND ${CMAKE_COMMAND} -E copy_if_different "${VNN_BIN_PATH}/vnn_general.dll"   ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<CONFIG>
					COMMAND ${CMAKE_COMMAND} -E copy_if_different "${VNN_BIN_PATH}/vnn_classifying.dll"   ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<CONFIG>
					COMMAND ${CMAKE_COMMAND} -E copy_if_different "${VNN_BIN_PATH}/vnn_pose.dll"   ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<CONFIG>
                    )



target_link_libraries (
    vnn_win_demo
    PUBLIC
    #debug       ${OPENCV_LIB_PATH}/opencv_world346d.lib
    optimized   ${OPENCV_LIB_PATH}/opencv_world346.lib )
