# (WIP) FPGA Text OLED Driver

**Verilog-2001 implementation of a 0.96" I²C OLED controller for FPGA text rendering with scalable font size.**

This project provides a lightweight, synthesizable OLED text display driver written entirely in **Verilog-2001**.  

**no UART, MicroBlaze IP, or software host is required.**

This repository contains a complete SSD1306-compatible OLED display driver written in Verilog-2001.
It includes initialization, screen clearing, character rendering, pixel-level draw engines, and an integrated I²C master controller.
The design is modular, lightweight, and suitable for FPGA projects.

---

##  Features

*  Full OLED initialization sequence
*  Built-in 8×16 ASCII **font ROM** (Number Only, add others if needed)
*  
*  Fixed text rendering (8 chars × 3 groups)
*  Dynamic text rendering (4 digits × 3 groups)
*  
*  Dynamic X/Y coordinate
*  Draw engine with priority selection
*  I²C master driver (no external IP required)

---

##  Usage

    top_oled_driver u_oled(
        .clk_50m    (clk_50m),
        .rst_n      (rst_n),

        // Fixed set 0
        .fixed_char (fixed_char),
        .fixed_x    (fixed_x),
        .fixed_y    (fixed_y),

        // Fixed set 1
        .fixed_char1(fixed_char1),
        .fixed_x1   (fixed_x1),
        .fixed_y1   (fixed_y1),

        // Fixed set 2
        .fixed_char2(fixed_char2),
        .fixed_x2   (fixed_x2),
        .fixed_y2   (fixed_y2),

        // Dynamic set 0
        .dy_value   (dy_value),
        .dy_x       (dy_x),
        .dy_y       (dy_y),

        // Dynamic set 1
        .dy_value1  (dy_value1),
        .dy_x1      (dy_x1),
        .dy_y1      (dy_y1),

        // Dynamic set 2
        .dy_value2  (dy_value2),
        .dy_x2      (dy_x2),
        .dy_y2      (dy_y2),

        .busy       (busy),

        .iic_scl    (iic_scl),
        .iic_sda    (iic_sda)
    );

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
```

---

## NUPT SAST.2025






