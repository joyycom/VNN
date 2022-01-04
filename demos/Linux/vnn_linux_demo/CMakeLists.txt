cmake_minimum_required(VERSION 3.8.0)

add_compile_options(-std=c++11)

project(vnn_linux_demo)
	
SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

set(ROOT_PATH ${CMAKE_CURRENT_LIST_DIR})
set(BUILD_PATH ${CMAKE_BINARY_DIR})  # set the build path

set(OPENCV_PATH "/usr/local")



file(GLOB_RECURSE  DEMO_SOURCE "demo/src/*.cpp" "demo/src/*.h" "demo/inc/*.h")

include_directories(${ROOT_PATH}/demo/inc )
include_directories(${CMAKE_CURRENT_LIST_DIR}/prebuilt/inc)

SET(CMKAE_DEBUG_POSTFIX "d" CACHE STRING "add a postfix, usually d on windows")
SET(CMAKE_RELEASE_POSTFIX "" CACHE STRING "add a postfix, usually empty on windows")

# include_directories(${OPENCV_PATH}/include)

add_executable(${PROJECT_NAME} ${DEMO_SOURCE})



set(VNN_LIB_PATH "${CMAKE_CURRENT_LIST_DIR}/prebuilt/lib")
set(OPENCV_LIB_PATH "${OPENCV_PATH}/lib")
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
target_link_libraries(${PROJECT_NAME}
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


find_library(opencv_core-lib opencv_core PATHS ${OPENCV_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(opencv_imgproc-lib opencv_imgproc PATHS ${OPENCV_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(opencv_highgui-lib opencv_highgui PATHS ${OPENCV_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(opencv_imgcodecs-lib opencv_imgcodecs PATHS ${OPENCV_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(opencv_videoio-lib opencv_videoio PATHS ${OPENCV_LIB_PATH}/ NO_CMAKE_FIND_ROOT_PATH)


target_link_libraries(${PROJECT_NAME}
        ${opencv_core-lib}
        ${opencv_imgproc-lib}
        ${opencv_highgui-lib}
        ${opencv_imgcodecs-lib}
        ${opencv_videoio-lib}
		)
