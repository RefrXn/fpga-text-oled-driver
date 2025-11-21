//____________________________________________________//
//    ______ _______ _______  ______ _     _ __   _   //
//   |_____/ |______ |______ |_____/  \___/  | \  |   //
//   |    \_ |______ |       |    \_ _/   \_ |  \_|   //
//____________________________________________________//

module oled_fx_char(

    // system signals
    input           clk_50m,
    input           rst_n,

    // fixed characters
    input  [63:0]   fixed_char,
    input  [6:0]    fixed_x,
    input  [5:0]    fixed_y,

    // control
    input           is_run,
    input           dy_active,   
    input           draw_busy,   
    input           draw_done,   

    // output to top for muxing
    output reg      fix_active,
    output reg      fix_draw_start,
    output reg [7:0] fix_draw_ascii,
    output reg [6:0] fix_draw_x,
    output reg [3:0] fix_draw_y

);

    // Fixed trigger logic
    reg [63:0] prev_fixed_char;
    reg        fixed_trigger;

    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            prev_fixed_char <= 64'd0;
            fixed_trigger   <= 1'b0;
        end else begin
            if(fixed_char != prev_fixed_char) begin
                prev_fixed_char <= fixed_char;
                fixed_trigger   <= 1'b1;
            end else if(fixed_trigger && (is_run) && !draw_busy) begin
                fixed_trigger <= 1'b0;
            end
        end
    end

    wire [7:0] C0 = fixed_char[63:56];
    wire [7:0] C1 = fixed_char[55:48];
    wire [7:0] C2 = fixed_char[47:40];
    wire [7:0] C3 = fixed_char[39:32];
    wire [7:0] C4 = fixed_char[31:24];
    wire [7:0] C5 = fixed_char[23:16];
    wire [7:0] C6 = fixed_char[15:8];
    wire [7:0] C7 = fixed_char[7:0];

    // Fixed divider
    reg [2:0]  fix_idx;
    reg        fix_arm;

    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            fix_active     <= 1'b0;
            fix_idx        <= 0;
            fix_arm        <= 1'b0;
            fix_draw_start <= 1'b0;
            fix_draw_ascii <= 8'd0;
            fix_draw_x     <= 0;
            fix_draw_y     <= 0;
        end else begin
            fix_draw_start <= 1'b0;

            if(fixed_trigger && !fix_active && !dy_active && is_run) begin
                fix_active <= 1'b1;
                fix_idx    <= 0;
                fix_arm    <= 1'b1;
            end

            if(fix_active && fix_arm && !draw_busy) begin
                case(fix_idx)
                    0: if(C0!=0 && C0!=" ") begin
                        fix_draw_start <= 1'b1;
                        fix_draw_ascii <= C0;
                        fix_draw_x     <= fixed_x + 0*8;
                        fix_draw_y     <= fixed_y[3:0];
                    end
                    1: if(C1!=0 && C1!=" ") begin
                        fix_draw_start <= 1'b1;
                        fix_draw_ascii <= C1;
                        fix_draw_x     <= fixed_x + 1*8;
                        fix_draw_y     <= fixed_y[3:0];
                    end
                    2: if(C2!=0 && C2!=" ") begin
                        fix_draw_start <= 1'b1;
                        fix_draw_ascii <= C2;
                        fix_draw_x     <= fixed_x + 2*8;
                        fix_draw_y     <= fixed_y[3:0];
                    end
                    3: if(C3!=0 && C3!=" ") begin
                        fix_draw_start <= 1'b1;
                        fix_draw_ascii <= C3;
                        fix_draw_x     <= fixed_x + 3*8;
                        fix_draw_y     <= fixed_y[3:0];
                    end
                    4: if(C4!=0 && C4!=" ") begin
                        fix_draw_start <= 1'b1;
                        fix_draw_ascii <= C4;
                        fix_draw_x     <= fixed_x + 4*8;
                        fix_draw_y     <= fixed_y[3:0];
                    end
                    5: if(C5!=0 && C5!=" ") begin
                        fix_draw_start <= 1'b1;
                        fix_draw_ascii <= C5;
                        fix_draw_x     <= fixed_x + 5*8;
                        fix_draw_y     <= fixed_y[3:0];
                    end
                    6: if(C6!=0 && C6!=" ") begin
                        fix_draw_start <= 1'b1;
                        fix_draw_ascii <= C6;
                        fix_draw_x     <= fixed_x + 6*8;
                        fix_draw_y     <= fixed_y[3:0];
                    end
                    7: if(C7!=0 && C7!=" ") begin
                        fix_draw_start <= 1'b1;
                        fix_draw_ascii <= C7;
                        fix_draw_x     <= fixed_x + 7*8;
                        fix_draw_y     <= fixed_y[3:0];
                    end
                endcase
                fix_arm <= 1'b0;
            end

            // done and next
            if(fix_active && draw_done) begin
                if(fix_idx != 7) begin
                    fix_idx <= fix_idx + 1;
                    fix_arm <= 1'b1;
                end else begin
                    fix_active <= 1'b0;
                end
            end
        end
    end

endmodule
