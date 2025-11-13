`timescale 1ns / 1ps
module multiplier (
    input clk,
    input rst,
    input st,
    input [3:0] mcand,
    input [15:0] mult,
    output [19:0] product,
    output done
);

    // ============== STATES (11 states) ============== //
    localparam IDLE = 4'd0,
               LOAD = 4'd1,
               ADD1 = 4'd2,
               SH1 = 4'd3,
               ADD2 = 4'd4,
               SH2 = 4'd5,
               ADD3 = 4'd6,
               SH3 = 4'd7,
               ADD4 = 4'd8,
               SH4 = 4'd9,
               DONE = 4'd10;

    reg [3:0] state, next_state;
    reg [23:0] A; // [23:16] acc, [15:0] mult
    reg Ld, Ad, Sh4;

    // ============== COMBINATIONAL LOGIC ============== //
    wire [7:0] partial = mcand * A[3:0]; // 4x4 multiplier
    wire [7:0] sum = A[23:16] + partial; // 8-bit adder

    // ============== DATAPATH: A REGISTER ============== //
    always @(posedge clk or posedge rst) begin
        if (rst)
            A <= 24'b0;
        else begin
            if (Ld)
                A <= {8'b0, mult};           // Load: A = {0, Mult}
            else if (Ad)
                A[23:16] <= sum;             // Add: A[23:16] += partial
            else if (Sh4)
                A <= A >> 4;                 // Shift right by 4
        end
    end

    // ============== NEXT STATE LOGIC ============== //
    always @(*) begin
        next_state = state;
        Ld = 0; Ad = 0; Sh4 = 0;
        case (state)
            IDLE: if (st) next_state = LOAD;
            LOAD: begin Ld = 1; next_state = ADD1; end
            ADD1: begin Ad = 1; next_state = SH1; end
            SH1:  begin Sh4 = 1; next_state = ADD2; end
            ADD2: begin Ad = 1; next_state = SH2; end
            SH2:  begin Sh4 = 1; next_state = ADD3; end
            ADD3: begin Ad = 1; next_state = SH3; end
            SH3:  begin Sh4 = 1; next_state = ADD4; end
            ADD4: begin Ad = 1; next_state = SH4; end
            SH4:  begin Sh4 = 1; next_state = DONE; end
            DONE: if (!st) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // ============== STATE REGISTER ============== //
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ============== OUTPUT REGISTER: PRODUCT ============== //
    reg [19:0] product_reg;
    assign product = product_reg;
    assign done    = (state == DONE);
    always @(posedge clk or posedge rst) begin
        if (rst)
            product_reg <= 20'b0;
        else if (state == DONE)
            product_reg <= A[19:0];  
    end

endmodule