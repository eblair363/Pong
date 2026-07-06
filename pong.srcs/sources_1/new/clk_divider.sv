`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/26/2026 01:09:25 AM
// Design Name: 
// Module Name: clk_divider
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


module clk_divider(
    input clk,
    input locked,
    output clk_led,
    output locked_led
    );

    reg[27:0] counter = 28'd0;
    reg clk_led_en;
    localparam DIVISOR = 28'd74250000;
    
    always @(posedge clk) begin
        counter <= counter + 28'd1;
        if (counter >= DIVISOR) counter <= 28'd0;
        clk_led_en <= (counter < DIVISOR/2) ? 1'b1 : 1'b0;
     end

     assign locked_led = locked;
     assign clk_led = clk_led_en;

endmodule
