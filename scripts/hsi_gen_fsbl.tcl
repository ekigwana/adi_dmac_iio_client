set this_file [ dict get [ info frame [ info frame ] ] file ]
set this_path [file dirname $this_file]

set sysdef_file $::env(SYSDEF_FILE)
set base_dir $::env(BASE_DIR)
set project_name $::env(PROJECT_NAME)
set REQUIRED_HSI_VERSION $::env(REQUIRED_HSI_VERSION)

if {![info exists REQUIRED_HSI_VERSION]} {
	set REQUIRED_HSI_VERSION "2018.2"
}

if {[info exists ::env(IGNORE_VERSION_CHECK)]} {
	set IGNORE_VERSION_CHECK 1
} elseif {![info exists IGNORE_VERSION_CHECK]} {
	set IGNORE_VERSION_CHECK 0
}

proc hsi_project_create {project_name} {
	global REQUIRED_HSI_VERSION
	global IGNORE_VERSION_CHECK
	global base_dir
	global sysdef_file

	if {!$IGNORE_VERSION_CHECK && [string compare [version -short] $REQUIRED_HSI_VERSION] != 0} {
		return -code error [format "ERROR: This project requires HSI %s." $REQUIRED_HSI_VERSION]
	}

	set hw_design_file [file tail $sysdef_file ]
	file mkdir hw_design
	set hw_design_file "hw_design/$hw_design_file"
	file copy -force $sysdef_file $hw_design_file

	hsi::open_hw_design $hw_design_file
	hsi::generate_app -dir $base_dir -hw [hsi::current_hw_design] -sw fsbl -proc ps7_cortexa9_0 -app zynq_fsbl -compile
	hsi::close_hw_design [hsi::current_hw_design]
}

hsi_project_create $project_name
exit
