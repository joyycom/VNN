cmake_minimum_required(VERSION 3.5)
project(vnn_android)
add_library(vnnjni SHARED ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/vnnjni.cpp)
target_include_directories(vnnjni PUBLIC ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/include)
#add_library(vnn_core
#        SHARED
#        IMPORTED)
#set_target_properties(vnn_core
#        PROPERTIES IMPORTED_LOCATION
#        ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/libs/${ANDROID_ABI}/libvnn_core.so)
#add_library(vnn_kit
#        SHARED
#        IMPORTED)
#set_target_properties(vnn_kit
#        PROPERTIES IMPORTED_LOCATION
#        ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/libs/${ANDROID_ABI}/libvnn_kit.so)
#add_library(vnn_face
#        SHARED
#        IMPORTED)
#set_target_properties(vnn_face
#        PROPERTIES IMPORTED_LOCATION
#        ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/libs/${ANDROID_ABI}/libvnn_face.so)
#target_link_libraries(vnnjni PUBLIC vnn_core vnn_kit vnn_face)

find_library(vnn_core-lib vnn_core PATHS ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/libs/${ANDROID_ABI}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_kit-lib vnn_kit PATHS ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/libs/${ANDROID_ABI}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_face-lib vnn_face PATHS ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/libs/${ANDROID_ABI}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_faceparser-lib vnn_faceparser PATHS ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/libs/${ANDROID_ABI}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_stylizing-lib vnn_stylizing PATHS ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/libs/${ANDROID_ABI}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_face_reenactment-lib vnn_face_reenactment PATHS ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/libs/${ANDROID_ABI}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_gesture-lib vnn_gesture PATHS ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/libs/${ANDROID_ABI}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_objcount-lib vnn_objcount PATHS ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/libs/${ANDROID_ABI}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_objtracking-lib vnn_objtracking PATHS ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/libs/${ANDROID_ABI}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_docrect-lib vnn_docrect PATHS ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/libs/${ANDROID_ABI}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_general-lib vnn_general PATHS ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/libs/${ANDROID_ABI}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_classifying-lib vnn_classifying PATHS ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/libs/${ANDROID_ABI}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(vnn_pose-lib vnn_pose PATHS ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp/libs/${ANDROID_ABI}/ NO_CMAKE_FIND_ROOT_PATH)
find_library(log-lib log)
find_library(dl-lib dl)
find_library(android-lib android)
target_link_libraries(vnnjni
        ${log-lib}
        ${dl-lib}
        ${android-lib}
        ${vnn_core-lib}
        ${vnn_kit-lib}
        ${vnn_face-lib}
        ${vnn_faceparser-lib}
        ${vnn_stylizing-lib}
        ${vnn_face_reenactment-lib}
        ${vnn_gesture-lib}
        ${vnn_objcount-lib}
        ${vnn_objtracking-lib}
        ${vnn_docrect-lib}
        ${vnn_general-lib}
        ${vnn_classifying-lib}
        ${vnn_pose-lib}
        )