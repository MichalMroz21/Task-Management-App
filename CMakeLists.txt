cmake_minimum_required(VERSION 3.24)

project(Task-Management-App VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_DIR ${CMAKE_CURRENT_LIST_DIR}/cmake)
set(INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/include)
set(SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/source)

#Some libraries are header-only and some require building, this separation is required as boost is added both with find_package and submodules
#As described here: https://www.boost.org/doc/libs/1_84_0/more/getting_started/windows.html#header-only-libraries
#The name has to be BOOST_INCLUDE_LIBRARIES!
set(BOOST_INCLUDE_LIBRARIES algorithm)
set(BOOST_BUILD_LIBRARIES)
set(BOOST_ENABLE_CMAKE ON)

set(QT_INCLUDE_LIBRARIES Quick)

option(MAKE_TEST_EXE "Run GTests" ON)

#CMakeConfig.hpp Constants
add_definitions(-DROOT_PATH_CMAKE=${CMAKE_CURRENT_SOURCE_DIR})

#Macros
include(${CMAKE_DIR}/UpdateSubmodules.cmake)
include(${CMAKE_DIR}/AddFiles.cmake)

#QT6 is required to be installed
find_package(Qt6 6.4 REQUIRED COMPONENTS ${QT_INCLUDE_LIBRARIES})

#Boost and GTest can be downloaded via git submodules
find_package(Boost COMPONENTS ${BOOST_BUILD_LIBRARIES})
find_package(GTest)

#Set dependencies if found or not by find_package
#If not found then get from git submodules
add_subdirectory(dependencies)

#Create executable
qt_standard_project_setup()
qt_add_executable(appTask-Management-App)
qt_policy(SET QTP0001 NEW)

#Get cpp files to add to Executables
file(GLOB_RECURSE SOURCE_FILES ${SOURCE_DIR}/*.cpp)

#Get include files to add to Executables (Required for MOC)
file(GLOB_RECURSE INCLUDE_FILES ${INCLUDE_DIR}/*.hpp)

#Get project files
add_subdirectory(include)
add_subdirectory(source)
add_subdirectory(source_gui)
add_subdirectory(assets)

#Files in include can be included with just a file name now
target_include_directories(appTask-Management-App PRIVATE
    ${INCLUDE_DIR}
)

if(${Boost_FOUND})
    target_include_directories(appTask-Management-App PRIVATE ${Boost_INCLUDE_DIRS})
endif()

#Transform library names into proper form for linking
list(TRANSFORM BOOST_BUILD_LIBRARIES PREPEND "Boost::")
list(TRANSFORM BOOST_INCLUDE_LIBRARIES PREPEND "Boost::")
list(TRANSFORM QT_INCLUDE_LIBRARIES PREPEND "Qt6::")

#Combine 2 lists into one
list(APPEND BOOST_LIBRARIES ${BOOST_BUILD_LIBRARIES})
list(APPEND BOOST_LIBRARIES ${BOOST_INCLUDE_LIBRARIES})

#Link to main application
target_link_libraries(appTask-Management-App
    PRIVATE ${BOOST_LIBRARIES} ${QT_INCLUDE_LIBRARIES}
)

#Add resources and GUI files
qt_add_qml_module(appTask-Management-App
    URI Task-Management-App
    VERSION 1.0
    RESOURCE_PREFIX "/"

    QML_FILES ${QML_FILES}
    RESOURCES ${RESOURCES}
)

#Create separate Tester executables that runs tests
if(MAKE_TEST_EXE)
    include(CTest)
    add_subdirectory(tests)
endif()

set_target_properties(appTask-Management-App PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

install(TARGETS appTask-Management-App
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

#cmake -B build -S . -G "MinGW Makefiles" && cd build && make && cd ..
#cmake -B build -S . -G "MinGW Makefiles" && cd build && make && cd tests && export GTEST_COLOR=1 && ./Tester.exe
