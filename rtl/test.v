//____________________________________________________//
//    ______ _______ _______  ______ _     _ __   _   //
//   |_____/ |______ |______ |_____/  \___/  | \  |   //
//   |    \_ |______ |       |    \_ _/   \_ |  \_|   //
//____________________________________________________//

// only for onboard testing
// plz set top module to top_oled_driver when actually using

module top_test(
    input           clk_50m,
    input           rst_n,

    output          iic_scl,
    inout           iic_sda
);

    // fixed characters
    reg [63:0] fixed_char;

    reg  [6:0]   fixed_x;
    reg  [5:0]   fixed_y;

    // dynamic characters
    reg  [15:0]  dy_value;
    reg  [6:0]   dy_x;
    reg  [5:0]   dy_y;

    wire busy;
    reg [2:0] state;
    reg [31:0] cnt;

    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            fixed_char <= {"3","1","4","1","5","9","2","6"};
            fixed_x    <= 20;
            fixed_y    <= 1;

            dy_value <= 1;
            dy_x <= 60;
            dy_y <= 3;

            state <= 0;
            cnt <= 0;
        end else begin
            case(state)
            0: begin
                if(!busy) begin
                    fixed_char <= {"3","1","4","1","5","9","2","6"};
                    state <= 1;
                end
            end

            // refresh 1~9
            1: begin
                cnt <= cnt + 1;
                if(cnt == 32'd10_000_000) begin
                    cnt <= 0;

                    if(dy_value >= 9)
                        dy_value <= 1;
                    else
                        dy_value <= dy_value + 1;
                end
            end

            default: state <= 1;
            endcase
        end
    end

    top_oled_driver u_oled(
        .clk_50m    (clk_50m),
        .rst_n      (rst_n),

        .fixed_char (fixed_char),
        .fixed_x    (fixed_x),
        .fixed_y    (fixed_y),

        .dy_value   (dy_value),
        .dy_x       (dy_x),
        .dy_y       (dy_y),

        .busy       (busy),

        .iic_scl   (iic_scl),
        .iic_sda   (iic_sda)
    );

endmodule


