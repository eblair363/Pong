`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Package: pong_pkg
// Shared playfield/paddle/ball geometry so gameRenderer (drawing) and gameLogic
// (collision/physics) can never drift out of sync with each other.
//////////////////////////////////////////////////////////////////////////////////

package pong_pkg;

    localparam int H_ACTIVE  = 1280;
    localparam int V_ACTIVE  = 720;
    localparam int MARGIN    = 100;
    localparam int THICKNESS = 8;

    // inner play-field bounds (inside the drawn border), half-open [X0,X1) / [Y0,Y1)
    localparam logic [10:0] FIELD_X0 = 11'(MARGIN + THICKNESS);
    localparam logic [10:0] FIELD_X1 = 11'(H_ACTIVE - MARGIN - THICKNESS);
    localparam logic [9:0]  FIELD_Y0 = 10'(MARGIN + THICKNESS);
    localparam logic [9:0]  FIELD_Y1 = 10'(V_ACTIVE - MARGIN - THICKNESS);

    localparam logic [10:0] LPAD_X = 11'd230;
    localparam logic [10:0] RPAD_X = 11'd1050;
    localparam logic [10:0] PAD_W  = 11'd16;
    localparam logic [9:0]  PAD_H  = 10'd96;
    localparam logic [10:0] BALL_W = 11'd16;
    localparam logic [9:0]  BALL_H = 10'd16;

    // legal range for a paddle's top-left y so it stays fully inside the field
    localparam logic [9:0] PAD_Y_MIN = FIELD_Y0;
    localparam logic [9:0] PAD_Y_MAX = FIELD_Y1 - PAD_H;

    // centered starting positions (ball centered in the field, paddles centered vertically)
    localparam logic [10:0] BALL_X_CENTER = FIELD_X0 + ((FIELD_X1 - FIELD_X0) - BALL_W) / 2;
    localparam logic [9:0]  BALL_Y_CENTER = FIELD_Y0 + ((FIELD_Y1 - FIELD_Y0) - BALL_H) / 2;
    localparam logic [9:0]  PAD_Y_CENTER  = (PAD_Y_MIN + PAD_Y_MAX) / 2;

endpackage
