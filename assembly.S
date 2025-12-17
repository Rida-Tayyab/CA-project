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
pm10_label:     .string "|   PM10:      "
co_label:       .string "|   CO:        "
no2_label:      .string "|   NO2:       "
o3_label:       .string "|   O3:        "
so2_label:      .string "|   SO2:       "
temp_label:     .string "|   Temperature: "
humidity_label: .string "|   Humidity:  "
status_header:  .string "| STATUS:                                                  |\n"
pm_status:      .string "|   PM2.5 State:    "
pm10_status:    .string "|   PM10 State:     "
co_status:      .string "|   CO State:       "
no2_status:     .string "|   NO2 State:      "
o3_status:      .string "|   O3 State:       "
so2_status:     .string "|   SO2 State:      "
temp_status:    .string "|   Temp State:     "
humidity_status:.string "|   Humidity State: "
control_header: .string "| CONTROL OUTPUTS:                                         |\n"
alarm_label:    .string "|   ALARM:          "
fan_label:      .string "|   FAN:            "
vent_label:     .string "|   VENTILATION:    "

safe_text:      .string "SAFE      "
moderate_text:  .string "MODERATE  "
hazardous_text: .string "HAZARDOUS "
on_text:        .string "ON "
off_text:       .string "OFF"
ppm_unit:       .string " ppm"
celsius_unit:   .string " C"
percent_unit:   .string " %"
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
    li t0, LED_BASE
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
# Classify CO (Carbon Monoxide)
#---------------------------------------------------------
classify_co:
    li t0, 200          # CO Hazard threshold: 200 ppm
    bge a0, t0, co_haz
    li t0, 50           # CO Moderate threshold: 50 ppm
    bge a0, t0, co_mod
co_safe:
    li a0, 0
    ret
co_mod:
    li a0, 1
    ret
co_haz:
    li a0, 2
    ret

#---------------------------------------------------------
# Classify PM10
#---------------------------------------------------------
classify_pm10:
    li t0, 100          # PM10 Hazard threshold: 100 µg/m³
    bge a0, t0, pm10_haz
    li t0, 50           # PM10 Moderate threshold: 50 µg/m³
    bge a0, t0, pm10_mod
pm10_safe:
    li a0, 0
    ret
pm10_mod:
    li a0, 1
    ret
pm10_haz:
    li a0, 2
    ret

#---------------------------------------------------------
# Classify NO2 (Nitrogen Dioxide)
#---------------------------------------------------------
classify_no2:
    li t0, 200          # NO2 Hazard threshold: 200 µg/m³
    bge a0, t0, no2_haz
    li t0, 100          # NO2 Moderate threshold: 100 µg/m³
    bge a0, t0, no2_mod
no2_safe:
    li a0, 0
    ret
no2_mod:
    li a0, 1
    ret
no2_haz:
    li a0, 2
    ret

#---------------------------------------------------------
# Classify O3 (Ozone)
#---------------------------------------------------------
classify_o3:
    li t0, 200          # O3 Hazard threshold: 200 µg/m³
    bge a0, t0, o3_haz
    li t0, 100          # O3 Moderate threshold: 100 µg/m³
    bge a0, t0, o3_mod
o3_safe:
    li a0, 0
    ret
o3_mod:
    li a0, 1
    ret
o3_haz:
    li a0, 2
    ret

#---------------------------------------------------------
# Classify SO2 (Sulfur Dioxide)
#---------------------------------------------------------
classify_so2:
    li t0, 150          # SO2 Hazard threshold: 150 µg/m³
    bge a0, t0, so2_haz
    li t0, 50           # SO2 Moderate threshold: 50 µg/m³
    bge a0, t0, so2_mod
so2_safe:
    li a0, 0
    ret
so2_mod:
    li a0, 1
    ret
so2_haz:
    li a0, 2
    ret

#---------------------------------------------------------
# Classify Temperature
#---------------------------------------------------------
classify_temp:
    li t0, 30           # High temp threshold: 30 C
    bge a0, t0, temp_high
    li t0, 20           # Low temp threshold: 20 C
    blt a0, t0, temp_low
temp_normal:
    li a0, 0            # Normal (20-30 C)
    ret
temp_low:
    li a0, 1            # Low (< 20 C) - moderate concern
    ret
temp_high:
    li a0, 2            # High (> 30 C) - hazardous
    ret

#---------------------------------------------------------
# Classify Humidity
#---------------------------------------------------------
classify_humidity:
    li t0, 70           # High humidity threshold: 70%
    bge a0, t0, hum_high
    li t0, 30           # Low humidity threshold: 30%
    blt a0, t0, hum_low
hum_normal:
    li a0, 0            # Normal (30-70%)
    ret
hum_low:
    li a0, 1            # Low (< 30%) - moderate concern
    ret
hum_high:
    li a0, 2            # High (> 70%) - hazardous (mold risk)
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
    
    # Generate PM2.5: 0..300
    jal ra, lcg
    mv t0, a0
    li t1, 301
    remu s2, t0, t1         # s2 = PM2.5 value
    
    # Generate CO: 0..300 ppm
    jal ra, lcg
    mv t0, a0
    li t1, 301
    remu s3, t0, t1         # s3 = CO value
    
    # Generate Temp: 15..35 C
    jal ra, lcg
    mv t0, a0
    li t1, 21
    remu s4, t0, t1
    addi s4, s4, 15         # s4 = Temperature value
    
    # Generate Humidity: 20..90%
    jal ra, lcg
    mv t0, a0
    li t1, 71
    remu s7, t0, t1
    addi s7, s7, 20        # s7 = Humidity value
    
    # Generate PM10: 0..200 µg/m³
    jal ra, lcg
    mv t0, a0
    li t1, 201
    remu t2, t0, t1
    addi sp, sp, -4
    sw t2, 0(sp)           # Store PM10 on stack
    
    # Generate NO2: 0..300 µg/m³
    jal ra, lcg
    mv t0, a0
    li t1, 301
    remu t3, t0, t1
    addi sp, sp, -4
    sw t3, 0(sp)           # Store NO2 on stack
    
    # Generate O3: 0..300 µg/m³
    jal ra, lcg
    mv t0, a0
    li t1, 301
    remu t4, t0, t1
    addi sp, sp, -4
    sw t4, 0(sp)           # Store O3 on stack
    
    # Generate SO2: 0..200 µg/m³
    jal ra, lcg
    mv t0, a0
    li t1, 201
    remu t5, t0, t1
    addi sp, sp, -4
    sw t5, 0(sp)           # Store SO2 on stack
    
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
    
    # Display CO
    la a0, co_label
    jal ra, print_string
    
    mv a0, s3
    jal ra, print_int
    la a0, ppm_unit
    jal ra, print_string
    
    li t0, 38
co_pad:
    beqz t0, co_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j co_pad
    co_pad_done:
    la a0, closing
    jal ra, print_string
    
    # Display PM10
    la a0, pm10_label
    jal ra, print_string
    lw t0, -12(sp)         # Load PM10 value from stack (4 values: -12, -8, -4, 0)
    mv a0, t0
    jal ra, print_int
    la a0, ppm_unit
    jal ra, print_string
    li t0, 36
pm10_pad:
    beqz t0, pm10_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j pm10_pad
pm10_pad_done:
    la a0, closing
    jal ra, print_string
    
    # Display NO2
    la a0, no2_label
    jal ra, print_string
    lw t0, -8(sp)           # Load NO2 value from stack
    mv a0, t0
    jal ra, print_int
    la a0, ppm_unit
    jal ra, print_string
    li t0, 36
no2_pad:
    beqz t0, no2_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j no2_pad
no2_pad_done:
    la a0, closing
    jal ra, print_string
    
    # Display O3
    la a0, o3_label
    jal ra, print_string
    lw t0, -4(sp)           # Load O3 value from stack
    mv a0, t0
    jal ra, print_int
    la a0, ppm_unit
    jal ra, print_string
    li t0, 36
o3_pad:
    beqz t0, o3_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j o3_pad
o3_pad_done:
    la a0, closing
    jal ra, print_string
    
    # Display SO2
    la a0, so2_label
    jal ra, print_string
    lw t0, 0(sp)            # Load SO2 value from stack (top)
    mv a0, t0
    jal ra, print_int
    la a0, ppm_unit
    jal ra, print_string
    li t0, 36
so2_pad:
    beqz t0, so2_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j so2_pad
so2_pad_done:
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
    
    # Display Humidity
    la a0, humidity_label
    jal ra, print_string
    
    mv a0, s7
    jal ra, print_int
    la a0, percent_unit
    jal ra, print_string
    
    li t0, 35
hum_pad:
    beqz t0, hum_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j hum_pad
hum_pad_done:
    la a0, closing
    jal ra, print_string
    
    #----- Classify Sensors -----
    
    # Classify PM2.5
    mv a0, s2
    jal ra, classify_pm25
    mv s5, a0               # s5 = PM state (0=safe, 1=mod, 2=haz)
    
    # Classify CO
    mv a0, s3
    jal ra, classify_co
    mv s6, a0               # s6 = CO state
    
    # Classify PM10 (value is at -12(sp) - first of 4 values)
    lw a0, -12(sp)          # Load PM10 value from stack
    jal ra, classify_pm10
    addi sp, sp, -4
    sw a0, 0(sp)            # Store PM10 state on stack
    
    # Classify NO2 (value is at -8(sp), but after PM10 state push it's at -16)
    lw a0, -16(sp)          # Load NO2 value from stack
    jal ra, classify_no2
    addi sp, sp, -4
    sw a0, 0(sp)            # Store NO2 state on stack
    
    # Classify O3 (value is at -4(sp), but after 2 state pushes it's at -20)
    lw a0, -20(sp)          # Load O3 value from stack
    jal ra, classify_o3
    addi sp, sp, -4
    sw a0, 0(sp)            # Store O3 state on stack
    
    # Classify SO2 (value is at 0(sp), but after 3 state pushes it's at -24)
    lw a0, -24(sp)          # Load SO2 value from stack
    jal ra, classify_so2
    addi sp, sp, -4
    sw a0, 0(sp)            # Store SO2 state on stack
    
    # Classify Temperature
    mv a0, s4
    jal ra, classify_temp
    mv s8, a0               # s8 = Temperature state
    
    # Classify Humidity
    mv a0, s7
    jal ra, classify_humidity
    mv s9, a0               # s9 = Humidity state
    
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
    
    # CO Status
    la a0, co_status
    jal ra, print_string
    
    beqz s6, co_safe_display
    li t0, 1
    beq s6, t0, co_mod_display
    # Hazardous
    la a0, hazardous_text
    jal ra, print_string
    j co_status_done
co_safe_display:
    la a0, safe_text
    jal ra, print_string
    j co_status_done
co_mod_display:
    la a0, moderate_text
    jal ra, print_string
    co_status_done:
    li t0, 26
co_stat_pad:
    beqz t0, co_stat_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j co_stat_pad
co_stat_pad_done:
    la a0, closing
    jal ra, print_string
    
    # PM10 Status
    la a0, pm10_status
    jal ra, print_string
    lw t0, -12(sp)          # Load PM10 state from stack
    beqz t0, pm10_safe_display
    li t1, 1
    beq t0, t1, pm10_mod_display
    la a0, hazardous_text
    jal ra, print_string
    j pm10_status_done
pm10_safe_display:
    la a0, safe_text
    jal ra, print_string
    j pm10_status_done
pm10_mod_display:
    la a0, moderate_text
    jal ra, print_string
pm10_status_done:
    li t0, 24
pm10_stat_pad:
    beqz t0, pm10_stat_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j pm10_stat_pad
pm10_stat_pad_done:
    la a0, closing
    jal ra, print_string
    
    # NO2 Status
    la a0, no2_status
    jal ra, print_string
    lw t0, -8(sp)           # Load NO2 state from stack
    beqz t0, no2_safe_display
    li t1, 1
    beq t0, t1, no2_mod_display
    la a0, hazardous_text
    jal ra, print_string
    j no2_status_done
no2_safe_display:
    la a0, safe_text
    jal ra, print_string
    j no2_status_done
no2_mod_display:
    la a0, moderate_text
    jal ra, print_string
no2_status_done:
    li t0, 26
no2_stat_pad:
    beqz t0, no2_stat_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j no2_stat_pad
no2_stat_pad_done:
    la a0, closing
    jal ra, print_string
    
    # O3 Status
    la a0, o3_status
    jal ra, print_string
    lw t0, -4(sp)           # Load O3 state from stack
    beqz t0, o3_safe_display
    li t1, 1
    beq t0, t1, o3_mod_display
    la a0, hazardous_text
    jal ra, print_string
    j o3_status_done
o3_safe_display:
    la a0, safe_text
    jal ra, print_string
    j o3_status_done
o3_mod_display:
    la a0, moderate_text
    jal ra, print_string
o3_status_done:
    li t0, 26
o3_stat_pad:
    beqz t0, o3_stat_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j o3_stat_pad
o3_stat_pad_done:
    la a0, closing
    jal ra, print_string
    
    # SO2 Status
    la a0, so2_status
    jal ra, print_string
    lw t0, 0(sp)            # Load SO2 state from stack (top)
    beqz t0, so2_safe_display
    li t1, 1
    beq t0, t1, so2_mod_display
    la a0, hazardous_text
    jal ra, print_string
    j so2_status_done
so2_safe_display:
    la a0, safe_text
    jal ra, print_string
    j so2_status_done
so2_mod_display:
    la a0, moderate_text
    jal ra, print_string
so2_status_done:
    li t0, 26
so2_stat_pad:
    beqz t0, so2_stat_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j so2_stat_pad
so2_stat_pad_done:
    la a0, closing
    jal ra, print_string
    
    # Temperature Status
    la a0, temp_status
    jal ra, print_string
    
    beqz s8, temp_safe_display
    li t0, 1
    beq s8, t0, temp_mod_display
    # Hazardous (High)
    la a0, hazardous_text
    jal ra, print_string
    j temp_status_done
temp_safe_display:
    la a0, safe_text
    jal ra, print_string
    j temp_status_done
temp_mod_display:
    la a0, moderate_text
    jal ra, print_string
temp_status_done:
    li t0, 24
temp_stat_pad:
    beqz t0, temp_stat_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j temp_stat_pad
temp_stat_pad_done:
    la a0, closing
    jal ra, print_string
    
    # Humidity Status
    la a0, humidity_status
    jal ra, print_string
    
    beqz s9, hum_safe_display
    li t0, 1
    beq s9, t0, hum_mod_display
    # Hazardous
    la a0, hazardous_text
    jal ra, print_string
    j hum_status_done
hum_safe_display:
    la a0, safe_text
    jal ra, print_string
    j hum_status_done
hum_mod_display:
    la a0, moderate_text
    jal ra, print_string
hum_status_done:
    li t0, 20
hum_stat_pad:
    beqz t0, hum_stat_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j hum_stat_pad
hum_stat_pad_done:
    la a0, closing
    jal ra, print_string
    
    #----- Display Controls -----
    
    la a0, control_header
    jal ra, print_string
    
    # ALARM (ON if any sensor is HAZARDOUS)
    la a0, alarm_label
    jal ra, print_string
    
    li t0, 2
    beq s5, t0, alarm_on_display      # PM2.5
    beq s6, t0, alarm_on_display      # CO
    beq s8, t0, alarm_on_display      # Temperature
    beq s9, t0, alarm_on_display      # Humidity
    # Check new pollutants from stack
    lw t1, -12(sp)                    # PM10 state
    beq t1, t0, alarm_on_display
    lw t1, -8(sp)                     # NO2 state
    beq t1, t0, alarm_on_display
    lw t1, -4(sp)                     # O3 state
    beq t1, t0, alarm_on_display
    lw t1, 0(sp)                      # SO2 state
    beq t1, t0, alarm_on_display
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
    
    # VENTILATION (ON if CO is MOD/HAZ or Humidity is HIGH or Temp is HIGH)
    la a0, vent_label
    jal ra, print_string
    
    li t0, 1
    blt s6, t0, check_vent_humidity  # Check if CO is MOD/HAZ
    # CO is MOD/HAZ, turn ON
    la a0, on_text
    jal ra, print_string
    j vent_done
check_vent_humidity:
    li t0, 2
    beq s9, t0, vent_on_display       # Humidity is HIGH (hazardous)
    beq s8, t0, vent_on_display       # Temperature is HIGH (hazardous)
    # OFF
    la a0, off_text
    jal ra, print_string
    j vent_done
vent_on_display:
    la a0, on_text
    jal ra, print_string
vent_done:
    li t0, 30
vent_pad:
    beqz t0, vent_pad_done
    li a0, ' '
    jal ra, print_char
    addi t0, t0, -1
    j vent_pad
vent_pad_done:
    la a0, closing
    jal ra, print_string
    
    # Draw footer
    la a0, footer
    jal ra, print_string
    
    # Update simulated LEDs (alarm status - any sensor hazardous)
    li t0, 2
    beq s5, t0, set_led_on      # PM2.5
    beq s6, t0, set_led_on      # CO
    beq s8, t0, set_led_on      # Temperature
    beq s9, t0, set_led_on      # Humidity
    # Check new pollutants from stack
    lw t1, -12(sp)              # PM10 state
    beq t1, t0, set_led_on
    lw t1, -8(sp)               # NO2 state
    beq t1, t0, set_led_on
    lw t1, -4(sp)               # O3 state
    beq t1, t0, set_led_on
    lw t1, 0(sp)                # SO2 state
    beq t1, t0, set_led_on
    li a0, 0
    j update_led_display
set_led_on:
    li a0, 0xFF
update_led_display:
    jal ra, update_leds
    
    # Clean up stack (4 values + 4 states = 8 words = 32 bytes)
    addi sp, sp, 32
    
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