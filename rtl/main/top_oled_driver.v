//____________________________________________________//
//    ______ _______ _______  ______ _     _ __   _   //
//   |_____/ |______ |______ |_____/  \___/  | \  |   //
//   |    \_ |______ |       |    \_ _/   \_ |  \_|   //
//____________________________________________________//

module top_oled_driver(

    // System signals
    input           clk_50m,
    input           rst_n,

    // 3 groups of fixed text (each 8 ASCII chars) 
    // Group 0 
    input  [63:0]   fixed_char,
    input  [6:0]    fixed_x,
    input  [5:0]    fixed_y,

    // Group 1
    input  [63:0]   fixed_char1,
    input  [6:0]    fixed_x1,
    input  [5:0]    fixed_y1,

    // Group 2
    input  [63:0]   fixed_char2,
    input  [6:0]    fixed_x2,
    input  [5:0]    fixed_y2,

    // 3 groups of dynamic numbers (each 4 decimal digits)
    // Group 0
    input  [15:0]   dy_value,
    input  [6:0]    dy_x,
    input  [5:0]    dy_y,

    // Group 1
    input  [15:0]   dy_value1,
    input  [6:0]    dy_x1,
    input  [5:0]    dy_y1,

    // Group 2
    input  [15:0]   dy_value2,
    input  [6:0]    dy_x2,
    input  [5:0]    dy_y2,

    // Status output
    output          busy,

    // IIC interface
    output          iic_scl,
    inout           iic_sda

);

    // OLED System FSM
    wire init_finish;
    wire clear_finish;
    wire init_req;
    wire clear_req;
    wire is_run;

    oled_fsm u_oled_fsm(
        .clk_50m      (clk_50m),
        .rst_n        (rst_n),
        .init_finish  (init_finish),
        .clear_finish (clear_finish),
        .init_req     (init_req),
        .clear_req    (clear_req),
        .is_run       (is_run)
    );

    // Draw scheduler -> char generator
    wire        draw_start;
    wire [7:0]  draw_ascii;
    wire [6:0]  draw_x;
    wire [3:0]  draw_y;

    wire        draw_busy;
    wire        draw_done;
    wire        engine_busy;

    // Unified scheduler for 3 static groups + 3 dynamic groups
    oled_draw_engine_3fx3dy u_draw_engine(
        .clk_50m   (clk_50m),
        .rst_n     (rst_n),
        .is_run    (is_run),

        // Fixed groups
        .fixed_char0 (fixed_char),
        .fixed_x0    (fixed_x),
        .fixed_y0    (fixed_y[3:0]),   // Only page (lower 4 bits)

        .fixed_char1 (fixed_char1),
        .fixed_x1    (fixed_x1),
        .fixed_y1    (fixed_y1[3:0]),

        .fixed_char2 (fixed_char2),
        .fixed_x2    (fixed_x2),
        .fixed_y2    (fixed_y2[3:0]),

        // Dynamic groups
        .dy_value0   (dy_value),
        .dy_x0       (dy_x),
        .dy_y0       (dy_y[3:0]),

        .dy_value1   (dy_value1),
        .dy_x1       (dy_x1),
        .dy_y1       (dy_y1[3:0]),

        .dy_value2   (dy_value2),
        .dy_x2       (dy_x2),
        .dy_y2       (dy_y2[3:0]),

        // Output to char generator
        .start       (draw_start),
        .ascii       (draw_ascii),
        .x           (draw_x),
        .y           (draw_y),

        // Handshake from char generator
        .char_busy   (draw_busy),
        .char_done   (draw_done),

        // Scheduler busy flag
        .engine_busy (engine_busy)
    );

    // Character generator (ASCII → IIC command sequence)
    wire [23:0] IICWriteData_char;
    wire        IICWriteReq_char;
    wire        IICWriteDone;

    oled_char_gen u_char_gen(
        .clk_50m     (clk_50m),
        .rst_n       (rst_n),
        .start       (draw_start),
        .ascii       (draw_ascii),
        .x           (draw_x),
        .y           (draw_y),
        .busy        (draw_busy),
        .done        (draw_done),
        .iic_wr_req  (IICWriteReq_char),
        .iic_wr_data (IICWriteData_char),
        .iic_wr_done (IICWriteDone)
    );

    // init / clear / select / IIC driver
    wire [23:0] Init_data;
    wire [23:0] clear_data;
    wire        IICWriteReq;
    wire [23:0] IICWriteData;

    oled_init u_init(
        .clk_50m      (clk_50m),
        .rst_n        (rst_n),
        .i_req        (init_req),
        .i_write_done (IICWriteDone),
        .o_init_done  (init_finish),
        .o_data       (Init_data)
    );

    oled_clear u_clear(
        .clk_50m        (clk_50m),
        .rst_n          (rst_n),
        .write_done     (IICWriteDone),
        .refresh_finish (clear_finish),
        .refresh_data   (clear_data)
    );

    oled_sel u_sel(
        .clk_50m      (clk_50m),
        .rst_n        (rst_n),
        .i_init_req   (init_req),
        .i_init_data  (Init_data),
        .i_clear_req  (clear_req),
        .i_clear_data (clear_data),
        .i_char_req   (IICWriteReq_char),
        .i_char_data  (IICWriteData_char),
        .o_iic_req    (IICWriteReq),
        .o_iic_data   (IICWriteData)
    );

    oled_iic_driver u_iic(
        .clk_50m      (clk_50m),
        .rst_n        (rst_n),
        .iic_scl      (iic_scl),
        .iic_sda      (iic_sda),
        .iic_slave    ({IICWriteData[15:8], IICWriteData[23:16]}),
        .iic_wr_req   (IICWriteReq),
        .iic_wr_done  (IICWriteDone),
        .iic_wr_data  (IICWriteData[7:0]),
        .iic_rd_req   (1'b0)
    );

    // OLED is busy when:
    //   - system FSM is not in run state (during init/clear), OR
    //   - draw engine is processing characters
    assign busy = !is_run || engine_busy;

endmodule
