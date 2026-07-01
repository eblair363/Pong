`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/26/2026 11:56:46 AM
// Design Name: 
// Module Name: toplevel
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


module toplevel(
    input mmcmclk, rst,
    output led0,
    output led1,
    output [2:0] tmds_data_p, tmds_data_n,
    output tmds_clk_p, tmds_clk_n
    );
    
    wire locked_internal;
    wire pixclk_internal, sysclk_internal;
    wire clk_rst, serdes_out_1, serdes_out_2, serdes_out_3, blank_internal, tmdsclk_internal;
    wire [1:0] ctrl_internal;
    wire [7:0] r_internal,g_internal,b_internal;
    wire [9:0] tmds_out_red, tmds_out_green, tmds_out_blue;
    
    assign clk_rst = rst | ~locked_internal;
    
    clk_wiz_0 u_clk_wiz_0 (
        .clk_in1    (mmcmclk),
        .reset      (rst),
        .pixclk     (pixclk_internal),
        .sysclk     (sysclk_internal),
        .locked     (locked_internal)
    );
    
    clk_divider u_clk_divider (
        .clk        (pixclk_internal),
        .locked     (locked_internal),
        .clk_led    (led0),
        .locked_led (led1)
    );
    
    tmds_encoder u_tmds_encoder_red (
        .clk    (pixclk_internal),
        .rst    (clk_rst),
        .ctrl   (2'b00),
        .d_in   (r_internal),
        .blank  (blank_internal),
        .q_out  (tmds_out_red)
    );
    
    tmds_encoder u_tmds_encoder_green (
        .clk    (pixclk_internal),
        .rst    (clk_rst),
        .ctrl   (2'b00),
        .d_in   (g_internal),
        .blank  (blank_internal),
        .q_out  (tmds_out_green)
    );
    
    tmds_encoder u_tmds_encoder_blue (
        .clk    (pixclk_internal),
        .rst    (clk_rst),
        .ctrl   (ctrl_internal),
        .d_in   (b_internal),
        .blank  (blank_internal),
        .q_out  (tmds_out_blue)
    );
    
    serializer_10to1 u_serializer_10to1_red (
        .d_in   (tmds_out_red),
        .pixclk (pixclk_internal),
        .sysclk (sysclk_internal),
        .rst (clk_rst),
        .serial_out (serdes_out_1)
    );

    serializer_10to1 u_serializer_10to1_green (
        .d_in   (tmds_out_green),
        .pixclk (pixclk_internal),
        .sysclk (sysclk_internal),
        .rst (clk_rst),
        .serial_out (serdes_out_2)
    );

    serializer_10to1 u_serializer_10to1_blue (
        .d_in   (tmds_out_blue),
        .pixclk (pixclk_internal),
        .sysclk (sysclk_internal),
        .rst (clk_rst),
        .serial_out (serdes_out_3)
    );
    
    serializer_10to1 u_serializer_10to1_tmdsclk (
        .d_in   (10'b1111100000),
        .pixclk (pixclk_internal),
        .sysclk (sysclk_internal),
        .rst (clk_rst),
        .serial_out (tmdsclk_internal)
    );
    
    obuffer u_obuffer_1 (
        .I  (serdes_out_1),
        .O  (tmds_data_p[0]),
        .OB (tmds_data_n[0])
    );
    
    obuffer u_obuffer_2 (
        .I  (serdes_out_2),
        .O  (tmds_data_p[1]),
        .OB (tmds_data_n[1])
    );
    
    obuffer u_obuffer_3 (
        .I  (serdes_out_3),
        .O  (tmds_data_p[2]),
        .OB (tmds_data_n[2])
    );

    obuffer u_obuffer_4 (
        .I  (tmdsclk_internal),
        .O  (tmds_clk_p),
        .OB (tmds_clk_n)
    );
    
    videoGen u_videogen (
        .pixclk (pixclk_internal),
        .rst    (clk_rst),
        .hsync  (ctrl_internal[0]),
        .vsync  (ctrl_internal[1]),
        .r      (r_internal),
        .g      (g_internal),
        .b      (b_internal),
        .blank  (blank_internal)
    );
    
    
endmodule

