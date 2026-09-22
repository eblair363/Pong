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
    input mmcmclk, rst, //sw_test,
    input btn_l_up, btn_l_down, btn_r_up, btn_r_down,
    output led0,
    output led1,
    output led2,
    output [2:0] tmds_data_p, tmds_data_n,
    output tmds_clk_p, tmds_clk_n
    //output debug_clk_serial
    );

    (* mark_debug = "true" *) logic [9:0] tmds_out_blue, tmds_out_green, tmds_out_red;
    (* mark_debug = "true" *) logic [7:0] r_internal, g_internal, b_internal;
    (* mark_debug = "true" *) logic [1:0] ctrl_internal;
    (* mark_debug = "true" *) logic blank_internal, locked_internal;
    (* keep = "true" *) reg [9:0] tmds_constant;

    wire pixclk_internal, sysclk_internal;
    wire clk_rst, serdes_out_1, serdes_out_2, serdes_out_3, tmdsclk_internal;
    wire [9:0] beam_y_internal;
    wire [10:0] beam_x_internal;
    wire frame_tick_internal;

    wire [3:0] btn_raw, btn_debounced;
    wire [10:0] ball_x_internal;
    wire [9:0]  ball_y_internal, lpad_y_internal, rpad_y_internal;
    wire [2:0]  score_l_internal, score_r_internal, game_state_internal;

    assign btn_raw   = {btn_l_up, btn_l_down, btn_r_up, btn_r_down};
    assign led2      = (game_state_internal == 3'd3); // lit once ST_GAME_OVER is reached

    wire [7:0] r_game, g_game, b_game;
    wire [7:0] r_test, g_test, b_test;

    assign clk_rst = rst | ~locked_internal;
//    assign r_internal = sw_test ? r_test : r_game;
//    assign g_internal = sw_test ? g_test : g_game;
//    assign b_internal = sw_test ? b_test : b_game;

    button_debounce #(.WIDTH(4)) u_button_debounce (
        .clk    (pixclk_internal),
        .rst    (clk_rst),
        .raw    (btn_raw),
        .out    (btn_debounced)
    );

    gameLogic u_game_logic (
        .pixclk     (pixclk_internal),
        .rst        (clk_rst),
        .frame_tick (frame_tick_internal),
        .l_up       (btn_debounced[3]),
        .l_down     (btn_debounced[2]),
        .r_up       (btn_debounced[1]),
        .r_down     (btn_debounced[0]),
        .ball_x     (ball_x_internal),
        .ball_y     (ball_y_internal),
        .lpad_y     (lpad_y_internal),
        .rpad_y     (rpad_y_internal),
        .score_l    (score_l_internal),
        .score_r    (score_r_internal),
        .game_state (game_state_internal)
    );

    gameRenderer u_game_renderer (
        .beam_x (beam_x_internal), .beam_y (beam_y_internal), .blank (blank_internal),
        .ball_x (ball_x_internal), .ball_y (ball_y_internal),
        .lpad_y (lpad_y_internal), .rpad_y (rpad_y_internal),
        .r (r_internal), .g (g_internal), .b (b_internal)
    );

    testPattern u_test_pattern (
        .beam_x (beam_x_internal), .beam_y (beam_y_internal), .blank (blank_internal),
        .r (r_test), .g (g_test), .b (b_test)
    );
    
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
    
    always @(posedge pixclk_internal) 
        if (clk_rst)
            tmds_constant <= 10'b0;
        else
            tmds_constant <= 10'b1111100000;
    
    serializer_10to1 u_serializer_10to1_tmdsclk (
        .d_in   (tmds_constant),
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
    
//    OBUF u_obuf_debug (
//    .I (tmdsclk_internal),   // the clock-lane OSERDES OQ - inherently 74.25 MHz
//    .O (debug_clk_serial)
//    );
    
    videoGen u_videoGen (
    .pixclk     (pixclk_internal),
    .rst        (clk_rst),
    .hsync      (ctrl_internal[0]),
    .vsync      (ctrl_internal[1]),
    .beam_x     (beam_x_internal),
    .beam_y     (beam_y_internal),
    .blank      (blank_internal),
    .frame_tick (frame_tick_internal)
);
    
    
endmodule

