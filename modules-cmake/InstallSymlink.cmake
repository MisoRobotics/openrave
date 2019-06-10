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
    set(_onevalueargs COMPONENT)
    cmake_parse_arguments(INSTALL_SYMLINK "" "${_onevalueargs}" "" ${ARGN} )
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
          execute_process(COMMAND "date" "+%s%N" OUTPUT_VARIABLE _timestamp_now OUTPUT_STRIP_TRAILING_WHITESPACE)
          set(_symlink_dir ${CMAKE_CURRENT_BINARY_DIR}/symlinks/${_timestamp_now})
          add_custom_target(
            ${_symname}_${_timestamp_now}_link_ ALL
            ${CMAKE_COMMAND} -E make_directory ${_symlink_dir}
            COMMAND ${CMAKE_COMMAND} -E create_symlink ${_filepath} ${_symlink_dir}/${_symname})
          if (IS_DIRECTORY ${_filepath})
            install(DIRECTORY ${_symlink_dir}/${_symname}
              DESTINATION ${_installdir}
              COMPONENT ${INSTALL_SYMLINK_COMPONENT})
          else()
            install(
              FILES ${_symlink_dir}/${_symname}
              DESTINATION ${_installdir}
              COMPONENT ${INSTALL_SYMLINK_COMPONENT})
          endif()
        endif ()
    endif ()
endmacro(InstallSymlink)
