//____________________________________________________//
//    ______ _______ _______  ______ _     _ __   _   //
//   |_____/ |______ |______ |_____/  \___/  | \  |   //
//   |    \_ |______ |       |    \_ _/   \_ |  \_|   //
//____________________________________________________//

// 8x16 ASCII character generator for OLED display

module oled_char_gen(
    
    input           clk_50m,      // 50MHz system clock
    input           rst_n,        // Active-low reset

    input           start,        // Start drawing a character
    input  [7:0]    ascii,        // ASCII code of the character
    input  [6:0]    x,            // X position (column)
    input  [3:0]    y,            // Y position (page 0~7)

    output reg      busy,         // High while generating font data
    output reg      done,         // Pulses high when one character is finished

    output          iic_wr_req,   // Request to write to I2C
    output [23:0]   iic_wr_data,  // Formatted 24-bit I2C frame
    input           iic_wr_done   // I2C write byte completed
);

    // Internal Registers
    reg [4:0] font_index;         // 0~10: controls command + 8 font bytes + row switch
    reg       font_row;           // 0 = upper 8 rows, 1 = lower 8 rows (for 16-pixel height)
    reg [3:0] digit;
    reg [7:0] show_x;             // Latched X position
    reg [3:0] show_y;             // Latched Y position

    wire [7:0] fontdata;          // 8-bit column data from font ROM

    // Font ROM lookup module
    font_data u_font (
        .clk_50m   (clk_50m),
        .rst_n     (rst_n),
        .font_row  (font_row),            // Select upper/lower row
        .ascii     (ascii_latched),       // Character code
        .index     (font_index - 5'd3),   // Font byte index (0~7)
        .data      (fontdata)
    );

    // State Machine
    localparam IDLE   = 2'd0;     // Waiting for start
    localparam RUN    = 2'd1;     // Actively generating font bytes
    localparam FINISH = 2'd2;     // One character done

    reg [1:0] state, next_state;

    // FSM state update
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Condition: one 8x16 character fully drawn
    wire onefont_finish =
            (font_row   == 1'b1)  &&     // Both rows finished
            (font_index == 5'd10) &&
            (iic_wr_done == 1'b1);

    // Next-state logic
    always @(*) begin
        case(state)
            IDLE:   next_state = start ? RUN : IDLE;
            RUN:    next_state = onefont_finish ? FINISH : RUN;
            FINISH: next_state = IDLE;
            default:next_state = IDLE;
        endcase
    end

    // busy / done flag control
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            case(state)
                IDLE:   begin busy <= 1'b0; done <= 1'b0; end
                RUN:    begin busy <= 1'b1; done <= 1'b0; end
                FINISH: begin busy <= 1'b0; done <= 1'b1; end
            endcase
        end
    end

    // Latch input ASCII and coordinates
    reg [7:0] ascii_latched;

    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            ascii_latched <= 8'd0;
            show_x <= 8'd0;
            show_y <= 4'd0;
        end
        else if(state == IDLE && start) begin
            ascii_latched <= ascii;       // Store ASCII value
            show_x <= {1'b0, x};          // Align X to full byte
            show_y <= y;                  // Store start page
        end
    end

    // font_index sequencing (0~10)
    //   0-2 : OLED command bytes
    //   3-10: 8 font bytes (upper or lower row)
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n)
            font_index <= 5'd0;
        else if(state == IDLE)
            font_index <= 5'd0;
        else if(state == RUN && iic_wr_done) begin
            if(font_index == 5'd10)
                font_index <= 5'd0;            // Reset for next row
            else
                font_index <= font_index + 1'b1;
        end
    end

    // font_row switching (0 = top 8 rows, 1 = bottom 8 rows)
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n)
            font_row <= 1'b0;
        else if(state == IDLE)
            font_row <= 1'b0;                 // Always start at upper row
        else if(state == RUN && onefont_finish)
            font_row <= 1'b0;                 // Reset for next character
        else if(state == RUN && iic_wr_done && font_index == 5'd10)
            font_row <= 1'b1;                 // Switch to lower row after first 8 bytes
    end

    // Build the iic_wr_data frames
    // Each font_index generates one 24-bit frame:
    //   [23:16] = slave address 0x78
    //   [15:8]  = command/data control byte
    //   [7:0]   = payload data
    reg [23:0] reg_data;

    always @(*) begin
        case(font_index)
            5'd0:
                reg_data = {8'h78, 8'h00, 8'hB0 + show_y + font_row};
                // Set page: B0~B7 + Y offset + row (upper/lower)

            5'd1:
                reg_data = {8'h78, 8'h00, 8'h00 + show_x[3:0]};
                // Lower 4 bits of column address

            5'd2:
                reg_data = {8'h78, 8'h00, 8'h10 + show_x[7:4]};
                // Upper 4 bits of column address

            default:
                reg_data = {8'h78, 8'h40, fontdata};
                // Send actual font pixel data (8-bit column)
        endcase
    end

    assign iic_wr_data = reg_data;

    // Request I2C write during RUN state
    assign iic_wr_req = (state == RUN);

endmodule // 8x16 ASCII character generator for OLED
