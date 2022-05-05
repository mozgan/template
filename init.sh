#!/usr/bin/env bash

RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

###############################################################################
### print_error(): print error message
print_error() {
    echo -e ${RED}${1}${RESET}; exit 1
}

###############################################################################
### print_info(): print info message
print_info() {
    echo -e ${GREEN}${1}${RESET}
}

[ ! -f "config" ] && print_error "Please use config.template to create file with name \"config\"!"

[ ! `command -v g++` ] && print_error "Please install g++!"
[ ! `command -v cmake` ] && print_error "Please install cmake!"

OS=`uname -s`
ARG=${1}
PRJ_NAME=""
FULLNAME=""
EMAIL=""
WWW=""

if [[ $OS == "Darwin" || $OS == "FreeBSD" ]]; then
    [ ! `command -v gsed` ] && print_error "Please install gnu-sed!"
    SED=`which gsed`
elif [ $OS == "Linux" ]; then
    SED=`which sed`
fi

###############################################################################
### usage(): show how to run
usage() {
    echo "Usage: ${0} [LIB | MAIN]" && exit 1
}
[ $# -ne 1 ] && usage

[ ! -f "config" ] && echo "config file not found!" && exit 1
FULLNAME=`grep '^FULLNAME' config | awk -F'=' '{ print $2 }'`
EMAIL=`grep '^EMAIL' config | awk -F'=' '{ print $2 }'`
printf -v EMAIL '%s' $EMAIL
WWW=`grep '^WWW' config | awk -F'=' '{ print $2 }'`
printf -v WWW '%s' $WWW

###############################################################################
### create_directory(): create directories include, src, and test
create_directories() {
    # rm -rf .git
    mkdir -p include
    mkdir -p src

    [ $ARG == "LIB" ] && mkdir -p test
}

###############################################################################
### prepare_cmake(): prepare CMakeLists.txt
prepare_cmake() {
    echo "cmake_minimum_required(VERSION 3.10)

### --- --- --- --- --- --- Version --- --- --- --- --- --- ###
set(VERSION_MAJOR 1)
set(VERSION_MINOR 0)
set(VERSION_PATCH 0)
set(VERSION_NO \${VERSION_MAJOR}.\${VERSION_MINOR}.\${VERSION_PATCH})

### --- --- --- --- --- --- --- Project name --- --- --- --- --- --- --- ###
"> CMakeLists.txt

    if [ $ARG == "MAIN" ]; then
        echo "project(${PRJ_NAME}
        VERSION \${VERSION_NO}
        HOMEPAGE_URL \"${WWW}\"
        DESCRIPTION \"Executable: ${PRJ_NAME}\"
        LANGUAGES \"CXX\"
)" >> CMakeLists.txt
    else
        echo "project(${PRJ_NAME}
        VERSION \${VERSION_NO}
        HOMEPAGE_URL \"${WWW}\"
        DESCRIPTION \"Library: ${PRJ_NAME}\"
        LANGUAGES \"CXX\"
)" >> CMakeLists.txt
    fi

    echo "
enable_language(C)
enable_language(CXX)

### --- --- --- --- --- --- --- File globbing --- --- --- --- --- --- --- ###
file(GLOB_RECURSE headers include/*.h)
file(GLOB_RECURSE sources src/*.cpp)
set(SOURCES \${headers} \${sources})

### --- --- --- Include directory --- --- --- ###
include_directories(include)

### --- --- --- --- --- --- --- Compiler --- --- --- --- --- --- --- ###
### --- --- --- Compiler definition --- --- --- ###
set(CMAKE_CXX_STANDARD 17)
#set(CMAKE_CXX_STANDARD 20)
#set(CMAKE_CXX_STANDARD 23)

### --- --- --- Compiler flags --- --- --- ###
### Compiler flags ###
# enable use of extra debugging information.
add_definitions(-g)

# enable all warnings about constructions that some users consider questionable.
add_definitions(-Wall)

# enable some extra warning flags that are not enabled by -Wall.
add_definitions(-Wextra)

# issue all the warnings demanded by strict ISO C/C++; reject all programs that
# use forbidden extensions, and some other programs that do not follow ISO C/C++.
add_definitions(-Wpedantic)

# do not warn about uses of functions, variables, and types marked as deprecated
# by using the deprecated attributes.
add_definitions(-Wno-deprecated-declarations)

# warn if declared variable, function, parameter etc. is not used.
add_definitions(-Wunused)

# warn when the order of member initializers given in the code does not match
# the order in which they must be executed.
add_definitions(-Wno-reorder)

# warn if the return type of a function has a type qualifier such as const.
add_definitions(-Wno-ignored-qualifiers)

# Warn about violations of the following style guidelines from Scott Meyers’
# Effective C++ series of books.
add_definitions(-Weffc++)

# Optimize even more.
#add_definitions(-O2)

# run the standard link-time optimizer. When invoked with source code,
# it generates GIMPLE and writes it to special ELF sections in the object file.
#add_definitions(-flto)

# During the link-time optimization, do not warn about type mismatches
# in global declarations from different compilation units.
#add_definitions(-Wlto-type-mismatch)

### --- --- --- --- --- --- Required libraries --- --- --- --- --- --- ###
### --- --- --- packages --- --- --- ###
#find_package(Threads REQUIRED)
#if (THREADS_FOUND)
#    message(STATUS \"CPP Threads found!\")
#else()
#    message(FATAL_ERROR \"CPP Threads not found!\")
#endif()

### --- --- --- static/shared libraries --- --- --- ###
#find_library(LIB_XXXXXX_FOUND
#    NAMES lib_xxxxxx       # lib_xxxxxx.a lib_xxxxxx.so lib_xxxxxx.dylib
#    HINTS /path/to/library
#)
#if (LIB_XXXXXX_FOUND)
#    message(STATUS \"Library XXXXXX found!\")
#else()
#    message(FATAL_ERROR \"Library XXXXXX not found!\")
#endif()

### --- --- --- --- --- --- Target definitions --- --- --- --- --- --- ###
" >> CMakeLists.txt

    if [ $ARG == "MAIN" ]; then
        echo "### --- --- --- executable --- --- --- ###
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY \${PROJECT_BINARY_DIR}/bin)
add_executable(\${CMAKE_PROJECT_NAME} \${SOURCES})


### --- --- --- --- --- --- Installation --- --- --- --- --- --- ###
set_property(TARGET \${PROJECT_NAME} PROPERTY POSITION_INDEPENDENT_CODE 1)
install(TARGETS \${PROJECT_NAME} DESTINATION bin COMPONENT applications)
" >> CMakeLists.txt
    else
        echo "### --- --- --- library --- --- --- ###
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY \${PROJECT_BINARY_DIR}/lib)
add_library(\${CMAKE_PROJECT_NAME} SHARED \${SOURCES})

### --- --- --- --- --- --- Gtest --- --- --- --- --- --- ###
find_library(GTEST_LIBRARY gtest)
if (GTEST_LIBRARY)
    enable_testing()
    add_subdirectory(test)
endif()

### --- --- --- --- --- --- Installation --- --- --- --- --- --- ###
#FILE(GLOB headers "\${PROJECT_SOURCE_DIR}/include/*.h")
install(FILES \${headers} DESTINATION include COMPONENT headers)

set_property(TARGET \${PROJECT_NAME} PROPERTY POSITION_INDEPENDENT_CODE 1)
install(TARGETS \${PROJECT_NAME} DESTINATION lib COMPONENT libraries)
" >> CMakeLists.txt

        echo "#pragma once" > include/${PRJ_NAME}.h
        echo "#include \"${PRJ_NAME}.h\"" > src/${PRJ_NAME}.cpp
    fi

    echo "### --- --- --- --- --- --- Dependencies --- --- --- --- --- --- ###
# Warning: use the extension \".dylib\" in macOS
#target_link_libraries(\${CMAKE_PROJECT_NAME} lib_xxxxxx.dylib)
# Warning: in Linux no extension requested
#target_link_libraries(\${CMAKE_PROJECT_NAME} add_some_lib)
#target_link_libraries(\${CMAKE_PROJECT_NAME} pthread)

### --- --- --- --- --- --- Cpack --- --- --- --- --- --- ###" >> CMakeLists.txt

    if [ $ARG == "MAIN" ]; then
        echo "set(CPACK_PACKAGE_NAME \${PROJECT_NAME})" >> CMakeLists.txt
    else
        echo "set(CPACK_PACKAGE_NAME lib\${PROJECT_NAME}-dev)" >> CMakeLists.txt
    fi

    echo "
set(CPACK_PACKAGE_VENDOR \"${FULLNAME}\")
set(CPACK_PACKAGE_CONTACT \"${EMAIL}\")
set(CPACK_PACKAGE_HOMEPAGE_URL \"${WWW}\")
set(CPACK_PACKAGE_VERSION \${VERSION_NO})
set(CPACK_PACKAGE_FILE_NAME \${CPACK_PACKAGE_NAME}-\${VERSION_NO}-\${CMAKE_SYSTEM_PROCESSOR})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY \"\${CMAKE_PROJECT_DESCRIPTION}\")
" >> CMakeLists.txt

    if [ $ARG == "MAIN" ]; then
        echo "set(CPACK_COMPONENTS_ALL applications)" >> CMakeLists.txt
        echo "set(CPACK_COMPONENT_APPLICATIONS_DISPLAY_NAME \"\${CMAKE_PROJECT_NAME}\")" >> CMakeLists.txt
        echo "set(CPACK_COMPONENT_APPLICATIONS_DESCRIPTION \"\${CMAKE_PROJECT_DESCRIPTION}\")" >> CMakeLists.txt
    else
        echo "set(CPACK_COMPONENTS_ALL libraries headers)" >> CMakeLists.txt
        echo "set(CPACK_COMPONENT_LIBRARIES_DISPLAY_NAME \"\${CMAKE_PROJECT_NAME}\")" >> CMakeLists.txt
        echo "set(CPACK_COMPONENT_LIBRARIES_DESCRIPTION \"\${CMAKE_PROJECT_DESCRIPTION}\")" >> CMakeLists.txt
        echo "set(CPACK_COMPONENT_HEADERS_DISPLAY_NAME \"C++ Headers\")" >> CMakeLists.txt
        echo "set(CPACK_COMPONENT_HEADERS_DESCRIPTION \"C++ Headers for the library \${CMAKE_PROJECT_NAME}\")" >> CMakeLists.txt
    fi

    echo "
set(CPACK_PACKAGING_INSTALL_PREFIX \"/usr/local\")

if (EXISTS \"\${CMAKE_CURRENT_SOURCE_DIR}/LICENSE.txt\")
    set(CPACK_RESOURCE_FILE_LICENSE \"\${CMAKE_CURRENT_SOURCE_DIR}/LICENSE.txt\")
    install(FILES \${CMAKE_CURRENT_SOURCE_DIR}/LICENSE.txt DESTINATION /tmp)
endif()

if (EXISTS \"\${CMAKE_CURRENT_SOURCE_DIR}/README.txt\")
    set(CPACK_RESOURCE_FILE_README \"\${CMAKE_CURRENT_SOURCE_DIR}/README.txt\")
    install(FILES \${CMAKE_CURRENT_SOURCE_DIR}/README.txt DESTINATION /tmp)
endif()

set(CPACK_SET_DESTDIR ON)
set(CPACK_STRIP_FILES ON)
set(CPACK_SOURCE_STRIP_FILES ON)

if (\${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    if (EXISTS \"\${CMAKE_CURRENT_SOURCE_DIR}/WELCOME.txt\")
        set(CPACK_RESOURCE_FILE_WELCOME \"\${CMAKE_CURRENT_SOURCE_DIR}/WELCOME.txt\")
    endif()

    set(CPACK_GENERATOR \"productbuild;TGZ\")
    set(CPACK_SOURCE_GENERATOR \"TGZ\")
elseif (\${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    file(STRINGS \"/etc/os-release\" os_name REGEX \"^NAME=\")

    # create deb package for Debian and Ubuntu
    if(\${os_name} MATCHES \"^(NAME)=\\\"(Debian GNU/Linux|Ubuntu)\\\"\$\")
        set(CPACK_DEBIAN_PACKAGE_DESCRIPTION \"\${CMAKE_PROJECT_DESCRIPTION}\")
        set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
        set(CPACK_DEBIAN_PACKAGE_DEPENDS \"\")
        set(CPACK_DEBIAN_PACKAGE_MAINTAINER \${CPACK_PACKAGE_VENDOR})
        set(CPACK_DEBIAN_PACKAGE_SECTION contrib/devel)
        set(CPACK_GENERATOR \"DEB;TGZ\")
    else()
        set(CPACK_GENERATOR \"TGZ\")
    endif()

    set(CPACK_SOURCE_GENERATOR \"TGZ\")
elseif (\${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")
    set(CPACK_FREEBSD_PACKAGE_DESCRIPTION \"\${CMAKE_PROJECT_DESCRIPTION}\")
    set(CPACK_FREEBSD_PACKAGE_LICENSE \"MIT\")
    set(CPACK_FREEBSD_PACKAGE_DEPS \"\")
    set(CPACK_FREEBSD_PACKAGE_MAINTAINER \${CPACK_PACKAGE_VENDOR})
    set(CPACK_SOURCE_GENERATOR \"TGZ\")
else()
    set(CPACK_SOURCE_GENERATOR \"TGZ\")
endif()

set(CPACK_SOURCE_IGNORE_FILES \"\${CMAKE_SOURCE_DIR}/build/;\${CMAKE_SOURCE_DIR}/_build/;\${CMAKE_SOURCE_DIR}/.git/\")

include(CPack)
" >> CMakeLists.txt
}

###############################################################################
### create_main(): create src/main.cpp file
create_main() {
    echo "#include <stdlib.h>

#include <iostream>

using namespace std;

int main(int argc, char* argv[]) {
  cout << \"#args: \" << argc << endl;
  cout << \"@prog: \" << argv[0] << endl;

  exit(EXIT_SUCCESS);
}
" > src/main.cpp
}

###############################################################################
### create_test(): prepare test/CMakeLists.txt and test/${PRJ_NAME}_test
create_test() {
    echo "cmake_minimum_required(VERSION 3.10)

find_package(GTest REQUIRED)
include_directories(\${GTEST_INCLUDE_DIRS})

set(${PRJ_NAME}_TEST ${PRJ_NAME}_test)


add_executable(\${${PRJ_NAME}_TEST} ${PRJ_NAME}_test.cpp)
add_test(NAME \${${PRJ_NAME}_TEST} COMMAND \${${PRJ_NAME}_TEST})
target_link_libraries(\${${PRJ_NAME}_TEST} PUBLIC \${CMAKE_PROJECT_NAME} \${GTEST_LIBRARIES} \${GTEST_MAIN_LIBRARIES} pthread)
" > test/CMakeLists.txt

    echo "#include \"${PRJ_NAME}.h\"

#include <iostream>

#include <gtest/gtest.h>

using namespace std;

TEST(${PRJ_NAME}_test, test_case) {  }
" > test/${PRJ_NAME}_test.cpp
}

###############################################################################
### do_test(): do a test
do_test() {
    mkdir -p _build && cd _build
    cmake .. && make

    if [ $ARG == "MAIN" ]; then
        #read -p "Do you want to test application? (y/n) " ans
        #answer=${ans^^}
        #if [[ $answer == "Y" || $answer == "YES" ]]; then
            ./bin/${PRJ_NAME}
        #fi
    else
        ./test/${PRJ_NAME}_test
    fi
}

###############################################################################
### update_license()
update_license() {
    $SED -i -e "s/YEAR/`date +'%Y'`/g" LICENSE.txt
    $SED -i -e "s/FULLNAME/${FULLNAME}/g" LICENSE.txt
    $SED -i -e "s/EMAIL/${EMAIL}/g" LICENSE.txt
}

###############################################################################
### update_welcome()
update_welcome() {
    $SED -i -e "s/PRJ_NAME/${PRJ_NAME}/g" WELCOME.txt
}

###############################################################################
### create_package()
create_package() {
    cpack
}

###############################################################################
### main()
main() {
    ### check ARG
    case $ARG in
        "LIB" | "MAIN")
            ### Get Project Name ###
            read -p "Give project name: " PRJ_NAME
            [ -z ${PRJ_NAME} ] && print_error "Project name should not be empty!"

            print_info "Project name: $PRJ_NAME \nOperating system: $OS \nFullname: $FULLNAME \nE-Mail: $EMAIL \nHomepage: $WWW"
            read -p "Are the above information correnct? (y/n) " ans
            answer=${ans^^}

            if [[ $answer == "N" || $answer == "NO" ]]; then
                exit 1
            fi

            update_license
            [ $OS == "Darwin" ] && update_welcome

            create_directories
            prepare_cmake

            if [ $ARG == "MAIN" ]; then
                create_main
            else
                create_test
            fi

            do_test
            create_package
            ;;
        *)
            usage
    esac
}

main

