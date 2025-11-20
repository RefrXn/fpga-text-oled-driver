//____________________________________________________//
//    ______ _______ _______  ______ _     _ __   _   //
//   |_____/ |______ |______ |_____/  \___/  | \  |   //
//   |    \_ |______ |       |    \_ _/   \_ |  \_|   //
//____________________________________________________//

module oled_fsm(

    input        clk_50m,
    input        rst_n,

    input        init_finish,
    input        clear_finish,

    output       init_req,
    output       clear_req,
    output       is_run

);

    localparam S_INIT  = 2'd0;
    localparam S_CLEAR = 2'd1;
    localparam S_RUN   = 2'd2;

    reg [1:0] state, next_state;

    always @(posedge clk_50m or negedge rst_n)
        if(!rst_n) state <= S_INIT;
        else       state <= next_state;

    always @(*) begin
        case(state)
            S_INIT : next_state = init_finish  ? S_CLEAR : S_INIT;
            S_CLEAR: next_state = clear_finish ? S_RUN   : S_CLEAR;
            S_RUN  : next_state = S_RUN;
            default: next_state = S_INIT;
        endcase
    end

    assign init_req  = (state == S_INIT);
    assign clear_req = (state == S_CLEAR);
    assign is_run    = (state == S_RUN);

endmodule
