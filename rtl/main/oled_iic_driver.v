//____________________________________________________//
//    ______ _______ _______  ______ _     _ __   _   //
//   |_____/ |______ |______ |_____/  \___/  | \  |   //
//   |    \_ |______ |       |    \_ _/   \_ |  \_|   //
//____________________________________________________//

module oled_iic_driver(
    input           clk_50m,            // 50MHz clock
    input           rst_n,              // Active-low reset

    output          iic_scl,            // IIC SCL output
    inout           iic_sda,            // IIC SDA bidirectional

    input  [15:0]   iic_slave,          // {8-bit slave address, 8-bit register address}

    input           iic_wr_req,         // Write request trigger
    output          iic_wr_done,        // Write complete flag
    input  [7:0]    iic_wr_data,        // Data to write

    input           iic_rd_req,         // Read request trigger
    output          iic_rd_done,        // Read complete
    output [7:0]    iic_rd_data         // Data read from slave
);

    // -------------------------------
    // IIC State Machine Definitions
    // -------------------------------
    localparam IDLE   = 6'b000_001;     // IDLE state
    localparam START  = 6'b000_010;     // Generate IIC START condition
    localparam WRDATA = 6'b000_100;     // Write 8-bit data
    localparam RDDATA = 6'b001_000;     // Read 8-bit data
    localparam ACK    = 6'b010_000;     // Handle ACK/NACK phase
    localparam DONE   = 6'b100_000;     // Generate STOP condition

    localparam WAIT_TIME = 'd100;       // Timing base for SCL/SDA control

    reg [5:0]   state, next_state;      // FSM current/next state
    reg [21:0]  iic_cnt;                // Timing counter for SCL/SDA edges
    reg [3:0]   iic_bit_cnt;            // Bit count for 8-bit transfers
    reg [1:0]   iic_ack_done_cnt;       // ACK pulse counter
    reg [2:0]   iic_send_bytes;         // Number of bytes sent so far

    reg [15:0]  r_iic_slave;            // Shifting address register
    reg [7:0]   r_iic_rd_data;          // Read buffer

    reg         r_iic_wr_req;           // Latched write request

    reg         iic_tx;                 // SDA drive output (when not Z)
    reg         iic_clk;                // Internal SCL generator

    // SDA is high-Z when reading or during ACK sampling
    assign iic_sda = (state == RDDATA || (state == ACK)) ? 1'bz : iic_tx;
    assign iic_scl = iic_clk;

    assign iic_rd_data = r_iic_rd_data;

    // Assert done only at the transition out of DONE state
    assign iic_rd_done = (state != next_state && state == DONE) ? 1'b1 : 1'b0;
    assign iic_wr_done = (state != next_state && state == DONE) ? 1'b1 : 1'b0;

    // ---------------------------------------
    // Latch write request to internal register
    // ---------------------------------------
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n)
            r_iic_wr_req <= 1'b0;
        else if (iic_wr_done)
            r_iic_wr_req <= 1'b0;
        else if (iic_wr_req)
            r_iic_wr_req <= 1'b1;        // keep write request latched
        else
            r_iic_wr_req <= r_iic_wr_req;
    end

    // ---------------------
    // State Register Update
    // ---------------------
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ---------------------------
    // FSM Next-State Combinational
    // ---------------------------
    always @(*) begin
        case (state)
            IDLE:
                if (iic_wr_req || iic_rd_req)
                    next_state <= START;     // begin a transaction
                else
                    next_state <= IDLE;

            START:
                if (iic_cnt == (WAIT_TIME * 2))
                    next_state <= WRDATA;    // move to 1st write byte
                else
                    next_state <= START;

            WRDATA:
                if (iic_bit_cnt == 8 && iic_clk == 1'b0)
                    next_state <= ACK;       // go to ACK phase
                else
                    next_state <= WRDATA;

            RDDATA:
                if (iic_bit_cnt == 8 && iic_cnt == WAIT_TIME/4 && iic_clk == 1'b0)
                    next_state <= ACK;
                else
                    next_state <= RDDATA;

            ACK:
                if (iic_ack_done_cnt == 1 && iic_clk == 1'b0) begin
                    // Decide next step based on how many bytes have been sent
                    if (iic_send_bytes == 2) begin
                        if (r_iic_wr_req)
                            next_state <= DONE;     // complete write
                        else
                            next_state <= RDDATA;   // begin read
                    end
                    else if (iic_send_bytes == 2 && iic_rd_req)
                        next_state <= START;        // repeated start for read
                    else if (iic_send_bytes == 4)
                        next_state <= DONE;         // finish read
                    else
                        next_state <= WRDATA;       // continue writing
                end
                else
                    next_state <= ACK;

            DONE:
                if (iic_ack_done_cnt == 1 && iic_cnt == WAIT_TIME/4 && iic_clk == 1'b1)
                    next_state <= IDLE;             // back to idle after STOP
                else
                    next_state <= DONE;

            default:
                next_state <= IDLE;
        endcase
    end

    // Byte counter
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n)
            iic_send_bytes <= 0;
        else if (state == IDLE)
            iic_send_bytes <= 0;
        else if (state == ACK && next_state != state)
            iic_send_bytes <= iic_send_bytes + 1'b1;
    end

    // Timing counter for SCL edges
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n)
            iic_cnt <= 0;
        else if ((iic_cnt == WAIT_TIME) && state != START)
            iic_cnt <= 0;
        else if ((iic_cnt == WAIT_TIME * 2) && state != START)
            iic_cnt <= 0;
        else if (state != next_state)
            iic_cnt <= 0;
        else
            iic_cnt <= iic_cnt + 1'b1;
    end

    // Bit counter
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n)
            iic_bit_cnt <= 0;
        else if (state == IDLE || state == ACK)
            iic_bit_cnt <= 0;
        else if (state == WRDATA && iic_cnt == WAIT_TIME/2 && iic_clk == 1'b1)
            iic_bit_cnt <= iic_bit_cnt + 1'b1;
        else if (state == RDDATA && iic_cnt == WAIT_TIME/2 && iic_clk == 1'b1)
            iic_bit_cnt <= iic_bit_cnt + 1'b1;
    end

    // ACK / STOP counter
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n)
            iic_ack_done_cnt <= 0;
        else if (state != next_state)
            iic_ack_done_cnt <= 0;
        else if ((state == ACK || state == DONE) && iic_cnt == WAIT_TIME/2 && iic_clk == 1'b1)
            iic_ack_done_cnt <= iic_ack_done_cnt + 1'b1;
    end

    // Address shifting logic
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n)
            r_iic_slave <= 0;
        else if ((iic_wr_req || iic_rd_req) && state == IDLE)
            r_iic_slave <= iic_slave;                   // load new address
        else if (state == ACK && state != next_state) begin
            if (iic_send_bytes == 2)
                r_iic_slave <= {r_iic_slave[7:0], r_iic_slave[15:8]} + 1'b1;
            else
                r_iic_slave <= {r_iic_slave[7:0], r_iic_slave[15:8]};
        end
    end

    // Generate SCL clock
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n)
            iic_clk <= 1'b1;
        else if (state == START && iic_cnt == WAIT_TIME*2)
            iic_clk <= 1'b0;
        else if (state == START && iic_cnt > WAIT_TIME)
            iic_clk <= 1'b1;
        else if (state == WRDATA && iic_cnt == WAIT_TIME)
            iic_clk <= ~iic_clk;
        else if (state == RDDATA && iic_cnt == WAIT_TIME)
            iic_clk <= ~iic_clk;
        else if (state == ACK && iic_cnt == WAIT_TIME)
            iic_clk <= ~iic_clk;
        else if (state == DONE && iic_cnt == WAIT_TIME)
            iic_clk <= 1'b1;
    end

    // Generate SDA
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n)
            iic_tx <= 1'b1;
        else if (state == START && iic_cnt == WAIT_TIME/2)
            iic_tx <= 1'b0;
        else if (state == START && iic_cnt == WAIT_TIME/4)
            iic_tx <= 1'b1;
        else if (state == WRDATA && iic_cnt == WAIT_TIME/2) begin
            if (iic_clk == 1'b0 && iic_send_bytes == 2 && (iic_wr_req || r_iic_wr_req))
                iic_tx <= iic_wr_data[7 - iic_bit_cnt];
            else if (iic_clk == 1'b0)
                iic_tx <= r_iic_slave[7 - iic_bit_cnt];
        end
        else if (state == ACK)
            iic_tx <= 1'b0;
        else if (state == DONE && iic_cnt == WAIT_TIME && iic_clk == 1'b1)
            iic_tx <= 1'b1;
        else if (state == IDLE)
            iic_tx <= 1'b1;
    end

    // Read SDA on SCL high
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n)
            r_iic_rd_data <= 0;
        else if (state == RDDATA && iic_cnt == WAIT_TIME/2 && iic_clk == 1'b1)
            r_iic_rd_data <= {r_iic_rd_data[6:0], iic_sda};
    end

endmodule
