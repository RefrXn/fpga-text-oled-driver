//____________________________________________________//
//    ______ _______ _______  ______ _     _ __   _   //
//   |_____/ |______ |______ |_____/  \___/  | \  |   //
//   |    \_ |______ |       |    \_ _/   \_ |  \_|   //
//____________________________________________________//

module oled_clear(
    input               clk_50m,         // 50MHz clock
    input               rst_n,           // Active-low reset

    input               refresh_req,     // External refresh trigger (not used internally)
    input               write_done,      // IIC write byte finished

    output              refresh_finish,  // Asserted when entire clear process finished

    output [23:0]       refresh_data     // 24-bit formatted IIC output data
);

reg [23:00]            refresh_data_reg; // 24-bit IIC frame: {slave, control, data}
reg [10:0]             refresh_index;    // Counts from 0 to 130 for each page
reg [2:0]              page;             // OLED has 8 pages (0~7)

assign refresh_data = refresh_data_reg;

// When page = 7 AND index = 130 AND last write is done → clearing completed
assign refresh_finish =
    (page == 'd7 && refresh_index == 'd130 && write_done == 1'b1) ? 1'b1 : 1'b0;

// --------------------------------------------------------------
// refresh_index counter (0~130: 3 command bytes + 128 pixel bytes)
// --------------------------------------------------------------
always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n)
        refresh_index <= 'd0;
    else if (refresh_index == 'd130 && write_done == 1'b1)
        refresh_index <= 'd0;              // restart index when one page is done
    else if (write_done == 1'b1)
        refresh_index <= refresh_index + 1'b1; // next byte
    else
        refresh_index <= refresh_index;
end

// --------------------------------------------------------------
// Page auto-increment (0 → 7)
// --------------------------------------------------------------
always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n)
        page <= 'd0;
    else if (refresh_index == 'd130 && write_done == 1'b1)
        page <= page + 1'b1;               // go to next OLED page
    else
        page <= page;
end

// --------------------------------------------------------------
// Generate OLED IIC command/data frames
// index = 0   → send page select command
// index = 1/2 → send column address commands
// index = 3~130 → send display data (all zeros for clearing)
// --------------------------------------------------------------
always @(*) begin
    case (refresh_index)

        'd0:
            refresh_data_reg <= {8'h78, 8'h00, 8'hB0 + page};
            // Slave=0x78, Command mode, Set page address (B0~B7)

        'd1:
            refresh_data_reg <= {8'h78, 8'h00, 8'h00};
            // Set lower column address = 0x00

        'd2:
            refresh_data_reg <= {8'h78, 8'h00, 8'h10};
            // Set higher column address = 0x10

        default:
            refresh_data_reg <= {8'h78, 8'h40, 8'h00};
            // Data mode (0x40), pixel data = 0x00 (clear screen)

    endcase
end

endmodule
