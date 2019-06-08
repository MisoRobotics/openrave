# This macro can be used to install symlinks, which turns out to be
# non-trivial due to CMake version differences and limitations on how
# files can be installed when building binary packages.
#
# The rule for binary packaging is that files (including symlinks) must
# be installed with the standard CMake install() macro.
#
# The rule for non-binary packaging is that CMake 2.6 cannot install()
# symlinks, but can create the symlink at install-time via scripting.
# Though, we assume that CMake 2.6 isn't going to be used to generate
# packages because versions later than 2.8.3 are superior for that purpose.
#
#   _filepath: the absolute path to the file to symlink
#   _sympath: absolute path of the installed symlink

macro(InstallSymlink _filepath _sympath)
    set(oneValueArgs COMPONENT)
    cmake_parse_arguments(INSTALL_SYMLINK "" "${oneValueArgs}" "" ${ARGN} )
    get_filename_component(_symname ${_sympath} NAME)
    get_filename_component(_installdir ${_sympath} PATH)

    if (BINARY_PACKAGING_MODE)
        execute_process(COMMAND "${CMAKE_COMMAND}" -E create_symlink
                        ${_filepath}
                        ${CMAKE_CURRENT_BINARY_DIR}/${_symname})
        install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${_symname}
                DESTINATION ${_installdir})
    else ()
        # scripting the symlink installation at install time should work
        # for CMake 2.6.x and 2.8.x
        install(CODE "
            if (\"\$ENV{DESTDIR}\" STREQUAL \"\")
                execute_process(COMMAND \"${CMAKE_COMMAND}\" -E create_symlink
                                ${_filepath}
                                ${_installdir}/${_symname})
            else ()
                execute_process(COMMAND \"${CMAKE_COMMAND}\" -E create_symlink
                                ${_filepath}
                                \$ENV{DESTDIR}/${_installdir}/${_symname})
            endif ()
        ")

        # Create a package.links file to be used as a Debian package control file.
        if (DEFINED INSTALL_SYMLINK_COMPONENT)
          add_custom_target(
            ${_symname}_link ALL
            ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/symlinks
            COMMAND ${CMAKE_COMMAND} -E create_symlink ${_filepath} ${CMAKE_CURRENT_BINARY_DIR}/symlinks/${_symname})
          if (IS_DIRECTORY ${_filepath})
            install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/symlinks/${_symname}
              DESTINATION ${_installdir}
              COMPONENT ${INSTALL_SYMLINK_COMPONENT})
          else()
            install(
              FILES ${CMAKE_CURRENT_BINARY_DIR}/symlinks/${_symname}
              DESTINATION ${_installdir}
              COMPONENT ${INSTALL_SYMLINK_COMPONENT})
          endif()
        else ()
            set(XCPACK_DEBIAN_PACKAGE_LINKS "${XCPACK_DEBIAN_PACKAGE_LINKS};${_filepath}	${_sympath}" CACHE INTERNAL "Package Links")
        endif ()
    endif ()
endmacro(InstallSymlink)
