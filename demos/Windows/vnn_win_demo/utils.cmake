include(CMakeParseArguments)

function(assign_source_group group)
	foreach(_source IN ITEMS ${ARGN})
		if(IS_ABSOLUTE "${_source}")
			file(RELATIVE_PATH _source_rel "${CMAKE_CURRENT_SOURCE_DIR}" "${_source}")
		else()
			set(_source_rel "${_source}")
		endif()
		get_filename_component(_source_path "${_source_rel}" PATH)
		string(REPLACE "/" "\\" _source_path_msvc "${_source_path}")
		source_group("${group}\\${_source_path_msvc}" FILES "${_source}")
		#message(${group}\\${_source_path_msvc})
	endforeach()
endfunction(assign_source_group)
		