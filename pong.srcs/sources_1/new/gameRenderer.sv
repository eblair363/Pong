`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/23/2026 10:09:24 AM
// Design Name: 
// Module Name: gameRenderer
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


module gameRenderer (
    input  logic [10:0] beam_x,
    input  logic [ 9:0] beam_y,
    input  logic        blank,
    input  logic [10:0] ball_x,
    input  logic [ 9:0] ball_y,
    input  logic [ 9:0] lpad_y,
    input  logic [ 9:0] rpad_y,
    output logic [ 7:0] r,
    output logic [ 7:0] g,
    output logic [ 7:0] b
);

    import pong_pkg::*;

    logic lpad_on, rpad_on, ball_on, pixel_on, inside_outer, inside_inner, border_on;


    assign lpad_on = (beam_x - LPAD_X < PAD_W) && (beam_y - lpad_y < PAD_H);
    assign rpad_on = (beam_x - RPAD_X < PAD_W) && (beam_y - rpad_y < PAD_H);
    assign ball_on = (beam_x - ball_x < BALL_W) && (beam_y - ball_y < BALL_H);

    assign inside_outer = (beam_x >= MARGIN && beam_x < H_ACTIVE - MARGIN) &&
                          (beam_y >= MARGIN && beam_y < V_ACTIVE - MARGIN);
    assign inside_inner = (beam_x >= FIELD_X0 && beam_x < FIELD_X1) &&
                          (beam_y >= FIELD_Y0 && beam_y < FIELD_Y1);

    assign border_on = inside_outer && !inside_inner;
    assign pixel_on = ~blank & (lpad_on | rpad_on | ball_on | border_on);

    always_comb begin
        r = pixel_on ? 8'hFF : 8'h00;
        g = pixel_on ? 8'hFF : 8'h00;
        b = pixel_on ? 8'hFF : 8'h00;
    end
endmodule
