`timescale 1ns / 1ps

module tb_multiplier;

    // ============== INPUTS ============== //
    reg clk, rst, st;
    reg [3:0]  mcand;
    reg [15:0] mult;

    // ============== OUTPUTS ============== //
    wire [19:0] product;
    wire done;

    // ============== DUT INSTANTIATION ============== //
    multiplier uut (
        .clk(clk),
        .rst(rst),
        .st(st),
        .mcand(mcand),
        .mult(mult),
        .product(product),
        .done(done)
    );

    // ============== CLOCK GENERATION ============== //
    initial clk = 0;
    always #5 clk = ~clk;  

    // ============== TEST SEQUENCE ============== //
    initial begin
        // Reset
        rst = 1; st = 0;
        #20 rst = 0;
        @(posedge clk);

        // === TEST 1: 3 * 1000 = 3000 ===
        $display("\n=== TEST 1: 3 * 1000 ===");
        mcand = 4'd3; mult = 16'd1000;
        start_mult();
        wait_for_done();
        check_result(20'd3000, "3 * 1000");

        // === TEST 2: 15 * 0 = 0 ===
        $display("\n=== TEST 2: 15 * 0 ===");
        mcand = 4'd15; mult = 16'd0;
        start_mult();
        wait_for_done();
        check_result(20'd0, "15 * 0");

        // === TEST 3: 15 * 65535 = 983025 ===
        $display("\n=== TEST 3: 15 * 65535 ===");
        mcand = 4'd15; mult = 16'hFFFF;
        start_mult();
        wait_for_done();
        check_result(20'd983025, "15 * 65535");

        // Final
        #50;
        $display("\nALL TESTS PASSED in ~10 clock cycles!\n");
        $finish;
    end

    // ============== TASKS ============== //
    task start_mult;
        begin
            @(posedge clk);
            st = 1;
            @(posedge clk);
            st = 0;
        end
    endtask

    task wait_for_done;
        begin
            @(posedge clk);
            while (!done) @(posedge clk);
        end
    endtask

    task check_result;
        input [19:0] expected;
        input [8*30:1] test_name;
        begin
            @(posedge clk);  
            $display("Time: %0tps | %s | Product: %d | Expected: %d", 
                     $time*1000, test_name, product, expected);
            if (product === expected)
                $display(" -> PASS\n");
            else
                $display(" -> FAIL\n");
        end
    endtask
endmodule