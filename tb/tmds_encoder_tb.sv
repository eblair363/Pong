module tmds_encoder_tb;

  logic clk, rst, blank;
  logic [1:0] ctrl;
  logic [7:0] d_in;
  logic [9:0] q_out;
  logic [9:0] expected;

  tmds_encoder dut (
      .clk  (clk),
      .rst  (rst),
      .ctrl (ctrl),
      .d_in (d_in),
      .blank(blank),
      .q_out(q_out)
  );

  always #5 clk = ~clk;  //100MHz

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tmds_encoder_tb);
    clk   = 0;
    rst   = 1;
    blank = 0;
    d_in  = 0;
    ctrl  = 0;

    @(posedge clk);
    @(posedge clk);
    rst  = 0;

    //case 1:
    //equal number of 1's and 0's
    d_in = 8'b11110000;
    @(posedge clk);

    $display("d_in     = %b", d_in);
    $display("q_out    = %b", q_out);
    $display("invert   = %b", q_out[9]);
    $display("xor/xnor = %b", q_out[8]);

    @(posedge clk);
    $display("q_out after 2nd cycle = %b\n", q_out);

    //case 2:
    //feed a bunch of 1 heavy words to watch disparity climb then invert
    d_in = 8'b00111111;
    expected = 10'b0010111111;
    @(posedge clk);
    if (q_out !== expected) $error("d_in = %b got %b expected %b", d_in, q_out, expected);
    else $display("PASS: d_in = %b => %b, expected = %b", d_in, q_out, expected);
    //let it run and look at waveform sim
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);

    //case 3:
    //xor chain; ones < 4
    blank = 1;
    @(posedge clk);
    blank = 0;
    d_in = 8'b10010000;
    expected = 10'b0101110000;
    @(posedge clk);
    if (q_out !== expected) $error("d_in = %b got %b expected %b", d_in, q_out, expected);
    else $display("PASS: d_in = %b => %b, expected = %b", d_in, q_out, expected);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);

    //case 4:
    //when blank=1, are we getting the correct ctrl token
    blank = 1;
    ctrl  = 2'b00;
    @(posedge clk);
    expected = 10'b1101010100;
    if (q_out !== expected) $error("ctrl=00 got %b expected %b", q_out, expected);
    else $display("PASS: ctrl=00 => %b", q_out);

    ctrl = 2'b01;
    expected = 10'b0010101011;
    if (q_out !== expected) $error("ctrl=01 got %b expected %b", q_out, expected);
    else $display("PASS: ctrl=01 => %b", q_out);
    @(posedge clk);
  end
endmodule

