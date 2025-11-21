//TESTESTESTESTESTESTESTESTESTESTESTESTESTESTESTESTEST//
//    ______ _______ _______  ______ _     _ __   _   //
//   |_____/ |______ |______ |_____/  \___/  | \  |   //
//   |    \_ |______ |       |    \_ _/   \_ |  \_|   //
//                                                    //
//TESTESTESTESTESTESTESTESTESTESTESTESTESTESTESTESTEST//

// plz delete this file when used in actual project
// set top_oled_driver.v as top module instead

module top_test(
    input           clk_50m,
    input           rst_n,

    output          iic_scl,
    inout           iic_sda
);

    // Three sets of static text (each 8 ASCII chars)
    reg [63:0] fixed_char;
    reg [6:0]  fixed_x;
    reg [5:0]  fixed_y;

    reg [63:0] fixed_char1;
    reg [6:0]  fixed_x1;
    reg [5:0]  fixed_y1;

    reg [63:0] fixed_char2;
    reg [6:0]  fixed_x2;
    reg [5:0]  fixed_y2;

    // Three sets of dynamic numbers (each 4 digits)
    reg [15:0] dy_value;
    reg [6:0]  dy_x;
    reg [5:0]  dy_y;

    reg [15:0] dy_value1;
    reg [6:0]  dy_x1;
    reg [5:0]  dy_y1;

    reg [15:0] dy_value2;
    reg [6:0]  dy_x2;
    reg [5:0]  dy_y2;

    wire       busy;
    reg  [2:0] state;
    reg  [31:0] cnt;

    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            // Fixed set 0
            fixed_char  <= {"1","1","1","1","1","1","1","1"};
            fixed_x     <= 7'd0;
            fixed_y     <= 6'd1;

            // Fixed set 1
            fixed_char1 <= {"2","2","2","2","2","2","2","2"};
            fixed_x1    <= 7'd0;
            fixed_y1    <= 6'd3;

            // Fixed set 2
            fixed_char2 <= {"3","3","3","3","3","3","3","3"};
            fixed_x2    <= 7'd0;
            fixed_y2    <= 6'd5;

            // Dynamic set 0 (1~9 loop)
            dy_value  <= 16'd1;
            dy_x      <= 7'd90;
            dy_y      <= 6'd1;

            // Dynamic set 1 (10,20,30,... loop)
            dy_value1 <= 16'd10;
            dy_x1     <= 7'd90;
            dy_y1     <= 6'd3;

            // Dynamic set 2 (100,200,300,... loop)
            dy_value2 <= 16'd100;
            dy_x2     <= 7'd90;
            dy_y2     <= 6'd5;

            state <= 3'd0;
            cnt   <= 32'd0;
        end else begin
            case(state)
                3'd0: begin
                    // Wait for OLED initialization to finish (busy goes low once)
                    if(!busy) begin
                        state <= 3'd1;
                    end
                end

                3'd1: begin
                    // Periodic counter to update dynamic values
                    cnt <= cnt + 1;
                    if(cnt == 32'd10_000_000) begin
                        cnt <= 32'd0;

                        // Dynamic set 0: 1~9 loop
                        if(dy_value >= 16'd9)
                            dy_value <= 16'd1;
                        else
                            dy_value <= dy_value + 16'd1;

                        // Dynamic set 1: 10,20,...,90 loop
                        if(dy_value1 >= 16'd90)
                            dy_value1 <= 16'd10;
                        else
                            dy_value1 <= dy_value1 + 16'd10;

                        // Dynamic set 2: 100,200,...,900 loop
                        if(dy_value2 >= 16'd900)
                            dy_value2 <= 16'd100;
                        else
                            dy_value2 <= dy_value2 + 16'd100;
                    end
                end

                default: state <= 3'd1;
            endcase
        end
    end

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

endmodule
