# -------------------------------------------------
# Smart Air Quality Monitoring System (Multi-Pollutant)
# Observable outputs start at 0x10000000
# Alarm triggers if any pollutant/environmental hazard
# -------------------------------------------------
.equ PM25_MOD,   75
.equ PM25_HIGH, 150
.equ PM10_MOD,   50
.equ PM10_HIGH, 100
.equ CO_MOD,     50
.equ CO_HIGH,   200
.equ NO2_MOD,   100
.equ NO2_HIGH,  200
.equ O3_MOD,    100
.equ O3_HIGH,   200
.equ SO2_MOD,    50
.equ SO2_HIGH,  150
.text
.globl _start
_start:
    j main
# -----------------------------
# Utility functions
# -----------------------------
map_sensor:
    li t0, 300
    mul t1, a0, t0
    li t0, 255
    div a0, t1, t0
    ret
map_temperature:
    li t0, 20
    mul t1, a0, t0
    li t0, 255
    div a0, t1, t0
    addi a0, a0, 15
    ret
map_humidity:
    li t0, 70
    mul t1, a0, t0
    li t0, 255
    div a0, t1, t0
    addi a0, a0, 20
    ret
classify:
    blt a0, a1, cls_safe
    blt a0, a2, cls_mod
    li a0, 2
    ret
cls_safe:
    li a0, 0
    ret
cls_mod:
    li a0, 1
    ret
# -----------------------------
# Delay loop (100000 cycles)
# -----------------------------
delay:
    lui  t0, 24          # 24 << 12 = 98304
    addi t0, t0, 1696    # +1696 = 100000
delay_loop:
    addi t0, t0, -1
    bnez t0, delay_loop
    ret
# -----------------------------
# Main program
# -----------------------------
main:
main_loop:
    # -------- INPUT (hardcoded / simulated potentiometers) --------
    li s1, 130       # PM2.5
    li s2, 180       # CO
    li s3, 70        # PM10
    li s4, 120       # NO2
    li s5, 90        # O3
    li s6, 60        # SO2
    # -------- Mapping --------
    mv a0, s1
    jal map_sensor
    mv s1, a0
    mv a0, s2
    jal map_sensor
    mv s2, a0
    mv a0, s3
    jal map_sensor
    mv s3, a0
    mv a0, s4
    jal map_sensor
    mv s4, a0
    mv a0, s5
    jal map_sensor
    mv s5, a0
    mv a0, s6
    jal map_sensor
    mv s6, a0
    mv a0, s1
    jal map_temperature
    mv s7, a0
    mv a0, s2
    jal map_humidity
    mv s8, a0
    # -------- STORE OUTPUTS @ 0x10000000 --------
    lui t0, 0x10000       # t0 = 0x10000000
    sw s1, 0(t0)          # 0x10000000 PM2.5
    sw s2, 4(t0)          # 0x10000004 CO
    sw s3, 8(t0)          # 0x10000008 PM10
    sw s4, 12(t0)         # 0x1000000C NO2
    sw s5, 16(t0)         # 0x10000010 O3
    sw s6, 20(t0)         # 0x10000014 SO2
    sw s7, 24(t0)         # 0x10000018 TEMP
    sw s8, 28(t0)         # 0x1000001C HUMID
    # -------- Classification --------
    mv a0, s1
    li a1, PM25_MOD
    li a2, PM25_HIGH
    jal classify
    mv t1, a0
    mv a0, s3
    li a1, PM10_MOD
    li a2, PM10_HIGH
    jal classify
    mv t2, a0
    mv a0, s2
    li a1, CO_MOD
    li a2, CO_HIGH
    jal classify
    mv t3, a0
    mv a0, s4
    li a1, NO2_MOD
    li a2, NO2_HIGH
    jal classify
    mv t4, a0
    mv a0, s5
    li a1, O3_MOD
    li a2, O3_HIGH
    jal classify
    mv t5, a0
    mv a0, s6
    li a1, SO2_MOD
    li a2, SO2_HIGH
    jal classify
    mv t6, a0
    mv a0, s7
    li a1, 0
    li a2, 30
    jal classify
    mv s9, a0
    mv a0, s8
    li a1, 0
    li a2, 70
    jal classify
    mv s10, a0
    # -------- Alarm Logic --------
    li s0, 0
    li t0, 2
    beq t1, t0, alarm
    beq t2, t0, alarm
    beq t3, t0, alarm
    beq t4, t0, alarm
    beq t5, t0, alarm
    beq t6, t0, alarm
    beq s9, t0, alarm
    beq s10, t0, alarm
    j no_alarm
alarm:
    li s0, 1
no_alarm:
    lui t0, 0x10000       # reload base address
    sw s0, 32(t0)         # 0x10000020 ALARM FLAG
    # Optional LED mirror (0xFFFF0008)
    lui  t1, 0xFFFF0
    addi t1, t1, 8
    sw   s0, 0(t1)
    jal delay
    j main_loop