# FPGA Text OLED Driver

WIP
will be uploaded soon

**Verilog-2001 implementation of a 0.96" I²C OLED controller for FPGA text rendering with scalable font size.**

This project provides a lightweight, synthesizable OLED text display driver written entirely in **Verilog-2001**.  
It allows an FPGA design to render ASCII text directly on a 0.96-inch I²C OLED screen (SSD1306 / SH1106 compatible) —  
**no UART, microcontroller, or software host is required.**

The design includes a dual-clock RAM framebuffer, an I²C communication core, and a hardware text pipeline that accepts  
character codes (`charcode[7:0]`) directly from FPGA logic.  
A **scalable font engine** enables flexible character size configuration, allowing the module  
to adapt to both compact displays and larger visual elements.
