`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: button_debounce
// Synchronizes WIDTH async, bouncy pushbutton inputs into clk's domain and
// debounces them: an input bit only propagates to `out` once it has held
// steady (post-synchronizer) for 2**STABLE_BITS consecutive clk cycles.
// At pixclk = 74.25 MHz, STABLE_BITS=20 gives ~14ms of required stability,
// comfortably longer than typical mechanical switch bounce (a few ms).
//////////////////////////////////////////////////////////////////////////////////

module button_debounce #(
    parameter int WIDTH       = 4,
    parameter int STABLE_BITS = 20
) (
    input  logic             clk,
    input  logic             rst,
    input  logic [WIDTH-1:0] raw,
    output logic [WIDTH-1:0] out
);

    logic [WIDTH-1:0] sync0, sync1;
    logic [WIDTH-1:0] stable_val;
    logic [STABLE_BITS-1:0] counter [WIDTH-1:0];

    // 2-flop synchronizer: raw pins are fully asynchronous to clk
    always_ff @(posedge clk) begin
        sync0 <= raw;
        sync1 <= sync0;
    end

    genvar i;
    generate
        for (i = 0; i < WIDTH; i++) begin : g_debounce
            always_ff @(posedge clk) begin
                if (rst) begin
                    counter[i]    <= '0;
                    stable_val[i] <= 1'b0;
                    out[i]        <= 1'b0;
                end else if (sync1[i] != stable_val[i]) begin
                    // input disagrees with the last committed value: keep counting
                    // as long as it stays put; any change resets the count.
                    if (counter[i] == {STABLE_BITS{1'b1}}) begin
                        stable_val[i] <= sync1[i];
                        out[i]        <= sync1[i];
                        counter[i]    <= '0;
                    end else begin
                        counter[i] <= counter[i] + 1'b1;
                    end
                end else begin
                    counter[i] <= '0;
                end
            end
        end
    endgenerate

endmodule
