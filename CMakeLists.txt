if(MSVC)
	# needed for CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS support
	cmake_minimum_required(VERSION 3.4)
else()
	cmake_minimum_required(VERSION 2.8.7)
endif()
project(pixelpulse2 CXX C)

# libsmu versioning
set(PP_VERSION_MAJOR 1)
set(PP_VERSION_MINOR 0)
set(PP_VERSION_PATCH 2)
set(PP_VERSION ${PP_VERSION_MAJOR}.${PP_VERSION_MINOR}.${PP_VERSION_PATCH})

# determine a more descriptive project version using git info if available
set(PP_VERSION_STR ${PP_VERSION})
if(IS_DIRECTORY ${CMAKE_SOURCE_DIR}/.git)
	# determine if the current revision is a tag
	execute_process(COMMAND git describe --exact-match --tags HEAD
		WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
		OUTPUT_VARIABLE PP_TAG_VERSION
		OUTPUT_STRIP_TRAILING_WHITESPACE
		ERROR_QUIET
	)
	# if the current revision isn't a tag, add git revision info
	if(PP_TAG_VERSION STREQUAL "")
		execute_process(COMMAND git rev-parse --short HEAD
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
			OUTPUT_VARIABLE PP_GIT_REV
			OUTPUT_STRIP_TRAILING_WHITESPACE
			ERROR_QUIET
		)
		set(PP_VERSION_STR ${PP_VERSION_STR}-g${PP_GIT_REV})
	endif()
endif()

# Set .exe properties
if (WIN32)
	string(REPLACE "." "," PP_FILEVERSION ${PP_VERSION})
	set(PP_PRODUCTVERSION_STR ${PP_VERSION})
	string(TIMESTAMP BUILD_YEAR "%Y")
endif()

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)

if (NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING
		"Choose the type of build, options are: None(CMAKE_CXX_FLAGS or CMAKE_C_FLAGS used) Debug Release RelWithDebInfo MinSizeRel."
		FORCE)
	set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS None Debug Release RelWithDebInfo MinSizeRel)
endif()

# write version info to file -- used for CI artifact versioning
file(WRITE ${CMAKE_BINARY_DIR}/.version ${PP_VERSION_STR})

find_package(Qt5Widgets REQUIRED)
find_package(Qt5Quick REQUIRED)
find_package(Qt5Qml REQUIRED)
find_package(Qt5Network REQUIRED)

string(TIMESTAMP BUILD_DATE "%Y/%m/%d")
set(GIT_VERSION ${PP_GIT_REV})
configure_file(config.h.cmakein ${CMAKE_BINARY_DIR}/config.h @ONLY)
configure_file(pixelpulse2.iss.cmakein ${CMAKE_CURRENT_BINARY_DIR}/pixelpulse2.iss @ONLY)

# use pkg-config for everything that's not Windows
if(NOT WIN32)
	include(FindPkgConfig REQUIRED)
	pkg_check_modules(LIBUSB REQUIRED libusb-1.0)
	link_directories(${LINK_DIRECTORIES} ${LIBUSB_LIBRARY_DIRS})
else()
	find_library(LIBUSB_LIBRARIES usb-1.0)
	find_path(LIBUSB_INCLUDE_DIRS libusb.h)
endif()

find_library(LIBSMU_LIBRARIES smu)
find_path(LIBSMU_INCLUDE_DIRS libsmu/libsmu.hpp)


# generate version header
if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -pedantic -std=c++11")
endif()
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DDEBUG_BUILD")

# don't complain about extra format args for g++
if(CMAKE_COMPILER_IS_GNUCXX)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-format-extra-args")
endif()

include(GNUInstallDirs)

# set default install path to /usr
if (NOT WIN32 AND CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
	set(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "default install path" FORCE)
endif()

# handle RPATH issues on OS X
if(APPLE)
	set(CMAKE_MACOSX_RPATH ON)
	set(CMAKE_SKIP_BUILD_RPATH FALSE)
	set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
	set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_LIBDIR}")
	set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
	list(FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES "${CMAKE_INSTALL_LIBDIR}" isSystemDir)
	if("${isSystemDir}" STREQUAL "-1")
		set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_LIBDIR}")
	endif()
endif()

FILE(GLOB PP_RESOURCES *.qrc)
qt5_add_resources(pixelpulse_RESOURCES ${PP_RESOURCES})

FILE(GLOB QML_SRC "qml/*.qml")

if (WIN32)
	set(RESOURCES ${CMAKE_CURRENT_BINARY_DIR}/properties.rc)
	configure_file(properties.rc.cmakein ${RESOURCES} @ONLY)
endif()

FILE(GLOB SRC_LIST  *.cpp
	Plot/*.cpp
	utils/*.cpp
	utils/*.h
)


include_directories(
	${LIBUSB_INCLUDE_DIRS}
	${LIBSMU_INCLUDE_DIRS}
	${Qt5Widgets_INCLUDE_DIRS}
	${Qt5Quick_INCLUDE_DIRS}
	${Qt5Qml_INCLUDE_DIRS}
	${Qt5Network_INCLUDE_DIRS}
	${CMAKE_SOURCE_DIR}/Plot
	${CMAKE_SOURCE_DIR}/utils
	${CMAKE_SOURCE_DIR}
)

add_executable(${PROJECT_NAME} WIN32 ${OSX_BUNDLE}
		${SRC_LIST}
		${pixelpulse_RESOURCES}
		${RESOURCES}
#		${QML_SRC}
)

# Compiler options
target_compile_options(${PROJECT_NAME} PUBLIC -Wall)

#List of warnings to be treated as errors
target_compile_options(${PROJECT_NAME} PUBLIC
	-Werror=return-type
	-Werror=uninitialized
	-Werror=init-self
	-Werror=switch
)

if (WIN32 OR ENABLE_APPLICATION_BUNDLE)
	message("================ Set target properties ")
	set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME pixelpulse2)
endif()

target_link_libraries(${PROJECT_NAME} LINK_PRIVATE
		${LIBUSB_LIBRARIES}
		${LIBSMU_LIBRARIES}
		${Qt5Widgets_LIBRARIES}
		${Qt5Quick_LIBRARIES}
		${Qt5Qml_LIBRARIES}
		${Qt5Network_LIBRARIES}
)


if (NOT WIN32)
	find_library(PTHREAD_LIBRARIES pthread)
	if (PTHREAD_LIBRARIES)
		target_link_libraries(${PROJECT_NAME} LINK_PRIVATE ${PTHREAD_LIBRARIES})
	endif()
endif()

if (APPLE)
	option(ENABLE_APPLICATION_BUNDLE "Enable application bundle for OSX" ON)
endif(APPLE)

if (ENABLE_APPLICATION_BUNDLE)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fvisibility=hidden")

	set(PKGINFO ${CMAKE_BINARY_DIR}/PkgInfo)
	file(WRITE ${PKGINFO} "APPLPixelpulse")
	set_source_files_properties(${PKGINFO} PROPERTIES MACOSX_PACKAGE_LOCATION .)

	set(QT_CONF ${CMAKE_BINARY_DIR}/qt.conf)
	file(WRITE ${QT_CONF} "")
	set_source_files_properties(${QT_CONF} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)

	set(ICON_FILE ${CMAKE_SOURCE_DIR}/icons/pp2.icns)
	set_source_files_properties(${ICON_FILE} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)

	set(CMAKE_EXE_LINKER_FLAGS "-Wl,-headerpad_max_install_names -Wl,-search_paths_first ${CMAKE_EXE_LINKER_FLAGS}")

	foreach(plugin ${Qt5Gui_PLUGINS} ${Qt5Svg_PLUGINS})
		get_target_property(_loc ${plugin} LOCATION)
		get_filename_component(_name ${_loc} NAME)
		get_filename_component(_dir ${_loc} DIRECTORY)
		get_filename_component(_dir ${_dir} NAME)

		set_source_files_properties(${_loc} PROPERTIES MACOSX_PACKAGE_LOCATION plugins/${_dir})
		set(QT_PLUGINS ${QT_PLUGINS} ${_loc})
		set(BUNDLED_QT_PLUGINS ${BUNDLED_QT_PLUGINS} ${CMAKE_BINARY_DIR}/Pixelpulse2.app/Contents/plugins/${_dir}/${_name})
	endforeach()

	install(CODE "
		set(BU_CHMOD_BUNDLE_ITEMS ON)
		include(BundleUtilities)
		fixup_bundle(\"${CMAKE_BINARY_DIR}/Pixelpulse2.app\" \"${BUNDLED_QT_PLUGINS}\" \"${CMAKE_SOURCE_DIR}\")"
	)

	set(OSX_BUNDLE MACOSX_BUNDLE)
	set(EXTRA_BUNDLE_FILES ${QT_PLUGINS} ${ICON_FILE} ${PKGINFO} ${QT_CONF})
endif()

if (NOT ENABLE_APPLICATION_BUNDLE)
	install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION bin)
	install(FILES ${CMAKE_SOURCE_DIR}/icons/pp2.ico DESTINATION share/icons/hicolor/apps/scalable RENAME pp2.ico)
endif()
