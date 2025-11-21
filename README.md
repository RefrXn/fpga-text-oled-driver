# (WIP) FPGA Text OLED Driver

**Verilog-2001 implementation of a 0.96" I²C OLED controller for FPGA text rendering with scalable font size.**

This project provides a lightweight, synthesizable OLED text display driver written entirely in **Verilog-2001**.  
It allows an FPGA design to render ASCII text directly on a 0.96-inch I²C OLED screen (SSD1306 / SH1106 compatible) —  
**no UART, microcontroller, or software host is required.**

This repository contains a complete SSD1306-compatible OLED display driver written in Verilog HDL.
It includes initialization, screen clearing, character rendering, pixel-level draw engines, and an integrated I²C master controller.
The design is modular, lightweight, and suitable for FPGA projects.

---

##  Features

*  Full OLED initialization sequence
*  Built-in 8×16 ASCII **font ROM** (Number Only, add others if needed)
*  Fixed text rendering (8 chars × 3 groups)
*  Dynamic text rendering (4 digits × 3 groups)
*  Dynamic X/Y coordinate
*  Draw engine with priority selection
*  I²C master driver (no external IP required)

---

##  Module Hierarchy

```
u_oled : top_oled_driver
│
├── u_oled_fsm : oled_fsm
│
├── u_draw_engine : oled_draw_engine_3fx3dy
│
├── u_char_gen : oled_char_gen
│   └── u_font : font_data
│
├── u_init  : oled_init
├── u_clear : oled_clear
├── u_sel   : oled_sel
└── u_iic   : oled_iic_driver




