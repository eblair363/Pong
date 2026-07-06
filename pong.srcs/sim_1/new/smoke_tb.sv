`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/26/2026 12:27:44 AM
// Design Name: 
// Module Name: smoke_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module smoke_tb;
  logic sw0, sw1, led0, led1;
  test dut (.sw0(sw0), .sw1(sw1), .led0(led0), .led1(led1)); // match your real port names
  initial begin
    sw0 = 0; sw1 = 0; #10;
    sw0 = 1;         #10;
    sw1 = 1;         #10;
    sw0 = 0;         #10;
    $finish;
  end
endmodule
