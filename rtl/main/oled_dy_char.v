//____________________________________________________//
//    ______ _______ _______  ______ _     _ __   _   //
//   |_____/ |______ |______ |_____/  \___/  | \  |   //
//   |    \_ |______ |       |    \_ _/   \_ |  \_|   //
//____________________________________________________//

module oled_dy_char(

    // system
    input           clk_50m,
    input           rst_n,

    // dynamic characters
    input  [15:0]   dy_value,
    input  [6:0]    dy_x,
    input  [5:0]    dy_y,

    // control
    input           is_run,
    input           fix_active,
    input           draw_busy,    // from char_gen
    input           draw_done,    // from char_gen

    // output to top for muxing
    output reg      dy_active,
    output reg      dy_draw_start,
    output reg [7:0] dy_draw_ascii,
    output reg [6:0] dy_draw_x,
    output reg [3:0] dy_draw_y

);

    // Dynamic trigger logic
    reg [15:0] dy_last_seen;
    reg [15:0] dy_latched;
    reg [1:0]  dy_idx;
    reg        dy_arm;

    wire dy_req = (dy_value != dy_last_seen);

    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            dy_last_seen  <= 0;
            dy_latched    <= 0;
            dy_active     <= 0;
            dy_idx        <= 0;
            dy_arm        <= 0;
            dy_draw_start <= 0;
            dy_draw_ascii <= 0;
            dy_draw_x     <= 0;
            dy_draw_y     <= 0;
        end else begin
            dy_draw_start <= 1'b0;

            // start condition
            if(is_run && dy_req && !fix_active && !dy_active) begin
                dy_latched   <= dy_value;
                dy_last_seen <= dy_value;
                dy_active    <= 1'b1;
                dy_idx       <= 0;
                dy_arm       <= 1'b1;
            end

            // 
            if(dy_active && dy_arm && !draw_busy) begin
                case(dy_idx)
                    0: begin
                        dy_draw_ascii <= ((dy_latched/1000)%10) + "0";
                        dy_draw_x     <= dy_x + 0;
                        dy_draw_y     <= dy_y[3:0];
                        dy_draw_start <= 1'b1;
                    end
                    1: begin
                        dy_draw_ascii <= ((dy_latched/100)%10) + "0";
                        dy_draw_x     <= dy_x + 8;
                        dy_draw_y     <= dy_y[3:0];
                        dy_draw_start <= 1'b1;
                    end
                    2: begin
                        dy_draw_ascii <= ((dy_latched/10)%10) + "0";
                        dy_draw_x     <= dy_x + 16;
                        dy_draw_y     <= dy_y[3:0];
                        dy_draw_start <= 1'b1;
                    end
                    3: begin
                        dy_draw_ascii <= (dy_latched%10) + "0";
                        dy_draw_x     <= dy_x + 24;
                        dy_draw_y     <= dy_y[3:0];
                        dy_draw_start <= 1'b1;
                    end
                endcase

                dy_arm <= 1'b0;
            end

            // 一位完成 -> 下一位
            if(dy_active && draw_done) begin
                if(dy_idx != 3) begin
                    dy_idx <= dy_idx + 1;
                    dy_arm <= 1'b1;
                end else begin
                    dy_active <= 1'b0;
                end
            end
        end
    end

endmodule
