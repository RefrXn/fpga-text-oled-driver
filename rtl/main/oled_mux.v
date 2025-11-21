// NO NEED TO USE
// PLEASE DELETE 

module oled_mux(

    input         clk_50m,
    input         rst_n,

    // from fixed char module
    input         fix_draw_start,
    input  [7:0]  fix_draw_ascii,
    input  [6:0]  fix_draw_x,
    input  [3:0]  fix_draw_y,

    // from dynamic char module
    input         dy_draw_start,
    input  [7:0]  dy_draw_ascii,
    input  [6:0]  dy_draw_x,
    input  [3:0]  dy_draw_y,

    // mux output
    output reg        start_mux,
    output reg [7:0]  ascii_mux,
    output reg [7:0]  x_mux,
    output reg [3:0]  y_mux

);

    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            start_mux <= 0;
            ascii_mux <= 0;
            x_mux     <= 0;
            y_mux     <= 0;
        end else begin
            start_mux <= 0;

            if(fix_draw_start) begin
                start_mux <= 1'b1;
                ascii_mux <= fix_draw_ascii;
                x_mux     <= fix_draw_x;
                y_mux     <= fix_draw_y;
            end else if(dy_draw_start) begin
                start_mux <= 1'b1;
                ascii_mux <= dy_draw_ascii;
                x_mux     <= dy_draw_x;
                y_mux     <= dy_draw_y;
            end
        end
    end

endmodule
