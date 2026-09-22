`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: gameLogic
// Ball physics, paddle motion, scoring and top-level game state, advanced once
// per video frame (on frame_tick from videoGen). Geometry comes from pong_pkg
// so it always agrees with what gameRenderer actually draws.
//
// Inputs l_up/l_down/r_up/r_down are expected to already be synchronized and
// debounced (see button_debounce) -- this module just applies "both pressed at
// once = no motion" (XOR) gating on top of that.
//
// All internal position/velocity math is done in plain (signed) `int` rather
// than hand-sized bit vectors: the design is nowhere near a resource or timing
// bottleneck (it advances once per 16.7ms frame), and using `int` throughout
// sidesteps Verilog's signed/unsigned mixing footgun (an unsigned operand in
// an expression silently makes the whole expression unsigned, which breaks
// negative-velocity/negative-position comparisons). Package constants are
// explicitly cast with int'() at each use for the same reason: they are
// unsigned logic vectors in pong_pkg (so gameRenderer's beam-position
// wraparound comparisons keep working), but must be signed here.
//////////////////////////////////////////////////////////////////////////////////

module gameLogic (
    input  logic        pixclk,
    input  logic        rst,
    input  logic        frame_tick,
    input  logic        l_up, l_down, r_up, r_down,
    output logic [10:0] ball_x,
    output logic [ 9:0] ball_y,
    output logic [ 9:0] lpad_y,
    output logic [ 9:0] rpad_y,
    output logic [ 2:0] score_l,
    output logic [ 2:0] score_r,
    output logic [ 2:0] game_state
);

    import pong_pkg::*;

    localparam int PADDLE_SPEED       = 4;   // px/frame while a direction button is held
    localparam int BALL_SPEED_X       = 4;   // px/frame
    localparam int BALL_SPEED_Y       = 3;   // px/frame
    localparam int BALL_SPEED_Y_MAX   = 8;   // clamp so paddle-edge hits can't runaway
    localparam int SERVE_DELAY_FRAMES = 90;  // ~1.5s at 60fps before the next serve
    localparam int SCORE_MAX          = 7;   // first to SCORE_MAX wins (fits the 3-bit port)

    typedef enum logic [2:0] {
        ST_PLAY,
        ST_GOAL_L,     // ball passed the left paddle plane -> right scored
        ST_GOAL_R,     // ball passed the right paddle plane -> left scored
        ST_GAME_OVER
    } state_e;

    state_e state_q, state_d;
    int ball_x_q, ball_x_d;
    int ball_y_q, ball_y_d;
    int vx_q, vx_d, vy_q, vy_d;
    int lpad_y_q, lpad_y_d, rpad_y_q, rpad_y_d;
    int score_l_q, score_l_d, score_r_q, score_r_d;
    int serve_timer_q, serve_timer_d;

    assign ball_x     = ball_x_q[10:0];
    assign ball_y     = ball_y_q[9:0];
    assign lpad_y     = lpad_y_q[9:0];
    assign rpad_y     = rpad_y_q[9:0];
    assign score_l    = score_l_q[2:0];
    assign score_r    = score_r_q[2:0];
    assign game_state = state_q;

    // "both pressed" cancels out rather than picking a direction
    wire l_move_up   = l_up   & ~l_down;
    wire l_move_down = l_down & ~l_up;
    wire r_move_up   = r_up   & ~r_down;
    wire r_move_down = r_down & ~r_up;

    function automatic int clamp_pad(input int y);
        if (y < int'(PAD_Y_MIN))      return int'(PAD_Y_MIN);
        else if (y > int'(PAD_Y_MAX)) return int'(PAD_Y_MAX);
        else                          return y;
    endfunction

    function automatic int clamp_vy(input int vy);
        if (vy > BALL_SPEED_Y_MAX)       return BALL_SPEED_Y_MAX;
        else if (vy < -BALL_SPEED_Y_MAX) return -BALL_SPEED_Y_MAX;
        else                              return vy;
    endfunction

    always_comb begin
        // defaults: hold everything
        state_d       = state_q;
        ball_x_d      = ball_x_q;
        ball_y_d      = ball_y_q;
        vx_d          = vx_q;
        vy_d          = vy_q;
        lpad_y_d      = lpad_y_q;
        rpad_y_d      = rpad_y_q;
        score_l_d     = score_l_q;
        score_r_d     = score_r_q;
        serve_timer_d = serve_timer_q;

        // paddles are free to move every frame, even during a serve delay
        if (l_move_up)        lpad_y_d = clamp_pad(lpad_y_q - PADDLE_SPEED);
        else if (l_move_down) lpad_y_d = clamp_pad(lpad_y_q + PADDLE_SPEED);
        if (r_move_up)        rpad_y_d = clamp_pad(rpad_y_q - PADDLE_SPEED);
        else if (r_move_down) rpad_y_d = clamp_pad(rpad_y_q + PADDLE_SPEED);

        unique case (state_q)
            ST_PLAY: begin
                automatic int nx  = ball_x_q + vx_q;
                automatic int ny  = ball_y_q + vy_q;
                automatic int nvx = vx_q;
                automatic int nvy = vy_q;
                automatic bit  l_hit, r_hit, scored;

                // top/bottom wall bounce
                if (ny <= int'(FIELD_Y0)) begin
                    ny  = int'(FIELD_Y0);
                    nvy = -nvy;
                end else if (ny >= int'(FIELD_Y1) - int'(BALL_H)) begin
                    ny  = int'(FIELD_Y1) - int'(BALL_H);
                    nvy = -nvy;
                end

                // did the ball's (new) vertical span overlap a paddle's span?
                l_hit  = (ny + int'(BALL_H) > lpad_y_d) && (ny < lpad_y_d + int'(PAD_H));
                r_hit  = (ny + int'(BALL_H) > rpad_y_d) && (ny < rpad_y_d + int'(PAD_H));
                scored = 1'b0;

                if (nx <= int'(LPAD_X) + int'(PAD_W)) begin
                    if (l_hit) begin
                        nx  = int'(LPAD_X) + int'(PAD_W);
                        nvx = -nvx;
                        nvy = clamp_vy(nvy + ((ny + int'(BALL_H)/2) - (lpad_y_d + int'(PAD_H)/2)) / 4);
                    end else if (nx < int'(LPAD_X)) begin
                        state_d       = ST_GOAL_R;
                        score_r_d     = (score_r_q >= SCORE_MAX) ? score_r_q : score_r_q + 1;
                        serve_timer_d = SERVE_DELAY_FRAMES;
                        scored        = 1'b1;
                    end
                end else if ((nx + int'(BALL_W)) >= int'(RPAD_X)) begin
                    if (r_hit) begin
                        nx  = int'(RPAD_X) - int'(BALL_W);
                        nvx = -nvx;
                        nvy = clamp_vy(nvy + ((ny + int'(BALL_H)/2) - (rpad_y_d + int'(PAD_H)/2)) / 4);
                    end else if ((nx + int'(BALL_W)) > (int'(RPAD_X) + int'(PAD_W))) begin
                        state_d       = ST_GOAL_L;
                        score_l_d     = (score_l_q >= SCORE_MAX) ? score_l_q : score_l_q + 1;
                        serve_timer_d = SERVE_DELAY_FRAMES;
                        scored        = 1'b1;
                    end
                end

                // on a miss, snap straight to center rather than letting the
                // ball sit one frame past the paddle plane before ST_GOAL_*'s
                // own re-centering logic takes over next frame
                if (scored) begin
                    ball_x_d = int'(BALL_X_CENTER);
                    ball_y_d = int'(BALL_Y_CENTER);
                end else begin
                    ball_x_d = nx;
                    ball_y_d = ny;
                end
                vx_d = nvx;
                vy_d = nvy;
            end

            ST_GOAL_L, ST_GOAL_R: begin
                // hold the ball at center during the serve delay
                ball_x_d = int'(BALL_X_CENTER);
                ball_y_d = int'(BALL_Y_CENTER);

                if (serve_timer_q == 0) begin
                    if ((state_q == ST_GOAL_L && score_l_q >= SCORE_MAX) ||
                        (state_q == ST_GOAL_R && score_r_q >= SCORE_MAX)) begin
                        state_d = ST_GAME_OVER;
                    end else begin
                        // serve toward whichever side just missed
                        vx_d    = (state_q == ST_GOAL_L) ? -BALL_SPEED_X : BALL_SPEED_X;
                        vy_d    = BALL_SPEED_Y;
                        state_d = ST_PLAY;
                    end
                end else begin
                    serve_timer_d = serve_timer_q - 1;
                end
            end

            ST_GAME_OVER: begin
                // frozen; only rst leaves this state
            end

            default: state_d = ST_PLAY;
        endcase
    end

    always_ff @(posedge pixclk) begin
        if (rst) begin
            state_q       <= ST_PLAY;
            ball_x_q      <= int'(BALL_X_CENTER);
            ball_y_q      <= int'(BALL_Y_CENTER);
            vx_q          <= -BALL_SPEED_X;
            vy_q          <= BALL_SPEED_Y;
            lpad_y_q      <= int'(PAD_Y_CENTER);
            rpad_y_q      <= int'(PAD_Y_CENTER);
            score_l_q     <= 0;
            score_r_q     <= 0;
            serve_timer_q <= 0;
        end else if (frame_tick) begin
            state_q       <= state_d;
            ball_x_q      <= ball_x_d;
            ball_y_q      <= ball_y_d;
            vx_q          <= vx_d;
            vy_q          <= vy_d;
            lpad_y_q      <= lpad_y_d;
            rpad_y_q      <= rpad_y_d;
            score_l_q     <= score_l_d;
            score_r_q     <= score_r_d;
            serve_timer_q <= serve_timer_d;
        end
    end

endmodule
