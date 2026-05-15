# Copyright (c) 2020 Intel Corporation. All rights reserved.

# Your use of Intel Corporation's design tools, logic functions
# and other software and tools, and any partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Intel Program License 
# Subscription Agreement, the Intel Quartus Prime License Agreement,
# the Intel FPGA IP License Agreement, or other applicable license
# agreement, including, without limitation, that your use is for
# the sole purpose of programming logic devices manufactured by
# Intel and sold by Intel or its authorized distributors.  Please
# refer to the applicable agreement for further details, at
# https://fpgasoftware.intel.com/eula.


load_package advanced_device
package require Tcl 8.4
package req json::write
package req json

set list_pins_config_and_info [dict create] 
set pin_config_file "pin_config.json"

proc dict2json {dictToEncode} {
	set accumulate {}
        
    #dict for {key value} $dictToEncode {
    #    if { ([llength $value] > 1) && ($key != "IO_STANDARD") } {
    #        lappend accumulate $key [dict2json $value]
    #    } else {
    #        lappend accumulate $key [json::write string $value]
    #    }
    #}
	
    return [json::write object {*}[dict map {k v} $dictToEncode {
    json::write object {*}[dict map {_k _v} $v {json::write string $_v}]}]]
}

proc read_json { input_json_file } {
	set fp [open $input_json_file r]
	set file_data [read $fp]
	close $fp
	
	return $file_data
}

proc json_convert_to_dict { json_data } {
	return [json::json2dict $json_data]
}


############################################################################
proc pre_syn_generate_all_pins {is_pre_syn} {
#
#   Description : 	This function populates a preliminary pin_config file with all the device's pin
#   Return      : 	None
#   Remarks     :	Pre-synthesis flow does not have the .pin file (where all pins config are stored)
# 					We substitute the query of the .pin file using this default pin populated pin config file instead
#
############################################################################
	
	if {$is_pre_syn != "True"} {
		return
	}

	global list_pins_config_and_info
	set total_pins [get_pkg_data INT_PIN_COUNT]
	
	for {set pin_number 0} {$pin_number < $total_pins} {incr pin_number} {
		set pin_name ""
		set is_bonded [get_pkg_data BOOL_IS_BONDED -pin $pin_number]

		# Pin location
		set ball_assignment [get_pkg_data STRING_USER_PIN_NAME -pin $pin_number] 

		# Pin direction
		set is_vcc 0
		[catch {set is_vcc [get_pkg_data BOOL_IS_VCC -pin $pin_number]}]
		set is_vss 0
		[catch {set is_vss [get_pkg_data BOOL_IS_VSS -pin $pin_number]}]
		set direction ""
		if {$is_vss} {
			set direction "gnd"
			set pin_name [get_pkg_data STRING_TYPE_NAME -pin $pin_number]
		}
		if {$is_vcc} {
			set direction "power"
			set pin_name [get_pkg_data STRING_TYPE_NAME -pin $pin_number]
		}

		set bank_name ""

		if {$is_bonded} {
			set pad_list [get_pkg_data LIST_PAD_IDS -pin_name $ball_assignment] 
			set first_pad [lindex $pad_list 0]
			set io_bank_list [get_pad_data VEC_STRING_IOBANK_NAMES]
			set bank_id 0
			catch { set bank_id [get_pad_data INT_IO_BANK_ID -pad $first_pad] }
			set bank_name [lindex $io_bank_list $bank_id]
		}

		set io_std ""
		set voltage ""
		set pad_id ""
		set pin_UID ""
		set pin_type ""
		if {$is_bonded} {
			# Use pad default io standard if no special handling required
			set pad_default_io_std [get_user_name -io_standard [get_pad_data INT_DEFAULT_IO_STANDARD]]
			set pad_list [get_pkg_data LIST_PAD_IDS -pin_name $ball_assignment]
			set pad_id [lindex $pad_list 0]
			set io_std_list [get_pad_data LIST_IO_STANDARDS -pad $pad_id]
			# IO STD special handling
			# HPS and SDM pads defaults to 1.8V
			# HVIO defaults to LVCMOS33
			# HSSI special handling
			# - HSSI pins do not support the pad's default IO standard
			set pin_UID [get_pad_data -pad $pad_id STRING_UID]
			switch -glob $pin_UID {
				*hvio* { set io_std "LVCMOS_33" }
				*hps* { set io_std "1.8-V" }
				*sdm* { set io_std "1.8-V" }
				*hssi* {set io_std [lindex $io_std_list 0]}
				default { set io_std $pad_default_io_std }
			}
			# Voltage
			set io_std [get_user_name -io_standard $io_std]
			set voltage_string [get_pad_data INT_VOLTAGE_TYPE -io_standard $io_std]
			if {[regexp {(\d+)_(\d+)} $voltage_string match v1 v2]} {
				append voltage $v1 "." $v2 "V"
			}
			#  Pin Type
			set pin_type [get_pad_data -pad $pad_id STRING_TYPE_NAME]
			set pin_type [string map {/ ""} $pin_type]
			dict lappend list_pins_config_and_info $ball_assignment "PIN_TYPE" $pin_type

		}
		
		dict append list_pins_config_and_info $ball_assignment
		dict lappend list_pins_config_and_info $ball_assignment "NODE_NAME" ""
		dict lappend list_pins_config_and_info $ball_assignment "DIRECTION" $direction
		dict lappend list_pins_config_and_info $ball_assignment "STRING_TYPE" $pin_name
		dict lappend list_pins_config_and_info $ball_assignment "USER_ASSIGNMENT" ""
		dict lappend list_pins_config_and_info $ball_assignment "IO_BANK" $bank_name
		dict lappend list_pins_config_and_info $ball_assignment "PAD_ID" $pad_id
		dict lappend list_pins_config_and_info $ball_assignment "UID" $pin_UID
		dict lappend list_pins_config_and_info $ball_assignment "PIN_TYPE" $pin_UID
		dict lappend list_pins_config_and_info $ball_assignment "IO_STANDARD" $io_std
		dict lappend list_pins_config_and_info $ball_assignment "VOLTAGE" $voltage
	}

	# Write into pin_config.json
	set json [dict2json $list_pins_config_and_info]
	set file [open "./pin_config.json" w] 
	puts $file $json
	close $file

}

proc get_open_drain_default { pin_config_variable ball_assignment pin_default_info panel_id } {
	global list_pins_config_and_info

	if {$panel_id != -1}  {
		if {[catch { set user_setting [string toupper [get_report_panel_data -id $panel_id -row_name "[dict get $list_pins_config_and_info $ball_assignment NODE_NAME]" -col_name "Open Drain"]] }]} {
			#Do nothing
		} else {
			if { $user_setting != "NO" } {
				if { $user_setting != "YES" } {
					dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $user_setting
				} elseif {  $user_setting == "YES" } {
					# This is due to boolean in Quartus fitter plan report only will show Yes/No. IF "Yes", means being configured by customer.
					dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable "ON"
				}
			}
		}
	}
			
	if { ![dict exists $list_pins_config_and_info $ball_assignment $pin_config_variable] } {
		if {$pin_default_info eq ""} {
			set default_open_drain ""
		} else {
			#The open drain mapping is coming from handle_open_drain_supports (falconmesa_io_standard_gen.pl)
			# The first index in the list is the default_open_drain
			if {[catch { get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info }]} {
				# This is due to GPIO pin does not have 2D_INT_VALID_OPEN_DRAIN_SUPPORTS_VALUES in pad ddb
				set pin_uid [dict get $list_pins_config_and_info $ball_assignment UID]
				switch -glob $pin_uid {
					*hvio* { set default_open_drain "" }
					*hps* { set default_open_drain "" }
					*sdm* { set default_open_drain "" }
					default { set default_open_drain $pin_default_info }
				}
			} else {
				switch -exact [lindex [lindex [get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info] 0] 0] {
					0 { set default_open_drain "OFF"}
					1 { set default_open_drain "ON"}
					default { set default_open_drain ""}
				}
			}
		}
		
		dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $default_open_drain
	}
}

proc get_current_strength_default { pin_config_variable ball_assignment pin_default_info panel_id } {
	global list_pins_config_and_info
	
	set pin_uid [dict get $list_pins_config_and_info $ball_assignment UID]
	switch -glob $pin_uid {
		*hvio* { 
			# HVIO currently does not have the list 
			set default_current_strength $pin_default_info 
		}
		*hps* { 
			if {[catch { get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info }]} {
				set default_current_strength ""
			} else {
				#The current strength mapping is coming from handle_drive_strength_control (falconmesa_io_standard_gen.pl)
				# The first index in the list is the default current strength
				switch -exact [lindex [lindex [get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info] 0] 0] {
					0 { set default_current_strength "8MA"}
					1 { set default_current_strength "2MA"}
					2 { set default_current_strength "4MA"}
					3 { set default_current_strength "6MA"}
					4 { set default_current_strength "12MA"}
					5 { set default_current_strength "16MA"}
					6 { set default_current_strength "10MA"}
					default { set default_current_strength ""}
				}
			}
		}
		*hssi* {
			# HSSI currently does not have the list 
			set default_current_strength $pin_default_info 
		}
		default { 
			if {$pin_default_info eq ""} {
				set default_current_strength ""
			} else {
				if {[catch { get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info }]} {
					set default_current_strength ""
				} else {
					switch -exact [lindex [lindex [get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info] 0] 0] {
						0 { set default_current_strength "8MA"}
						1 { set default_current_strength "2MA"}
						2 { set default_current_strength "4MA"}
						3 { set default_current_strength "6MA"}
						4 { set default_current_strength "12MA"}
						5 { set default_current_strength "16MA"}
						6 { set default_current_strength "10MA"}
						default { set default_current_strength ""}
					}
				}
			}
		}
	}
	
	dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $default_current_strength
}

proc get_bus_hold_default { pin_config_variable ball_assignment pin_default_info panel_id } {
	global list_pins_config_and_info
	
	if {$panel_id != -1}  {
		if {[catch { set user_setting [string toupper [get_report_panel_data -id $panel_id -row_name "[dict get $list_pins_config_and_info $ball_assignment NODE_NAME]" -col_name "Bus Hold"]] }]} {
			#Do nothing
		} else {
			if { $user_setting != "NO" } {
				if { $user_setting != "YES" } {
					dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $user_setting
				} elseif {  $user_setting == "YES" } {
					# This is due to boolean in Quartus fitter plan report only will show Yes/No. IF "Yes", means being configured by customer.
					dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable "ON"
				}
			}
		}
	}
			
	if { ![dict exists $list_pins_config_and_info $ball_assignment $pin_config_variable] } {
	
		dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $pin_default_info
	}
}

proc get_hps_odt_default { pin_config_variable ball_assignment pin_default_info panel_id } {
	global list_pins_config_and_info
	
	dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $pin_default_info
}

proc get_input_termination_default { pin_config_variable ball_assignment pin_default_info panel_id } {
	global list_pins_config_and_info
	set default_input_termination ""
	
	if {$panel_id != -1}  {
		if { [dict get $list_pins_config_and_info $ball_assignment DIRECTION] == "input" } {
			if {[catch { set default_input_termination [string toupper [get_report_panel_data -id $panel_id -row_name "[dict get $list_pins_config_and_info $ball_assignment NODE_NAME]" -col_name "Termination"]] }]} {
				#Do nothing
			}
		} else {
			if {[catch { set default_input_termination [string toupper [get_report_panel_data -id $panel_id -row_name "[dict get $list_pins_config_and_info $ball_assignment NODE_NAME]" -col_name "Input Termination"]] }]} {
				#Do nothing
			}
		}
	}
			
	if { $default_input_termination == "" || $default_input_termination == "NO" } {
		if {$pin_default_info eq ""} {
			#Do nothing
		} else {
			if {[catch { set default_input_termination [string toupper [get_user_name -termination [get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info] ]]}]} {
				set default_input_termination ""
			}
		}
	}

	# This is due to database or fitter plan report have possibility to have different kind of OCT value especially bidir
	if { [string match "SERIES*" $default_input_termination ] } {
		set default_input_termination ""
	}

	# During fitter plan, HSSI REFCLK IP will also assign rx_onchip_termination_setting as the INPUT_TERMINATION value
	# HSSI REFCLK pins uses the RX_ONCHIP_TERMINATION_SETTING atttribute to determine the input termination, assign to both attributes
	if {[regexp -nocase "rx_onchip_termination_setting=(.*)" $default_input_termination match termination_value]} {
		dict lappend list_pins_config_and_info $ball_assignment "RX_ONCHIP_TERMINATION_SETTING" $termination_value
		dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $termination_value
	} else {
		dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $default_input_termination
	}
	
}

proc get_output_termination_default { pin_config_variable ball_assignment pin_default_info panel_id } {
	global list_pins_config_and_info
	set default_output_termination ""
	
	if {$panel_id != -1}  {
		if { [dict get $list_pins_config_and_info $ball_assignment DIRECTION] == "output" } {
			if {[catch { set default_output_termination [string toupper [get_report_panel_data -id $panel_id -row_name "[dict get $list_pins_config_and_info $ball_assignment NODE_NAME]" -col_name "Termination"]] }]} {
				#Do nothing
			}
		} else {
			if {[catch { set default_output_termination [string toupper [get_report_panel_data -id $panel_id -row_name "[dict get $list_pins_config_and_info $ball_assignment NODE_NAME]" -col_name "Output Termination"]] }]} {
				#Do nothing
			}
		}
	}
			
	if { $default_output_termination == "" || $default_output_termination == "NO" } {
	
		if {$pin_default_info eq ""} {
			#Do nothing
		} else {
			if {[catch { set default_output_termination [string toupper [get_user_name -termination [get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info] ]]}]} {
				set default_output_termination ""
			}
		}
	}
	
	# This is due to database or fitter plan report have possibility to have different kind of OCT value especially bidir
	if { [string match "PARALLEL*" $default_output_termination ] } {
		set default_output_termination ""
	}
	dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $default_output_termination
}

proc get_deemphasis_default { pin_config_variable ball_assignment pin_default_info panel_id } {
	global list_pins_config_and_info
	
	if {$pin_default_info eq ""} {
		set default_deemphasis ""
	} else {
		if {[catch { get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info }]} {
			set default_deemphasis ""
		} else {
			#The deemphasis mapping is coming from handle_deemphasis (falconmesa_io_standard_gen.pl)
			# The first index in the list is the default deemphasis
			switch -exact [lindex [lindex [get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info] 0] 0] {
				0 { set default_deemphasis "OFF"}
				1 { set default_deemphasis "LOW_LP"}
				2 { set default_deemphasis "MEDIUM_LP"}
				3 { set default_deemphasis "HIGH_LP"}
				4 { set default_deemphasis "LOW_CZ"}
				5 { set default_deemphasis "MEDIUM_CZ"}
				6 { set default_deemphasis "HIGH_CZ"}
				default { set default_deemphasis ""}
			}
		}
	}
	
	dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $default_deemphasis
}

proc get_vod_default { pin_config_variable ball_assignment pin_default_info panel_id } {
	global list_pins_config_and_info
	
	if {$panel_id != -1}  {
		if {[catch { set user_setting [string toupper [get_report_panel_data -id $panel_id -row_name "[dict get $list_pins_config_and_info $ball_assignment NODE_NAME]" -col_name "Voltage Output Differential"]] }]} {
			#Do nothing
		} else {
			if { $user_setting != "NO" } {
				dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $user_setting
			}
		}
	}
			
	if { ![dict exists $list_pins_config_and_info $ball_assignment $pin_config_variable] } {
	
		if {$pin_default_info eq ""} {
			set default_vod ""
		} else {
			if {[catch { get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info }]} {
				set default_vod ""
			} else {
				#The vod mapping is coming from handle_vod (falconmesa_io_standard_gen.pl)
				# The first index in the list is the default vod
				set default_vod [lindex [lindex [get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info] 0] 0]
			}
		}
		
		dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $default_vod
	}
}

proc get_preemphasis_default { pin_config_variable ball_assignment pin_default_info panel_id} {
	global list_pins_config_and_info
	
	if {$panel_id != -1}  {
		if {[catch { set user_setting [string toupper [get_report_panel_data -id $panel_id -row_name "[dict get $list_pins_config_and_info $ball_assignment NODE_NAME]" -col_name "Output Buffer Pre-emphasis"]] }]} {
			#Do nothing
		} else {
			if { $user_setting != "NO" } {
				dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $user_setting
			}
		}
	}
			
	if { ![dict exists $list_pins_config_and_info $ball_assignment $pin_config_variable] } {
	
		if {$pin_default_info eq ""} {
			set default_preemphasis ""
		} else {
			if {[catch { get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info }]} {
				set default_preemphasis ""
			} else {
				#The preemphasis mapping is coming from handle_preemphasis (falconmesa_io_standard_gen.pl)
				# The first index in the list is the default preemphasis
				set default_preemphasis [lindex [lindex [get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info] 0] 0]
			}
		}
		
		dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $default_preemphasis
	}
}

proc get_receiver_equalization_default { pin_config_variable ball_assignment pin_default_info panel_id } {
	global list_pins_config_and_info
	
	if {$pin_default_info eq ""} {
		set default_receiver_equalization ""
	} else {
		if {[catch { get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info }]} {
			set default_receiver_equalization ""
		} else {
			#The receiver_equalization mapping is coming from handle_rx_equalization (falconmesa_io_standard_gen.pl)
			# The first index in the list is the default receiver_equalization
			switch -exact [lindex [lindex [get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info] 0] 0] {
				0 { set default_receiver_equalization "OFF"}
				1 { set default_receiver_equalization "ON"}
				2 { set default_receiver_equalization "SMALL"}
				3 { set default_receiver_equalization "MEDIUM"}
				4 { set default_receiver_equalization "LARGE"}
				default { set default_receiver_equalization ""}
			}
		}
	}
	
	dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $default_receiver_equalization
}

proc get_schmitt_trigger_default { pin_config_variable ball_assignment pin_default_info panel_id } {
	global list_pins_config_and_info
	
	if {$pin_default_info eq ""} {
		set default_schmitt_trigger ""
	} else {
		if {[catch { get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info }]} {
			set default_schmitt_trigger ""
		} else {
			#The schmitt_trigger mapping is coming from handle_hysteresis_supports (falconmesa_io_standard_gen.pl)
			# The first index in the list is the default schmitt_trigger
			switch -exact [lindex [lindex [get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info] 0] 0] {
				0 { set default_schmitt_trigger "OFF"}
				1 { set default_schmitt_trigger "ON"}
				default { set default_schmitt_trigger ""}
			}
		}
	}
	
	dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $default_schmitt_trigger
}

proc get_slew_rate_default { pin_config_variable ball_assignment pin_default_info panel_id } {
	global list_pins_config_and_info
	
	if {$panel_id != -1}  {
		if {[catch { set user_setting [string toupper [get_report_panel_data -id $panel_id -row_name "[dict get $list_pins_config_and_info $ball_assignment NODE_NAME]" -col_name "Slew Rate"]] }]} {
			#Do nothing
		} else {
			if { $user_setting != "NO" } {
				dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $user_setting
			}
		}
	}
			
	if { ![dict exists $list_pins_config_and_info $ball_assignment $pin_config_variable] } {
	
		if {$pin_default_info eq ""} {
			set default_slew_rate ""
		} else {
			if {[catch { get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info } fid]} {
				set default_slew_rate ""
			} else {
				#The slew_rate mapping is coming from get_slew_rate_index (falconmesa_io_standard_gen.pl)
				# The first index in the list is the default slew_rate
				set default_slew_rate [lindex [lindex [get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info] 0] 0]
			}
		}
		
		dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $default_slew_rate
	}
}

proc get_weak_pullup_pulldown_default { pin_config_variable ball_assignment pin_default_info panel_id } {
	global list_pins_config_and_info
	
	if {$pin_default_info eq ""} {
		set default_weak_pullup_pulldown ""
	} else {
		if {[catch { get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info } fid]} {
			set default_weak_pullup_pulldown ""
		} else {
			#The weak_pullup_pulldown mapping is coming from handle_weak_pull_control (falconmesa_io_standard_gen.pl)
			# The first index in the list is the default weak_pullup_pulldown
			switch -exact [lindex [lindex [get_pad_data -io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD] $pin_default_info] 0] 0] {
				0 { set default_weak_pullup_pulldown "NO_PULL_UP_DN"}
				1 { set default_weak_pullup_pulldown "PULL_UP_20"}
				2 { set default_weak_pullup_pulldown "PULL_UP_50"}
				3 { set default_weak_pullup_pulldown "PULL_UP_80"}
				4 { set default_weak_pullup_pulldown "PULL_DN_20"}
				5 { set default_weak_pullup_pulldown "PULL_DN_50"}
				6 { set default_weak_pullup_pulldown "PULL_DN_80"}
				default { set default_weak_pullup_pulldown ""}
			}
		}
	}
	
	dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $default_weak_pullup_pulldown
}

proc get_weak_pulldown_default { pin_config_variable ball_assignment pin_default_info panel_id } {
	global list_pins_config_and_info
	
	dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $pin_default_info
}

proc get_weak_pullup_default { pin_config_variable ball_assignment pin_default_info panel_id } {
	global list_pins_config_and_info
	
	if {$panel_id != -1}  {
		if {[catch { set user_setting [string toupper [get_report_panel_data -id $panel_id -row_name "[dict get $list_pins_config_and_info $ball_assignment NODE_NAME]" -col_name "Weak Pull Up"]] }]} {
			#Do nothing
		} else {
			if { $user_setting != "NO" } {
				if { $user_setting != "YES" } {
					dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $user_setting
				} elseif {  $user_setting == "YES" } {
					# This is due to boolean in Quartus fitter plan report only will show Yes/No. IF "Yes", means being configured by customer.
					dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable "ON"
				}
			}
		}
	}
			
	if { ![dict exists $list_pins_config_and_info $ball_assignment $pin_config_variable] } {
	
		dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $pin_default_info
	}
}

proc get_rx_onchip_termination_setting_default { pin_config_variable ball_assignment pin_default_info panel_id } {
	global list_pins_config_and_info
	set user_pin_node_name [dict get $list_pins_config_and_info $ball_assignment NODE_NAME]
	
	foreach_in_collection asgn_id [get_all_assignments -type instance -name HSSI_PARAMETER] {
		set assigned_node [get_assignment_info -to $asgn_id]
		if {![string match $user_pin_node_name $assigned_node]} {
			# Continue if the assignment is not for the current ball assignment
			continue
		}
		set assignment_val [get_assignment_info $asgn_id -value]
		# Check if the HSSI_PARAMETER has the termination key, assign if found 
		if {[regexp -nocase "${pin_config_variable}=(.*)" $assignment_val match termination_value]} {
			dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $termination_value
		} else {
			continue
		}
	}
	
	# Default value assignment if no user configuration found
	if { ![dict exists $list_pins_config_and_info $ball_assignment $pin_config_variable] } {
		if {$pin_default_info eq ""} {
			set rx_onchip_termination_setting_default ""
		} else {
			set rx_onchip_termination_setting_default $pin_default_info
		}
		dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $rx_onchip_termination_setting_default
	}
}

proc get_tolerant_voltage_setting_default { pin_config_variable ball_assignment pin_default_info panel_id } {
	global list_pins_config_and_info
	set user_pin_node_name [dict get $list_pins_config_and_info $ball_assignment NODE_NAME]
	
	foreach_in_collection asgn_id [get_all_assignments -type instance -name HSSI_PARAMETER] {
		set assigned_node [get_assignment_info -to $asgn_id]
		if {![string match $user_pin_node_name $assigned_node]} {
			# Continue if the assignment is not for the current ball assignment
			continue
		}
		set assignment_val [get_assignment_info $asgn_id -value]
		# The tolerant voltage defaults to 2.5, and is controlled by refclk_divider_enable_3p3v
		# This means that:
		# refclk_divider_enable_3p3v=disable_3p3v_tol is equivalent to 2.5V
		# refclk_divider_enable_3p3v=enable_3p3v_tol is equivalent to 3.3V
		if {[regexp -nocase "refclk_divider_enable_3p3v=(.*)" $assignment_val match assinged_value]} {
			dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $assinged_value
		} else {
			continue
		}
	}
	
	# Default value assignment if no user configuration found
	if { ![dict exists $list_pins_config_and_info $ball_assignment $pin_config_variable] } {
		if {$pin_default_info eq ""} {
			set tolerant_voltage_setting_default ""
		} else {
			set tolerant_voltage_setting_default $pin_default_info
		}
		dict lappend list_pins_config_and_info $ball_assignment $pin_config_variable $tolerant_voltage_setting_default
	}
}


proc get_pad_id { is_pre_syn } {

	if { $is_pre_syn == "True" } {
		# Pre-synthesis pre-populates all pins with their pad ID at pre_syn_generate_all_pins
		return
	}

	global list_pins_config_and_info
	set total_pins [get_pkg_data INT_PIN_COUNT]

	for { set pin_number 0 } { $pin_number < $total_pins } { incr pin_number } {
		set ball_assignment [get_pkg_data STRING_USER_PIN_NAME -pin $pin_number]
		
		if { [dict exists $list_pins_config_and_info $ball_assignment] } {
			set bond_info ""
			if { [get_pkg_data BOOL_IS_BONDED -pin $pin_number] } {
				set pad_list [get_pkg_data LIST_PAD_IDS -pin_name $ball_assignment]
				set bond_info [lindex $pad_list 0]
			} else {
				set bond_info [get_pkg_data STRING_TYPE_NAME -pin $pin_number]
			}
			
			dict lappend list_pins_config_and_info $ball_assignment "PAD_ID" $bond_info
		}
	}
}

proc get_pin_and_IO_type {is_pre_syn} {
	global list_pins_config_and_info
	if { $is_pre_syn == "True"} {
		# Pre-synthesis pre-populates all pins with their Pin UID and Pin Type at pre_syn_generate_all_pins
		return
	} else {
		foreach ball_assignment [dict keys $list_pins_config_and_info] {
			set pin_type [get_pad_data -pad [dict get $list_pins_config_and_info $ball_assignment PAD_ID] STRING_TYPE_NAME]
			set pin_type [string map {/ ""} $pin_type]
			dict lappend list_pins_config_and_info $ball_assignment "PIN_TYPE" $pin_type
			
			set pin_UID [get_pad_data -pad [dict get $list_pins_config_and_info $ball_assignment PAD_ID] STRING_UID]
			dict lappend list_pins_config_and_info $ball_assignment "UID" $pin_UID
		}
	}
}

proc get_user_node_name_from_config_pin { is_pre_syn } {
	global list_pins_config_and_info
	global pin_config_file
	
	if { $is_pre_syn == "True" } {
		set has_iobank_without_location_assignment "False"
		# Pre-synthesis flow queries from the qsf file directly
		foreach_in_collection asgn_id [get_all_assignments -type instance -name LOCATION] {
			# User assignments based on location
			if {[regexp {PIN_} [get_assignment_info $asgn_id -value]]} {
				set ball_assignment  [string map {"PIN_" ""}  [get_assignment_info $asgn_id -value]]
				set assigned_node [get_assignment_info -to $asgn_id]
				dict append list_pins_config_and_info $ball_assignment
				dict lappend list_pins_config_and_info $ball_assignment "NODE_NAME" $assigned_node
				dict lappend list_pins_config_and_info $ball_assignment "USER_ASSIGNMENT" "Y"
			# This condition checks if the user assigned a pin with io bank but no location
			} elseif {[regexp {IOBANK_} [get_assignment_info $asgn_id -value]]} {
				set has_iobank_without_location_assignment "True"
			}
		}
		# This if block processes user assigned pins with io bank but no location
		if {$has_iobank_without_location_assignment == "True"} {
			foreach_in_collection asgn_id [get_all_assignments -type instance -name LOCATION] { 
				if {![regexp {IOBANK_} [get_assignment_info $asgn_id -value]]} {
					continue
				}
				# Get the assignment's node name
				set auto_location_assignment_node [get_assignment_info -to $asgn_id]

				# Get the assignment node's io_std if configured
				set assignment_node_io_std ""
				# Find the io std assignment node that matches the current auto assignment node
				foreach_in_collection io_std_asgn_id [get_all_assignments -type instance -name IO_STANDARD] {
					set current_io_std_assignment_node [get_assignment_info $io_std_asgn_id -to]
					if {[string match $auto_location_assignment_node $current_io_std_assignment_node]} {
						set assignment_node_io_std [get_assignment_info $io_std_asgn_id -value]
					}
				}
				set iobank [string map {"IOBANK_" ""} [get_assignment_info $asgn_id -value]]
				set found_auto_assignment_location "False"

				# This flag is used for pin validity checking
				# Specifically for post processing to inform if the suitable pins have ran out, or there wasn't a pin that suits the criteria
				set found_suitable_pin_for_assignment "False"

				foreach ball_assignment [dict keys $list_pins_config_and_info] {
					# Loop through the list of pins that have the same IO Bank as the user defined io bank
					set pin_io_bank [dict get $list_pins_config_and_info $ball_assignment IO_BANK]
					if {[catch {[get_pkg_data BOOL_IS_BONDED -pin_name $ball_assignment]}]} {
						# This catch block catches the invalid pins populated from failed auto assignments
						continue
					}
					if {![string match $pin_io_bank $iobank] || ![get_pkg_data BOOL_IS_BONDED -pin_name $ball_assignment] } {
						# Skip not bonded pins and non matching IO bank pins
						continue
					}
					# Special handling if the user has specific the IO standard of this specific assignment
					set pin_supports_stated_io_std "False"
					if {$assignment_node_io_std != ""} {
						set pad_id [dict get $list_pins_config_and_info $ball_assignment PAD_ID]
						set pin_supported_io_std_list [get_pad_data LIST_IO_STANDARDS -pad $pad_id]
						# We need to convert the IO standard list to customer facing names hence we use loop
						foreach pin_supported_io_std $pin_supported_io_std_list {
							set user_facing_io_std [get_user_name -io_standard $pin_supported_io_std]
							if {[string match -nocase $user_facing_io_std $assignment_node_io_std]} {
								set pin_supports_stated_io_std "True"
							}
						}
						# Skip this pin if the pin doesn't have the supported IO standard
						if {$pin_supports_stated_io_std == "False" } {
							continue
						}
					}
					# At this point, the script has found a pin with matching criteria
					set found_suitable_pin_for_assignment "True"
					# Skip already occupied pins
					if {[dict get $list_pins_config_and_info $ball_assignment NODE_NAME] != ""} { 
						continue
					}
					# Assigns the user assignment to this unused pin
					dict lappend list_pins_config_and_info $ball_assignment "NODE_NAME" $auto_location_assignment_node
					dict lappend list_pins_config_and_info $ball_assignment "USER_ASSIGNMENT" "Y"
					# This indicates the pin is an auto assigned, and will be post processed by the generate_atom_netlist to warn the user
					dict lappend list_pins_config_and_info $ball_assignment "AUTO_ASSIGNED_LOCATION" "TRUE"
					set found_auto_assignment_location "True"
					break
				}
				# Check if auto assignment was not performed due to all pins are occupied/no matching criteria
				if { $found_auto_assignment_location != "True" } {
					# Use node name as key as we do not have the ball assignment
					# The rest are placeholder values for other functions that need them
					dict lappend list_pins_config_and_info $auto_location_assignment_node
					dict lappend list_pins_config_and_info $auto_location_assignment_node "NODE_NAME" $auto_location_assignment_node
					dict lappend list_pins_config_and_info $auto_location_assignment_node "FAILED_AUTO_ASSIGNMENT" "TRUE"
					dict lappend list_pins_config_and_info $auto_location_assignment_node "IO_BANK" $iobank
					dict lappend list_pins_config_and_info $auto_location_assignment_node "IO_STANDARD" $assignment_node_io_std
        			dict lappend list_pins_config_and_info $auto_location_assignment_node "DIRECTION" ""
        			dict lappend list_pins_config_and_info $auto_location_assignment_node "STRING_TYPE" ""
        			dict lappend list_pins_config_and_info $auto_location_assignment_node "PAD_ID" ""
        			dict lappend list_pins_config_and_info $auto_location_assignment_node "PIN_TYPE" ""
        			dict lappend list_pins_config_and_info $auto_location_assignment_node "UID" ""

					if { $found_suitable_pin_for_assignment == "True" } {
						dict lappend list_pins_config_and_info $auto_location_assignment_node "SUITABLE_PINS_ARE_OCCUPIED" "TRUE"
					} else {
						dict lappend list_pins_config_and_info $auto_location_assignment_node "NO_PINS_WITH_MATCHING_CONFIG" "TRUE"
					}
				}
			}

		}

	} else {
		# Default IBIS flow reads from the preliminary pin_config file
		# Have to load this package in here due to this is only can called by quartus_fit
		load_package design
		load_package report

		design::load_design -latest_snapshot
		load_report
		
		set pin_config_json [ read_json $pin_config_file ]
		set dict_variable [json_convert_to_dict $pin_config_json]
		
		foreach ball_assignment [dict keys $dict_variable] {
			if { ! [dict exists $list_pins_config_and_info $ball_assignment] } {
				dict append list_pins_config_and_info $ball_assignment
				dict lappend list_pins_config_and_info $ball_assignment "NODE_NAME" [dict get $dict_variable $ball_assignment NODE_NAME]
				dict lappend list_pins_config_and_info $ball_assignment "DIRECTION" [dict get $dict_variable $ball_assignment DIRECTION]
				dict lappend list_pins_config_and_info $ball_assignment "IO_STANDARD" [string toupper [dict get $dict_variable $ball_assignment IO_STANDARD]]
			}
		}	
	}
}

proc get_pin_io_standard { } {
	# IO standard and its associated voltage are assigned here

	global list_pins_config_and_info
	
	# User assigned IO standard and its voltage
	foreach_in_collection asgn_id [get_all_assignments -type instance -name IO_STANDARD] {
		set assigned_node [get_assignment_info $asgn_id -to]
		foreach ball_assignment [dict keys $list_pins_config_and_info] {
			# Skip pins without node name assignment
			if {[dict get $list_pins_config_and_info $ball_assignment NODE_NAME] == ""} {
				continue
			} 
			# Assign user configured pin settings
			if { [dict get $list_pins_config_and_info $ball_assignment NODE_NAME] == $assigned_node } {
				set io_standard  [get_user_name -io_standard [get_assignment_info $asgn_id -value]]
				dict lappend list_pins_config_and_info $ball_assignment "IO_STANDARD" $io_standard
				# Read voltage from the io standard
				set voltage_string [get_pad_data INT_VOLTAGE_TYPE -io_standard $io_standard]
				if {[regexp {(\d+)_(\d+)} $voltage_string match v1 v2]} {
					set voltage ""
					append voltage $v1 "." $v2 "V"
					dict lappend list_pins_config_and_info $ball_assignment "VOLTAGE" $voltage
				}
			}
		}
	}

}


proc get_user_pin_io_bank {} {
	global list_pins_config_and_info

	# Override any default io bank with user configured io bank from the qsf file
	foreach_in_collection asgn_id [get_all_assignments -type instance -name LOCATION] {
		set comments [get_assignment_info -comments $asgn_id]
		if {[regexp "IOBANK_(.+)" $comments match group]} {
			set assigned_node [get_assignment_info $asgn_id -to]
			foreach ball_assignment [dict keys $list_pins_config_and_info] {
				# Skip pins without node name assignment
				if {[dict get $list_pins_config_and_info $ball_assignment NODE_NAME] == ""} {
					continue
				} 
				# Assign user configured pin settings
				if { [dict get $list_pins_config_and_info $ball_assignment NODE_NAME] == $assigned_node } {
					dict lappend list_pins_config_and_info $ball_assignment "IO_BANK" $group
				}
			}
		} 
	}
	# For user pins without pin location but with io bank assignments, 
	# the script auto assigns it to pins with matching IO bank at get_user_node_name_from_config_pin
	
}
	
proc get_pin_name {} {

	# In certain scenarios, we would want to have the pin name configured to a specific pin_name instead of NC
	global list_pins_config_and_info

	foreach ball_assignment [dict keys $list_pins_config_and_info] { 
		# Skip unbonded pins 
		if {[catch {[get_pkg_data BOOL_IS_BONDED -pin_name $ball_assignment]}]} {
			# This catch block catches the invalid pins populated from failed auto assignments
			continue
		}
		if {![get_pkg_data BOOL_IS_BONDED -pin_name $ball_assignment]} {
			continue
		}
		set pad_list [get_pkg_data LIST_PAD_IDS -pin_name $ball_assignment] 
		set first_pad [lindex $pad_list 0]
		set auxiliary_pin_name [get_pad_data STRING_AUXILIARY_FUNCTION_NAME -pad $first_pad]
		set index_of_comma [string first "," $auxiliary_pin_name]
		# Only retrieve the substring before the first comma, if a comma is inside the pad auxiliary name
		if {$index_of_comma >= 0} {
			set auxiliary_pin_name [string range $auxiliary_pin_name 0 [expr $index_of_comma - 1]]
		}
		# Update this regex if more pins require a specific pin name
		if {[regexp {(HPS|SDM)} $auxiliary_pin_name match dump]} {
			dict lappend list_pins_config_and_info $ball_assignment "PIN_NAME" $auxiliary_pin_name
		}
			
	}

}


proc get_pin_config { is_pre_syn qsf_variable_mapping part_num qsf_variable_json_filename} {
	global list_pins_config_and_info
	set device_type [string range $part_num 0 2]
	set device [get_part_info -device $part_num]
	set devie_list_json_file [string map {"devices_qsf_variable_mapping.json" "devices_list.json"} $qsf_variable_json_filename]
	set device_list [read_json $devie_list_json_file]
	set device_list_dict [json_convert_to_dict $device_list]
	set dict_variable [json_convert_to_dict $qsf_variable_mapping]
	
	if { [dict exists $device_list_dict $device_type "SPECIAL_DEVICE_HANDLING" $device] } {
		set device_type [dict get $device_list_dict $device_type "SPECIAL_DEVICE_HANDLING" $device]
	}
	
	set input_panel_id 0
	set bidir_panel_id -1
	set output_panel_id -1
	if { $is_pre_syn == "True" } {
		foreach_in_collection asgn_id [get_all_assignments -type instance -name RESERVE_PIN] {
			set assigned_node [get_assignment_info $asgn_id -to]
			foreach ball_assignment [dict keys $list_pins_config_and_info] {
				# Skip pins without node name assignment
				if {[dict get $list_pins_config_and_info $ball_assignment NODE_NAME] == ""} {
					continue
				} 
				# Assign user configured pin settings
				if { [dict get $list_pins_config_and_info $ball_assignment NODE_NAME] == $assigned_node } {
					set direction ""
					set user_assinged_direction [get_assignment_info $asgn_id -value]
					if {[regexp {INPUT} $user_assinged_direction]} {
						set direction "input"
					} elseif {[regexp {OUTPUT} $user_assinged_direction]} {
						set direction "output"
					} elseif {[regexp {BIDIR} $user_assinged_direction]} {
						set direction "bidir"
					}
					dict lappend list_pins_config_and_info $ball_assignment "DIRECTION"  $direction
				}
			}
		}

	} else {
		# Default IBIS flow has access to report package, we query overwrite the panel id based on the project configurations
		set input_panel_id [get_report_panel_id {Fitter||Plan Stage||Input Pins}]
		set bidir_panel_id [get_report_panel_id {Fitter||Plan Stage||Bidir Pins}]
		set output_panel_id [get_report_panel_id {Fitter||Plan Stage||Output Pins}]
	} 	

	# This dictionary processes generic device QSF assignments 
	foreach variable [dict keys $dict_variable] {
		if {$is_pre_syn == "True"} {
			foreach_in_collection asgn_id [get_all_assignments -type instance -name $variable] {
				set assigned_node [get_assignment_info $asgn_id -to]
				set pin_config [get_assignment_info $asgn_id -value]
				foreach ball_assignment [dict keys $list_pins_config_and_info] {
					# Skip pins without node name assignment
					if {[dict get $list_pins_config_and_info $ball_assignment NODE_NAME] == ""} {
						continue
					} 
					# Assign user configured pin settings
					if { [dict get $list_pins_config_and_info $ball_assignment NODE_NAME] == $assigned_node } {
						dict lappend list_pins_config_and_info $ball_assignment $variable $pin_config
					}
				}
			}
		} else {
			foreach asgn_id [design::get_assignments -enabled -name $variable] {
				foreach ball_assignment [dict keys $list_pins_config_and_info] {
					# Skip pins without node name assignment
					if {[dict get $list_pins_config_and_info $ball_assignment NODE_NAME] == ""} {
						continue
					} 
					# Assign user configured pin settings
					if { [dict get $list_pins_config_and_info $ball_assignment NODE_NAME] == [design::get_assignment_info -to $asgn_id] } {
						set pin_config [string toupper [design::get_assignment_info -value $asgn_id]]
						dict lappend list_pins_config_and_info $ball_assignment $variable $pin_config
						break
					}
					
				}
			}
		}
		
		foreach ball_assignment [dict keys $list_pins_config_and_info] {
			if { ! [dict exists $list_pins_config_and_info $ball_assignment $variable] } {
				if {$is_pre_syn == "True" && [dict exists $list_pins_config_and_info $ball_assignment USER_ASSIGNMENT] && [dict get $list_pins_config_and_info $ball_assignment USER_ASSIGNMENT] == ""} {
					continue
				} else {
					set called_function [dict get $dict_variable $variable FUNCTION]
					set pin_uid [dict get $list_pins_config_and_info $ball_assignment UID]

					switch -glob $pin_uid {
						*hps* { set pin_default_info [ dict get $dict_variable $variable $device_type HPS ] }
						*sdm* { set pin_default_info [ dict get $dict_variable $variable $device_type SDM ] }
						*hvio* { set pin_default_info [ dict get $dict_variable $variable $device_type HVIO ] }
						*hssi* { set pin_default_info [ dict get $dict_variable $variable $device_type XCVR ] } 
						default { set pin_default_info [ dict get $dict_variable $variable $device_type GPIO ] }
					}
					
					# If pre-synthesis is true, the script only updates the direction of those that are user assgined
					# Defaults the pin direction to input if no assignments were found
					set pin_direction "input"
					if { [dict get $list_pins_config_and_info $ball_assignment DIRECTION] != "" } {
						set pin_direction [dict get $list_pins_config_and_info $ball_assignment DIRECTION]
					# This indicates the user assigned pin did not have a direction assigned
					} elseif {[dict get $list_pins_config_and_info $ball_assignment NODE_NAME] != ""} {
						dict lappend list_pins_config_and_info $ball_assignment "AUTO_ASSIGNED_DIRECTION" "TRUE"
					}
					
					dict lappend list_pins_config_and_info $ball_assignment DIRECTION $pin_direction
					
					switch $pin_direction {
						input { $called_function $variable $ball_assignment $pin_default_info $input_panel_id }
						bidir { $called_function $variable $ball_assignment $pin_default_info $bidir_panel_id }
						output { $called_function $variable $ball_assignment $pin_default_info $output_panel_id }
						default { $called_function $variable $ball_assignment $pin_default_info -1 }
					}
				}
			}
		}
	}

	# This dictionary processes transceiver specific QSF parameters
	set transceiver_dict_variable_json_file [string map {"devices_qsf_variable_mapping.json" "refclk_qsf_variable_mapping.json"} $qsf_variable_json_filename]
	set transceiver_qsf_variable_mapping [read_json $transceiver_dict_variable_json_file]
	set transceiver_dict [json_convert_to_dict $transceiver_qsf_variable_mapping]
	foreach transceiver_variable [dict keys $transceiver_dict] {
		foreach ball_assignment [dict keys $list_pins_config_and_info] {
			if {$is_pre_syn == "True" && [dict exists $list_pins_config_and_info $ball_assignment USER_ASSIGNMENT] && [dict get $list_pins_config_and_info $ball_assignment USER_ASSIGNMENT] == ""} {
				# Skip non user assigned pins
				continue
			}
			set pin_uid [dict get $list_pins_config_and_info $ball_assignment UID]
			if {![regexp -nocase {hssi} $pin_uid]} { 
				# Skip non transceiver pins
				continue
			}
			if {[dict exists $list_pins_config_and_info $ball_assignment $transceiver_variable] } {
				# Skip already processed tranceiver pins
				continue			
			}
			set called_function [dict get $transceiver_dict $transceiver_variable FUNCTION]
			# Default transceiver attribute value if not configured
			set pin_transceiver_tile [get_transceiver_bonded_tile $ball_assignment]
			set pin_default_info [ dict get $transceiver_dict $transceiver_variable $pin_transceiver_tile]
			set pin_direction [dict get $list_pins_config_and_info $ball_assignment DIRECTION]
			# Transceiver attribute retrieval from QSF
			switch $pin_direction {
				input { $called_function $transceiver_variable $ball_assignment $pin_default_info $input_panel_id }
				bidir { $called_function $transceiver_variable $ball_assignment $pin_default_info $bidir_panel_id }
				output { $called_function $transceiver_variable $ball_assignment $pin_default_info $output_panel_id }
				default { $called_function $transceiver_variable $ball_assignment $pin_default_info -1 }
			}

		}
		
	}
	
}

proc get_pin_complement_pairing { qsf_variable_mapping } {
	global list_pins_config_and_info
	set dict_variable [json_convert_to_dict $qsf_variable_mapping]
	
	foreach ball_assignment [dict keys $list_pins_config_and_info] {
		if {[catch {get_pad_data -pad [dict get $list_pins_config_and_info $ball_assignment PAD_ID] INT_LVDS_COMPLEMENT_PAD_ID} fid]} {
			#Skipped means the pin is not supported for differential IO_STANDARD
		} else {
			set diff_pad_id [get_pad_data -pad [dict get $list_pins_config_and_info $ball_assignment PAD_ID] INT_LVDS_COMPLEMENT_PAD_ID]
			set pin_io_standard [dict get $list_pins_config_and_info $ball_assignment IO_STANDARD]
			
			if { [string match "*DIFFERENTIAL*" $pin_io_standard ] } {
				foreach diff_pin [dict keys $list_pins_config_and_info] {
					if { [dict get $list_pins_config_and_info $diff_pin PAD_ID] == $diff_pad_id } {
						if { ! [dict exists $list_pins_config_and_info $ball_assignment DIFF_PIN_PAIR] } { 
							dict lappend list_pins_config_and_info $ball_assignment "DIFF_PIN_PAIR" $diff_pin
							
							if {[catch {set is_positive_pin [get_pad_data -pad [dict get $list_pins_config_and_info $ball_assignment PAD_ID] BOOL_IS_LVDS_POSITIVE]} fid]} {
								dict lappend list_pins_config_and_info $ball_assignment "IS_POSITIVE_PIN" false
							} else {
								dict lappend list_pins_config_and_info $ball_assignment "IS_POSITIVE_PIN" $is_positive_pin
							}
						}
						break
					}
				}
			}
		}
	}
}


proc get_transceiver_bonded_tile { ball_assignment } {
	set pad_list [get_pkg_data LIST_PAD_IDS -pin_name $ball_assignment]
	set first_pad [lindex $pad_list 0]
	set customer_facing_name [get_pad_data -pad $first_pad STRING_AUXILIARY_FUNCTION_NAME]

	if {[regexp {^REFCLK_FGT} $customer_facing_name]} {
		return "REFCLK_FGT"
	} elseif {[regexp {^REFCLK_FHT} $customer_facing_name]} {
		return "REFCLK_FHT"
	} elseif {[regexp {^REFCLK_GXP} $customer_facing_name]} {
		return "REFCLK_GXP"
	} elseif {[regexp {^REFCLK_GXR} $customer_facing_name]} {
		return "REFCLK_GXR"
	} elseif {[regexp {^REFCLK_GXE} $customer_facing_name]} {
		return "REFCLK_GXE"
	} elseif {[regexp {^REFCLK_GTS} $customer_facing_name]} {
		return "REFCLK_GTS"
	}
	# Base case, return NOT_SUPPORTED as the given pin is not one of the supported Transceiver pins
	return "NOT_SUPPORTED"
}


############################################################################
proc main { arg_1 arg_2 arg_3 arg_4} {
#
#   Description : 	Main process
#   Return      : 	None
#
############################################################################
	global list_pins_config_and_info
	global pin_config_file
	
	set project_qpf_path $arg_1
	set project_revision $arg_2
	set is_pre_syn $arg_3
	set qsf_variable_json_filename $arg_4
	set qsf_variable_mapping [ read_json $qsf_variable_json_filename ]
	set currentDir [pwd]
	project_open -force -revision $project_revision $project_qpf_path
	
	set part_num [get_global_assignment -name DEVICE]
	load_device -part $part_num
	
	#pre-populate pin_config_file with all pins if the flow is pre-synthesis
	pre_syn_generate_all_pins $is_pre_syn

	#get user configured pins and initialize the json data
	get_user_node_name_from_config_pin $is_pre_syn

	#get pad id from ddb
	get_pad_id $is_pre_syn

	#get PIN IO type and PIN type
	get_pin_and_IO_type $is_pre_syn

	# Pre-synthesis specific flow
	if {$is_pre_syn == "True"} {
		#pre_synthesis function to populate all default iobank
		get_user_pin_io_bank

		#pre_synthesis function to retrieve the pin's pin_name
		get_pin_name

		#pre_synthesis retrieve every configured pin IO_standard and the associated voltage
		get_pin_io_standard
	}

	#get all the pin configuration and its default value
	get_pin_config $is_pre_syn $qsf_variable_mapping $part_num $qsf_variable_json_filename
	
	#get complement pad pairing
	get_pin_complement_pairing $qsf_variable_mapping

	#convert to JSON format
	set converted_json [dict2json $list_pins_config_and_info]
	
	# write to json file
	set outfile [open $pin_config_file w] 
	puts $outfile $converted_json
	close $outfile
	
	cd $currentDir
	unload_device
	project_close
}

set arg_1 [lindex $argv 0]
set arg_2 [lindex $argv 1]
set arg_3 [lindex $argv 2]
set arg_4 [lindex $argv 3]

main $arg_1 $arg_2 $arg_3 $arg_4 