`timescale 1ns / 1ps
module button_debounce_tb;
    localparam int WIDTH = 2;
    localparam int STABLE_BITS = 4; // small for a fast sim

    logic clk = 0, rst;
    logic [WIDTH-1:0] raw, out;
    int errors = 0;

    button_debounce #(.WIDTH(WIDTH), .STABLE_BITS(STABLE_BITS)) dut (
        .clk(clk), .rst(rst), .raw(raw), .out(out)
    );

    always #5 clk = ~clk;

    task automatic check(input bit cond, input string msg);
        if (!cond) begin errors++; $display("[FAIL] %s", msg); end
        else              $display("[ pass] %s", msg);
    endtask

    initial begin
        raw = 2'b00; rst = 1;
        repeat (4) @(posedge clk);
        @(negedge clk) rst = 0;
        check(out == 2'b00, "out is 0 after reset");

        // a glitch shorter than the stability window should NOT propagate
        raw[0] = 1'b1;
        repeat (3) @(posedge clk); // fewer than 2 (sync) + 2**4 (counter) cycles
        raw[0] = 1'b0;
        repeat (30) @(posedge clk);
        check(out[0] == 1'b0, "a short glitch on bit0 does not propagate to out");

        // a sustained press should propagate after the stability window
        raw[1] = 1'b1;
        repeat (40) @(posedge clk); // 2 sync stages + 2**4=16 stable cycles, with margin
        check(out[1] == 1'b1, "a sustained press on bit1 propagates to out");
        check(out[0] == 1'b0, "bit0 unaffected by bit1 changing (bits independent)");

        // releasing should also debounce
        raw[1] = 1'b0;
        repeat (40) @(posedge clk);
        check(out[1] == 1'b0, "a sustained release on bit1 propagates to out");

        if (errors == 0) $display("\nALL CHECKS PASSED");
        else              $display("\n%0d CHECK(S) FAILED", errors);
        $finish;
    end
endmodule
