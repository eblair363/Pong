module  tmds_encoder_tb;

    logic clk, rst, blank;
    logic [1:0] ctrl;
    logic [7:0] d_in;
    logic [9:0] q_out;

    tmds_encoder dut (
        .clk (clk),
        .rst (rst),
        .ctrl (ctrl),
        .d_in (d_in),
        .blank (blank),
        .q_out (q_out)
    );

    always #5 clk = ~clk; //100MHz

    initial begin
        clk = 0; rst = 0; blank = 0;
        d_in = 0; ctrl = 0;

        @(posedge clk);
        @(posedge clk);
        rst = 0;

        //test cases
        /*case 1: 
            d_in = 11110000 (equal number of 1's and 0's)
            expected output: xnor(d_in)
        */

        $finish;
    end
endmodule