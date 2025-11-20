//____________________________________________________//
//    ______ _______ _______  ______ _     _ __   _   //
//   |_____/ |______ |______ |_____/  \___/  | \  |   //
//   |    \_ |______ |       |    \_ _/   \_ |  \_|   //
//____________________________________________________//

module oled_sel(
    input               clk_50m,
    input               rst_n,

    // init
    input               i_init_req,
    input   [23:0]      i_init_data,

    // clear
    input               i_clear_req,
    input   [23:0]      i_clear_data,

    // char
    input               i_char_req,
    input   [23:0]      i_char_data,

    // IIC
    output              o_iic_req,
    output  [23:0]      o_iic_data
);

    reg         r_req;
    reg [23:0]  r_data;

    // priority mux ：init > clear > char
    always @(*) begin
        r_req  = 1'b0;       // default
        r_data = 24'd0;      // default

        if (i_init_req) begin
            r_req  = 1'b1;
            r_data = i_init_data;
        end
        else if (i_clear_req) begin
            r_req  = 1'b1;
            r_data = i_clear_data;
        end
        else if (i_char_req) begin
            r_req  = 1'b1;
            r_data = i_char_data;
        end
    end


    assign o_iic_req  = r_req;
    assign o_iic_data = r_data;

endmodule