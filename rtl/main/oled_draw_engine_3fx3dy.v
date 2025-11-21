//____________________________________________________//
//    ______ _______ _______  ______ _     _ __   _   //
//   |_____/ |______ |______ |_____/  \___/  | \  |   //
//   |    \_ |______ |       |    \_ _/   \_ |  \_|   //
//____________________________________________________//

module oled_draw_engine_3fx3dy(
    input         clk_50m,
    input         rst_n,
    input         is_run,

    // 3 groups of Fixed characters (8 ASCII each)
    input  [63:0] fixed_char0,
    input  [6:0]  fixed_x0,
    input  [5:0]  fixed_y0,

    input  [63:0] fixed_char1,
    input  [6:0]  fixed_x1,
    input  [5:0]  fixed_y1,

    input  [63:0] fixed_char2,
    input  [6:0]  fixed_x2,
    input  [5:0]  fixed_y2,

    // 3 groups of dynamic numbers (4 decimal digits each)
    input  [15:0] dy_value0,
    input  [6:0]  dy_x0,
    input  [5:0]  dy_y0,

    input  [15:0] dy_value1,
    input  [6:0]  dy_x1,
    input  [5:0]  dy_y1,

    input  [15:0] dy_value2,
    input  [6:0]  dy_x2,
    input  [5:0]  dy_y2,

    // Output to oled_char_gen
    output reg        start,
    output reg [7:0]  ascii,
    output reg [6:0]  x,
    output reg [3:0]  y,

    // Feedback from oled_char_gen
    input             char_busy,
    input             char_done,

    // Indicates drawing engine is active
    output reg        engine_busy
);

    // FSM states
    localparam ST_IDLE      = 3'd0;
    localparam ST_PREP_CHAR = 3'd1;
    localparam ST_SEND_CHAR = 3'd2;
    localparam ST_WAIT_DONE = 3'd3;

    reg [2:0] state;

    // Current group index:
    //   0/1/2 = Fixed groups 0/1/2
    //   3/4/5 = dynamic groups 0/1/2
    reg [2:0] cur_group;
    reg       cur_is_dynamic;      // 0: fixed, 1: dynamic
    reg [3:0] cur_char_total;      // 8 for fixed, 4 for dynamic
    reg [3:0] char_index;          // current character index

    // Snapshot of the current group's data
    reg [63:0] cur_word;           // 8 ASCII characters for fixed text
    reg [6:0]  base_x;
    reg [3:0]  base_y;

    // Split dynamic number into 4 decimal digits
    reg [3:0] digit3;  // thousands
    reg [3:0] digit2;  // hundreds
    reg [3:0] digit1;  // tens
    reg [3:0] digit0;  // ones

    // Pending flags: need redraw
    reg fix_pending0, fix_pending1, fix_pending2;
    reg dy_pending0,  dy_pending1,  dy_pending2;

    // Previous value storage for change detection
    reg [63:0] prev_fixed_char0, prev_fixed_char1, prev_fixed_char2;
    reg [6:0]  prev_fixed_x0,    prev_fixed_x1,    prev_fixed_x2;
    reg [5:0]  prev_fixed_y0,    prev_fixed_y1,    prev_fixed_y2;

    reg [15:0] prev_dy_value0, prev_dy_value1, prev_dy_value2;
    reg [6:0]  prev_dy_x0,     prev_dy_x1,     prev_dy_x2;
    reg [5:0]  prev_dy_y0,     prev_dy_y1,     prev_dy_y2;

    // Main FSM + pending management + change detection
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            state         <= ST_IDLE;
            cur_group     <= 3'd0;
            cur_is_dynamic<= 1'b0;
            cur_char_total<= 4'd0;
            char_index    <= 4'd0;
            cur_word      <= 64'd0;
            base_x        <= 7'd0;
            base_y        <= 4'd0;
            digit3        <= 4'd0;
            digit2        <= 4'd0;
            digit1        <= 4'd0;
            digit0        <= 4'd0;
            ascii         <= 8'd0;
            x             <= 7'd0;
            y             <= 4'd0;
            start         <= 1'b0;
            engine_busy   <= 1'b0;

            // At reset, mark all groups as pending (initial draw)
            fix_pending0 <= 1'b1;
            fix_pending1 <= 1'b1;
            fix_pending2 <= 1'b1;
            dy_pending0  <= 1'b1;
            dy_pending1  <= 1'b1;
            dy_pending2  <= 1'b1;

            // Clear previous-value registers
            prev_fixed_char0 <= 64'd0;
            prev_fixed_char1 <= 64'd0;
            prev_fixed_char2 <= 64'd0;
            prev_fixed_x0    <= 7'd0;
            prev_fixed_x1    <= 7'd0;
            prev_fixed_x2    <= 7'd0;
            prev_fixed_y0    <= 6'd0;
            prev_fixed_y1    <= 6'd0;
            prev_fixed_y2    <= 6'd0;

            prev_dy_value0 <= 16'd0;
            prev_dy_value1 <= 16'd0;
            prev_dy_value2 <= 16'd0;
            prev_dy_x0     <= 7'd0;
            prev_dy_x1     <= 7'd0;
            prev_dy_x2     <= 7'd0;
            prev_dy_y0     <= 6'd0;
            prev_dy_y1     <= 6'd0;
            prev_dy_y2     <= 6'd0;
        end else begin
            // 'start' is a 1-cycle pulse
            start <= 1'b0;

            // Main FSM
            case(state)
                ST_IDLE: begin
                    char_index <= 4'd0;

                    if(is_run) begin
                        // Select next pending group by priority
                        if(fix_pending0) begin
                            cur_group      <= 3'd0;
                            cur_is_dynamic <= 1'b0;
                            cur_char_total <= 4'd8;
                            cur_word       <= fixed_char0;
                            base_x         <= fixed_x0;
                            base_y         <= fixed_y0[3:0];
                            engine_busy    <= 1'b1;
                            state          <= ST_PREP_CHAR;

                        end else if(fix_pending1) begin
                            cur_group      <= 3'd1;
                            cur_is_dynamic <= 1'b0;
                            cur_char_total <= 4'd8;
                            cur_word       <= fixed_char1;
                            base_x         <= fixed_x1;
                            base_y         <= fixed_y1[3:0];
                            engine_busy    <= 1'b1;
                            state          <= ST_PREP_CHAR;

                        end else if(fix_pending2) begin
                            cur_group      <= 3'd2;
                            cur_is_dynamic <= 1'b0;
                            cur_char_total <= 4'd8;
                            cur_word       <= fixed_char2;
                            base_x         <= fixed_x2;
                            base_y         <= fixed_y2[3:0];
                            engine_busy    <= 1'b1;
                            state          <= ST_PREP_CHAR;

                        end else if(dy_pending0) begin
                            cur_group      <= 3'd3;
                            cur_is_dynamic <= 1'b1;
                            cur_char_total <= 4'd4;
                            base_x         <= dy_x0;
                            base_y         <= dy_y0[3:0];
                            digit3         <= (dy_value0 / 1000) % 10;
                            digit2         <= (dy_value0 / 100)  % 10;
                            digit1         <= (dy_value0 / 10)   % 10;
                            digit0         <=  dy_value0 % 10;
                            engine_busy    <= 1'b1;
                            state          <= ST_PREP_CHAR;

                        end else if(dy_pending1) begin
                            cur_group      <= 3'd4;
                            cur_is_dynamic <= 1'b1;
                            cur_char_total <= 4'd4;
                            base_x         <= dy_x1;
                            base_y         <= dy_y1[3:0];
                            digit3         <= (dy_value1 / 1000) % 10;
                            digit2         <= (dy_value1 / 100)  % 10;
                            digit1         <= (dy_value1 / 10)   % 10;
                            digit0         <=  dy_value1 % 10;
                            engine_busy    <= 1'b1;
                            state          <= ST_PREP_CHAR;

                        end else if(dy_pending2) begin
                            cur_group      <= 3'd5;
                            cur_is_dynamic <= 1'b1;
                            cur_char_total <= 4'd4;
                            base_x         <= dy_x2;
                            base_y         <= dy_y2[3:0];
                            digit3         <= (dy_value2 / 1000) % 10;
                            digit2         <= (dy_value2 / 100)  % 10;
                            digit1         <= (dy_value2 / 10)   % 10;
                            digit0         <=  dy_value2 % 10;
                            engine_busy    <= 1'b1;
                            state          <= ST_PREP_CHAR;

                        end else begin
                            // No pending groups
                            engine_busy <= 1'b0;
                        end
                    end else begin
                        // Still in init/clear stage
                        engine_busy <= 1'b0;
                    end
                end

                ST_PREP_CHAR: begin
                    // Prepare ASCII code depending on fixed/dynamic mode
                    if(!cur_is_dynamic) begin
                        // fixed: 8 characters, MSB first
                        case(char_index)
                            4'd0: ascii <= cur_word[63:56];
                            4'd1: ascii <= cur_word[55:48];
                            4'd2: ascii <= cur_word[47:40];
                            4'd3: ascii <= cur_word[39:32];
                            4'd4: ascii <= cur_word[31:24];
                            4'd5: ascii <= cur_word[23:16];
                            4'd6: ascii <= cur_word[15:8];
                            4'd7: ascii <= cur_word[7:0];
                            default: ascii <= 8'h20;
                        endcase
                    end else begin
                        // Dynamic: 4 decimal digits → '0' + digit
                        case(char_index)
                            4'd0: ascii <= 8'd48 + digit3;
                            4'd1: ascii <= 8'd48 + digit2;
                            4'd2: ascii <= 8'd48 + digit1;
                            4'd3: ascii <= 8'd48 + digit0;
                            default: ascii <= 8'h20;
                        endcase
                    end

                    // Each character is 8 pixels wide
                    x <= base_x + (char_index << 3);
                    y <= base_y;

                    state <= ST_SEND_CHAR;
                end

                ST_SEND_CHAR: begin
                    // Send only when char_gen is idle
                    if(!char_busy) begin
                        start <= 1'b1;
                        state <= ST_WAIT_DONE;
                    end
                end

                ST_WAIT_DONE: begin
                    if(char_done) begin
                        if(char_index == (cur_char_total - 1)) begin
                            // Final character of this group → clear pending flag
                            case(cur_group)
                                3'd0: fix_pending0 <= 1'b0;
                                3'd1: fix_pending1 <= 1'b0;
                                3'd2: fix_pending2 <= 1'b0;
                                3'd3: dy_pending0  <= 1'b0;
                                3'd4: dy_pending1  <= 1'b0;
                                3'd5: dy_pending2  <= 1'b0;
                                default: ;
                            endcase
                            state <= ST_IDLE;
                        end else begin
                            // Continue with next character
                            char_index <= char_index + 1'b1;
                            state      <= ST_PREP_CHAR;
                        end
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase

            // Change detection (executed after FSM per cycle)

            // fixed group 0
            if( (fixed_char0 != prev_fixed_char0) ||
                (fixed_x0    != prev_fixed_x0)    ||
                (fixed_y0    != prev_fixed_y0) ) begin
                prev_fixed_char0 <= fixed_char0;
                prev_fixed_x0    <= fixed_x0;
                prev_fixed_y0    <= fixed_y0;
                fix_pending0     <= 1'b1;
            end

            // fixed group 1
            if( (fixed_char1 != prev_fixed_char1) ||
                (fixed_x1    != prev_fixed_x1)    ||
                (fixed_y1    != prev_fixed_y1) ) begin
                prev_fixed_char1 <= fixed_char1;
                prev_fixed_x1    <= fixed_x1;
                prev_fixed_y1    <= fixed_y1;
                fix_pending1     <= 1'b1;
            end

            // fixed group 2
            if( (fixed_char2 != prev_fixed_char2) ||
                (fixed_x2    != prev_fixed_x2)    ||
                (fixed_y2    != prev_fixed_y2) ) begin
                prev_fixed_char2 <= fixed_char2;
                prev_fixed_x2    <= fixed_x2;
                prev_fixed_y2    <= fixed_y2;
                fix_pending2     <= 1'b1;
            end

            // Dynamic group 0
            if( (dy_value0 != prev_dy_value0) ||
                (dy_x0     != prev_dy_x0)     ||
                (dy_y0     != prev_dy_y0) ) begin
                prev_dy_value0 <= dy_value0;
                prev_dy_x0     <= dy_x0;
                prev_dy_y0     <= dy_y0;
                dy_pending0    <= 1'b1;
            end

            // Dynamic group 1
            if( (dy_value1 != prev_dy_value1) ||
                (dy_x1     != prev_dy_x1)     ||
                (dy_y1     != prev_dy_y1) ) begin
                prev_dy_value1 <= dy_value1;
                prev_dy_x1     <= dy_x1;
                prev_dy_y1     <= dy_y1;
                dy_pending1    <= 1'b1;
            end

            // Dynamic group 2
            if( (dy_value2 != prev_dy_value2) ||
                (dy_x2     != prev_dy_x2)     ||
                (dy_y2     != prev_dy_y2) ) begin
                prev_dy_value2 <= dy_value2;
                prev_dy_x2     <= dy_x2;
                prev_dy_y2     <= dy_y2;
                dy_pending2    <= 1'b1;
            end

        end
    end

endmodule
