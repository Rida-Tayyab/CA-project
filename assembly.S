#########################################################
# Smart Air Quality Monitoring - RVfpga Software Simulation
# Compatible with RARS/Venus simulator - ASCII ONLY
#########################################################

.equ DISPLAY_BASE,  0x10000000    # Memory-mapped I/O base for simulation
.equ LED_BASE,      0xFFFF0010    # LED display simulation

.data
.align 4

# Screen layout strings - ASCII ONLY
header:         .string "+============================================================+\n"
title:          .string "|      AIR QUALITY MONITORING SYSTEM - RVfpga SIM          |\n"
separator:      .string "+============================================================+\n"
footer:         .string "+============================================================+\n"
line:           .string "|                                                          |\n"

cycle_label:    .string "| Cycle: "
sensor_header:  .string "| SENSOR READINGS:                                         |\n"
pm_label:       .string "|   PM2.5:     "
co2_label:      .string "|   CO2:       "
temp_label:     .string "|   Temperature: "
status_header:  .string "| STATUS:                                                  |\n"
pm_status:      .string "|   PM2.5 State:    "
co2_status:     .string "|   CO2 State:      "
control_header: .string "| CONTROL OUTPUTS:                                         |\n"
alarm_label:    .string "|   ALARM:          "
fan_label:      .string "|   FAN:            "
purifier_label: .string "|   PURIFIER:       "

safe_text:      .string "SAFE      "
moderate_text:  .string "MODERATE  "
hazardous_text: .string "HAZARDOUS "
on_text:        .string "ON "
off_text:       .string "OFF"
ppm_unit:       .string " ppm"
celsius_unit:   .string " C"
space:          .string " "
newline:        .string "\n"
closing:        .string "|\n"

complete_msg:   .string "\n| Monitoring Complete! 20 cycles finished.                 |\n"

.text
.globl main

#---------------------------------------------------------
# Print string helper
#---------------------------------------------------------
print_string:
    li a7, 4
    ecall
    ret

#---------------------------------------------------------
# Print integer helper
#---------------------------------------------------------
print_int:
    li a7, 1
    ecall
    ret

#---------------------------------------------------------
# Print character helper
#---------------------------------------------------------
print_char:
    li a7, 11
    ecall
    ret

#---------------------------------------------------------
# Print newlines to simulate clear screen
#---------------------------------------------------------
clear_screen:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    li t0, 50           # Print 50 newlines
clear_loop:
    beqz t0, clear_done
    li a0, 10           # newline character
    jal ra, print_char
    addi t0, t0, -1
    j clear_loop
    
clear_done:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

#---------------------------------------------------------
# Update LED display (simulated via MMIO)
#---------------------------------------------------------
update_leds:
    la t0, LED_BASE
    sw a0, 0(t0)
    ret


#---------------------------------------------------------
# LCG PRNG
#---------------------------------------------------------
lcg:
    li t0, 1103515245
    mul s0, s0, t0
    li t1, 12345
    add s0, s0, t1
    srli a0, s0, 16
    li t2, 0x7fff
    and a0, a0, t2
    ret

#---------------------------------------------------------
# Classify PM2.5
#---------------------------------------------------------
classify_pm25:
    li t0, 150
    bge a0, t0, pm_haz
    li t0, 75
    bge a0, t0, pm_mod
pm_safe:
    li a0, 0
    ret
pm_mod:
    li a0, 1
    ret
pm_haz:
    li a0, 2
    ret

#---------------------------------------------------------
# Classify CO2
#---------------------------------------------------------
classify_co2:
    li t0, 2000
    bge a0, t0, co2_haz
    li t0, 1000
    bge a0, t0, co2_mod
co2_safe:
    li a0, 0
    ret
co2_mod:
    li a0, 1
    ret
co2_haz:
    li a0, 2
    ret

#---------------------------------------------------------
# Delay function for simulation visibility
#---------------------------------------------------------
delay:
    li t0, 3000000      # Adjust for simulation speed
delay_loop:
    addi t0, t0, -1
    bnez t0, delay_loop
    ret

#---------------------------------------------------------
# Draw display frame
#---------------------------------------------------------
draw_frame:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Clear screen
    jal ra, clear_screen
    
    # Draw header
    la a0, header
    jal ra, print_string
    
    la a0, title
    jal ra, print_string
    
    la a0, separator
    jal ra, print_string
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

#---------------------------------------------------------
# Main Program
#---------------------------------------------------------
main:
    # Initialize PRNG seed
    li s0, 123456789
    
    # Loop counter (20 cycles)
    li s11, 20
    li s10, 1           # Current cycle number (1-indexed for display)

main_loop:
    # Draw frame
    jal ra, draw_frame
    
    # Display cycle number
    la a0, cycle_label
    jal ra, print_string
    
    mv a0, s10
    jal ra, print_int
    la a0, space
    jal ra, print_string
    
    # Fill rest of line
    li t0, 48
cycle_pad:
    beqz t0, cycle_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j cycle_pad
cycle_pad_done:
    la a0, closing
    jal ra, print_string
    
    #----- Generate Sensor Values -----
    
    # Generate PM2.5: 0..200
    jal ra, lcg
    mv t0, a0
    li t1, 201
    remu s2, t0, t1         # s2 = PM2.5 value
    
    # Generate CO2: 400..2900
    jal ra, lcg
    mv t0, a0
    li t1, 2501
    remu s3, t0, t1
    addi s3, s3, 400        # s3 = CO2 value
    
    # Generate Temp: 18..32
    jal ra, lcg
    mv t0, a0
    li t1, 15
    remu s4, t0, t1
    addi s4, s4, 18         # s4 = Temperature value
    
    #----- Display Sensor Readings -----
    
    la a0, sensor_header
    jal ra, print_string
    
    # Display PM2.5
    la a0, pm_label
    jal ra, print_string
    
    mv a0, s2
    jal ra, print_int
    
    li t0, 42
pm_pad:
    beqz t0, pm_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j pm_pad
pm_pad_done:
    la a0, closing
    jal ra, print_string
    
    # Display CO2
    la a0, co2_label
    jal ra, print_string
    
    mv a0, s3
    jal ra, print_int
    la a0, ppm_unit
    jal ra, print_string
    
    li t0, 37
co2_pad:
    beqz t0, co2_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j co2_pad
co2_pad_done:
    la a0, closing
    jal ra, print_string
    
    # Display Temperature
    la a0, temp_label
    jal ra, print_string
    
    mv a0, s4
    jal ra, print_int
    la a0, celsius_unit
    jal ra, print_string
    
    li t0, 38
temp_pad:
    beqz t0, temp_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j temp_pad
temp_pad_done:
    la a0, closing
    jal ra, print_string
    
    #----- Classify Sensors -----
    
    # Classify PM2.5
    mv a0, s2
    jal ra, classify_pm25
    mv s5, a0               # s5 = PM state (0=safe, 1=mod, 2=haz)
    
    # Classify CO2
    mv a0, s3
    jal ra, classify_co2
    mv s6, a0               # s6 = CO2 state
    
    #----- Display Status -----
    
    la a0, status_header
    jal ra, print_string
    
    # PM2.5 Status
    la a0, pm_status
    jal ra, print_string
    
    beqz s5, pm_safe_display
    li t0, 1
    beq s5, t0, pm_mod_display
    # Hazardous
    la a0, hazardous_text
    jal ra, print_string
    j pm_status_done
pm_safe_display:
    la a0, safe_text
    jal ra, print_string
    j pm_status_done
pm_mod_display:
    la a0, moderate_text
    jal ra, print_string
pm_status_done:
    li t0, 24
pm_stat_pad:
    beqz t0, pm_stat_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j pm_stat_pad
pm_stat_pad_done:
    la a0, closing
    jal ra, print_string
    
    # CO2 Status
    la a0, co2_status
    jal ra, print_string
    
    beqz s6, co2_safe_display
    li t0, 1
    beq s6, t0, co2_mod_display
    # Hazardous
    la a0, hazardous_text
    jal ra, print_string
    j co2_status_done
co2_safe_display:
    la a0, safe_text
    jal ra, print_string
    j co2_status_done
co2_mod_display:
    la a0, moderate_text
    jal ra, print_string
co2_status_done:
    li t0, 24
co2_stat_pad:
    beqz t0, co2_stat_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j co2_stat_pad
co2_stat_pad_done:
    la a0, closing
    jal ra, print_string
    
    #----- Display Controls -----
    
    la a0, control_header
    jal ra, print_string
    
    # ALARM (ON if any sensor is HAZARDOUS)
    la a0, alarm_label
    jal ra, print_string
    
    li t0, 2
    beq s5, t0, alarm_on_display
    beq s6, t0, alarm_on_display
    # OFF
    la a0, off_text
    jal ra, print_string
    j alarm_done
alarm_on_display:
    la a0, on_text
    jal ra, print_string
alarm_done:
    li t0, 38
alarm_pad:
    beqz t0, alarm_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j alarm_pad
alarm_pad_done:
    la a0, closing
    jal ra, print_string
    
    # FAN (ON if PM is MODERATE or HAZARDOUS)
    la a0, fan_label
    jal ra, print_string
    
    li t0, 1
    blt s5, t0, fan_off_display
    # ON
    la a0, on_text
    jal ra, print_string
    j fan_done
fan_off_display:
    la a0, off_text
    jal ra, print_string
fan_done:
    li t0, 38
fan_pad:
    beqz t0, fan_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j fan_pad
fan_pad_done:
    la a0, closing
    jal ra, print_string
    
    # PURIFIER (ON if CO2 is MODERATE or HAZARDOUS)
    la a0, purifier_label
    jal ra, print_string
    
    li t0, 1
    blt s6, t0, purifier_off_display
    # ON
    la a0, on_text
    jal ra, print_string
    j purifier_done
purifier_off_display:
    la a0, off_text
    jal ra, print_string
purifier_done:
    li t0, 38
pur_pad:
    beqz t0, pur_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j pur_pad
pur_pad_done:
    la a0, closing
    jal ra, print_string
    
    # Draw footer
    la a0, footer
    jal ra, print_string
    
    # Update simulated LEDs (alarm status)
    li t0, 2
    beq s5, t0, set_led_on
    beq s6, t0, set_led_on
    li a0, 0
    j update_led_display
set_led_on:
    li a0, 0xFF
update_led_display:
    jal ra, update_leds
    
    # Delay for visibility
    jal ra, delay
    
    # Increment cycle counter
    addi s10, s10, 1
    addi s11, s11, -1
    bnez s11, main_loop
    
    #----- Completion -----
    
    jal ra, draw_frame
    la a0, complete_msg
    jal ra, print_string
    la a0, footer
    jal ra, print_string
    
    # Exit
    li a7, 10
    ecall