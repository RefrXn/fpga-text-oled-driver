//____________________________________________________//
//    ______ _______ _______  ______ _     _ __   _   //
//   |_____/ |______ |______ |_____/  \___/  | \  |   //
//   |    \_ |______ |       |    \_ _/   \_ |  \_|   //
//____________________________________________________//

module oled_init(

    input               clk_50m,
    input               rst_n,

    input               i_req,
    input               i_write_done,

    output              o_init_done,
    output [23:0]       o_data

);

    // index for initialization sequence
    reg [4:0]   r_idx;
    reg [23:0]  r_data;

    assign o_data      = r_data;
    assign o_init_done = (r_idx == 5'd26 && i_write_done);

    // index control
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n)
            r_idx <= 5'd0;
        else if (o_init_done)
            r_idx <= 5'd0;
        else if (i_write_done && i_req)
            r_idx <= r_idx + 1'b1;
    end

    // LUT for initialization data
    always @(*) begin
        case (r_idx)
            5'd0 :  r_data = {8'h78, 8'h00, 8'hAE};
            5'd1 :  r_data = {8'h78, 8'h00, 8'h00};
            5'd2 :  r_data = {8'h78, 8'h00, 8'h10};
            5'd3 :  r_data = {8'h78, 8'h00, 8'h40};
            5'd4 :  r_data = {8'h78, 8'h00, 8'hB0};
            5'd5 :  r_data = {8'h78, 8'h00, 8'h81};
            5'd6 :  r_data = {8'h78, 8'h00, 8'hFF};
            5'd7 :  r_data = {8'h78, 8'h00, 8'hA1};
            5'd8 :  r_data = {8'h78, 8'h00, 8'hA6};
            5'd9 :  r_data = {8'h78, 8'h00, 8'hA8};
            5'd10:  r_data = {8'h78, 8'h00, 8'h3F};
            5'd11:  r_data = {8'h78, 8'h00, 8'hC8};
            5'd12:  r_data = {8'h78, 8'h00, 8'hD3};
            5'd13:  r_data = {8'h78, 8'h00, 8'h00};
            5'd14:  r_data = {8'h78, 8'h00, 8'hD5};
            5'd15:  r_data = {8'h78, 8'h00, 8'h80};
            5'd16:  r_data = {8'h78, 8'h00, 8'hD8};
            5'd17:  r_data = {8'h78, 8'h00, 8'h05};
            5'd18:  r_data = {8'h78, 8'h00, 8'hD9};
            5'd19:  r_data = {8'h78, 8'h00, 8'hF1};
            5'd20:  r_data = {8'h78, 8'h00, 8'hDA};
            5'd21:  r_data = {8'h78, 8'h00, 8'h12};
            5'd22:  r_data = {8'h78, 8'h00, 8'hDB};
            5'd23:  r_data = {8'h78, 8'h00, 8'h30};
            5'd24:  r_data = {8'h78, 8'h00, 8'h8D};
            5'd25:  r_data = {8'h78, 8'h00, 8'h14};
            5'd26:  r_data = {8'h78, 8'h00, 8'hAF};

            default:
                r_data = {8'h78, 8'h00, 8'hAE};
                
        endcase
    end

endmodule
