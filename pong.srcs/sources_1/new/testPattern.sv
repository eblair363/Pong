`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/25/2026 12:35:14 PM
// Design Name: 
// Module Name: testPattern
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


module testPattern (
    input  logic [10:0] beam_x,
    input  logic [9:0]  beam_y,
    input  logic        blank,
    output logic [7:0]  r, g, b
);
    logic [2:0] bar;
    assign bar = 3'(beam_x / 11'd160);

    always_comb begin
        r = 8'h00; g = 8'h00; b = 8'h00;
        if (~blank) begin
            case (bar)
                3'd0: begin r=8'hFF; g=8'hFF; b=8'hFF; end
                3'd1: begin r=8'hFF; g=8'hFF; b=8'h00; end
                3'd2: begin r=8'h00; g=8'hFF; b=8'hFF; end
                3'd3: begin r=8'h00; g=8'hFF; b=8'h00; end
                3'd4: begin r=8'hFF; g=8'h00; b=8'hFF; end
                3'd5: begin r=8'hFF; g=8'h00; b=8'h00; end
                3'd6: begin r=8'h00; g=8'h00; b=8'hFF; end
                3'd7: begin r=8'h00; g=8'h00; b=8'h00; end
            endcase
        end
    end
endmodule
