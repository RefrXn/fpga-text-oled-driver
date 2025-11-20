//____________________________________________________//
//    ______ _______ _______  ______ _     _ __   _   //
//   |_____/ |______ |______ |_____/  \___/  | \  |   //
//   |    \_ |______ |       |    \_ _/   \_ |  \_|   //
//____________________________________________________//

module top_oled_driver(

    // system signals
    input           clk_50m,
    input           rst_n,

    // fixed characters
    input  [63:0]   fixed_char,
    input  [6:0]    fixed_x,
    input  [5:0]    fixed_y,

    // dynamic characters
    input  [15:0]   dy_value,
    input  [6:0]    dy_x,
    input  [5:0]    dy_y,

    // status output
    output          busy,

    // IIC interface
    output          iic_scl,
    inout           iic_sda

);

    // System FSM signals
    wire init_finish;
    wire clear_finish;
    wire init_req;
    wire clear_req;
    wire is_run;

    // FSM: handles initialization and screen clearing
    oled_fsm u_oled_fsm(
        .clk_50m      (clk_50m),
        .rst_n        (rst_n),
        .init_finish  (init_finish),
        .clear_finish (clear_finish),
        .init_req     (init_req),
        .clear_req    (clear_req),
        .is_run       (is_run)
    );

    // Handshake signals for character drawing engine
    wire       draw_busy;
    wire       draw_done;

    // Fixed / Dynamic character module interface signals
    // fixed text draw request output
    wire        fix_active;
    wire        fix_draw_start;
    wire [7:0]  fix_draw_ascii;
    wire [6:0]  fix_draw_x;
    wire [3:0]  fix_draw_y;

    // dynamic number draw request output
    wire        dy_active;
    wire        dy_draw_start;
    wire [7:0]  dy_draw_ascii;
    wire [6:0]  dy_draw_x;
    wire [3:0]  dy_draw_y;

    // Fixed character renderer module
    // Draws 8 ASCII characters when fixed_char changes
    oled_fx_char u_oled_fx_char(
        .clk_50m        (clk_50m),
        .rst_n          (rst_n),
        .fixed_char     (fixed_char),
        .fixed_x        (fixed_x),
        .fixed_y        (fixed_y),
        .is_run         (is_run),
        .dy_active      (dy_active),
        .draw_busy      (draw_busy),
        .draw_done      (draw_done),
        .fix_active     (fix_active),
        .fix_draw_start (fix_draw_start),
        .fix_draw_ascii (fix_draw_ascii),
        .fix_draw_x     (fix_draw_x),
        .fix_draw_y     (fix_draw_y)
    );

    // Dynamic number renderer module
    // Draws a 4-digit number whenever dy_value changes
    oled_dy_char u_oled_dy_char(
        .clk_50m        (clk_50m),
        .rst_n          (rst_n),
        .dy_value       (dy_value),
        .dy_x           (dy_x),
        .dy_y           (dy_y),
        .is_run         (is_run),
        .fix_active     (fix_active),
        .draw_busy      (draw_busy),
        .draw_done      (draw_done),
        .dy_active      (dy_active),
        .dy_draw_start  (dy_draw_start),
        .dy_draw_ascii  (dy_draw_ascii),
        .dy_draw_x      (dy_draw_x),
        .dy_draw_y      (dy_draw_y)
    );

    // Draw command multiplexer
    // Chooses between fixed or dynamic character requests
    wire        start_mux;
    wire [7:0]  ascii_mux;
    wire [7:0]  x_mux;
    wire [3:0]  y_mux;

    oled_mux u_mux(
        .clk_50m         (clk_50m),
        .rst_n           (rst_n),

        .fix_draw_start  (fix_draw_start),
        .fix_draw_ascii  (fix_draw_ascii),
        .fix_draw_x      (fix_draw_x),
        .fix_draw_y      (fix_draw_y),

        .dy_draw_start   (dy_draw_start),
        .dy_draw_ascii   (dy_draw_ascii),
        .dy_draw_x       (dy_draw_x),
        .dy_draw_y       (dy_draw_y),

        .start_mux       (start_mux),
        .ascii_mux       (ascii_mux),
        .x_mux           (x_mux),
        .y_mux           (y_mux)
    );


    // character generator
    wire [23:0] IICWriteData_char;
    wire        IICWriteReq_char;
    wire        IICWriteDone;

    oled_char_gen u_char_gen(
        .clk_50m      (clk_50m),
        .rst_n        (rst_n),
        .start        (start_mux),
        .ascii        (ascii_mux),
        .x            (x_mux[6:0]),
        .y            (y_mux),
        .busy         (draw_busy),
        .done         (draw_done),
        .IICWriteReq  (IICWriteReq_char),
        .IICWriteData (IICWriteData_char),
        .IICWriteDone (IICWriteDone)
    );


    // init / clear / sel /iic driver
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
        .iic_scl       (iic_scl),
        .iic_sda       (iic_sda),
        .iic_slave     ({IICWriteData[15:8], IICWriteData[23:16]}),
        .iic_wr_req  (IICWriteReq),
        .iic_wr_done (IICWriteDone),
        .iic_wr_data (IICWriteData[7:0]),
        .iic_rd_req   (1'b0)
    );

    // busy signal
    assign busy = !is_run || draw_busy || fix_active || dy_active;

endmodule