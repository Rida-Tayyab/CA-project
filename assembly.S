# -------------------------------------------------
# Smart Air Quality Monitoring System
# Bare-metal RV32IM
# Observable outputs start at 0x10000000
# Alarm always triggers (class 2)
# -------------------------------------------------

.equ PM25_HIGH, 150
.equ PM25_MOD,   75
.equ CO_HIGH,   200
.equ CO_MOD,     50

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

    # -------- INPUT (hardcoded to trigger alarm) --------
    li s1, 130       # PM2.5 raw
    li s2, 180       # CO raw

    # -------- Mapping --------
    mv a0, s1
    jal map_sensor
    mv s1, a0

    mv a0, s2
    jal map_sensor
    mv s2, a0

    mv a0, s1
    jal map_temperature
    mv s3, a0

    mv a0, s2
    jal map_humidity
    mv s4, a0

    # -------- STORE OUTPUTS @ 0x10000000 --------
    lui t0, 0x10000       # t0 = 0x10000000
    sw s1, 0(t0)          # 0x10000000 PM2.5
    sw s2, 4(t0)          # 0x10000004 CO
    sw s3, 8(t0)          # 0x10000008 TEMP
    sw s4, 12(t0)         # 0x1000000C HUMID

    # -------- Classification --------
    mv a0, s1
    li a1, PM25_MOD
    li a2, PM25_HIGH
    jal classify
    mv s5, a0

    mv a0, s2
    li a1, CO_MOD
    li a2, CO_HIGH
    jal classify
    mv s6, a0

    # -------- Alarm Logic --------
    li s0, 0
    li t3, 2
    beq s5, t3, alarm
    beq s6, t3, alarm
    j no_alarm

alarm:
    li s0, 1

no_alarm:
    sw s0, 16(t0)         # 0x10000010 ALARM FLAG

    # Optional LED mirror (0xFFFF0008)
    lui  t4, 0xFFFF0
    addi t4, t4, 8
    sw   s0, 0(t4)

    jal delay
    j main_loop