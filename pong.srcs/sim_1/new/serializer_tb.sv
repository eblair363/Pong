`timescale 1ps/1ps
module serializer_tb;
  logic [9:0] d_in;
  logic pixclk, sysclk, rst, serial_out;

  serializer_10to1 uut (
    .d_in(d_in), .pixclk(pixclk), .sysclk(sysclk),
    .rst(rst), .serial_out(serial_out)
  );

  localparam int SYS_HALF = 1347;
  localparam int PIX_HALF = SYS_HALF * 5;
  initial begin sysclk = 0; pixclk = 0; end
  always #SYS_HALF sysclk = ~sysclk;
  always #PIX_HALF pixclk = ~pixclk;

  localparam int MAXBITS = 1024;
  bit cap_buf [0:MAXBITS-1];
  int cap_n = 0;
  bit capturing = 0;

  task automatic sample();          // sample mid-UI, away from the OQ edge
    #(SYS_HALF/2);
    if (capturing && cap_n < MAXBITS) cap_buf[cap_n++] = serial_out;
  endtask
  always @(posedge sysclk) sample();
  always @(negedge sysclk) sample();

  localparam int NWORDS = 10;
  logic [9:0] words [0:NWORDS-1];
  initial foreach (words[k]) words[k] = (10'd1 << k);   // walking 1

  initial begin
    capturing = 0; rst = 1; d_in = 10'd0;
    repeat (4) @(posedge pixclk);
    @(negedge pixclk) rst = 0;

    @(posedge pixclk) capturing = 1;
    foreach (words[w]) begin d_in = words[w]; @(posedge pixclk); end
    d_in = 10'd0;
    repeat (8) @(posedge pixclk);   // generous flush so nothing is left in the pipe
    capturing = 0;

    begin
      string s = "";
      int first1 = -1;
      for (int k = 0; k < cap_n; k++) s = {s, cap_buf[k] ? "1":"0"};
      $display("cap_n=%0d", cap_n);
      $display("raw: %s", s);

      for (int k = 0; k < cap_n; k++) if (cap_buf[k]) begin first1 = k; break; end
      $display("first '1' at bit %0d  (= OSERDES latency in UIs)", first1);

      if (first1 >= 0)
        for (int w = 0; w < NWORDS && first1 + 10*w + 10 <= cap_n; w++) begin
          string g = "";
          for (int b = 0; b < 10; b++) g = {g, cap_buf[first1 + 10*w + b] ? "1":"0"};
          $display("  win %0d : %s   (input %010b)", w, g, words[w]);
        end
    end
    $finish;
  end
endmodule