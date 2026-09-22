`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: gameLogic_tb
// Directed checks for gameLogic: reset values, ball motion/wall bounce, paddle
// motion (including the "both buttons held = no motion" case), scoring on a
// missed paddle, the post-goal serve delay, and game-over latching.
//
// frame_tick is pulsed every few pixclk edges here (not the real ~1.24M-cycle
// video-frame period) since gameLogic only reacts to frame_tick edges -- the
// real cadence is videoGen's concern, already exercised by hardware testing.
//////////////////////////////////////////////////////////////////////////////////

module gameLogic_tb;

    import pong_pkg::*;

    logic pixclk = 0;
    logic rst;
    logic frame_tick;
    logic l_up, l_down, r_up, r_down;
    logic [10:0] ball_x;
    logic [9:0]  ball_y;
    logic [9:0]  lpad_y, rpad_y;
    logic [2:0]  score_l, score_r;
    logic [2:0]  game_state;

    int errors = 0;

    gameLogic dut (
        .pixclk(pixclk), .rst(rst), .frame_tick(frame_tick),
        .l_up(l_up), .l_down(l_down), .r_up(r_up), .r_down(r_down),
        .ball_x(ball_x), .ball_y(ball_y),
        .lpad_y(lpad_y), .rpad_y(rpad_y),
        .score_l(score_l), .score_r(score_r),
        .game_state(game_state)
    );

    always #5 pixclk = ~pixclk;

    task automatic frame();
        @(negedge pixclk); frame_tick = 1;
        @(posedge pixclk);
        @(negedge pixclk); frame_tick = 0;
    endtask

    task automatic frames(input int n);
        repeat (n) frame();
    endtask

    task automatic check(input bit cond, input string msg);
        if (!cond) begin
            errors++;
            $display("[FAIL] %s", msg);
        end else begin
            $display("[ pass] %s", msg);
        end
    endtask

    initial begin
        l_up = 0; l_down = 0; r_up = 0; r_down = 0;
        frame_tick = 0;
        rst = 1;
        repeat (4) @(posedge pixclk);
        @(negedge pixclk) rst = 0;

        // --- reset values ---
        check(ball_x == BALL_X_CENTER, "ball_x centered after reset");
        check(ball_y == BALL_Y_CENTER, "ball_y centered after reset");
        check(lpad_y == PAD_Y_CENTER,  "lpad_y centered after reset");
        check(rpad_y == PAD_Y_CENTER,  "rpad_y centered after reset");
        check(score_l == 0 && score_r == 0, "scores zero after reset");
        check(game_state == 3'd0, "game_state == ST_PLAY after reset");

        // --- ball motion: one frame of vx=-4, vy=+3 from reset ---
        begin
            automatic int x0 = ball_x, y0 = ball_y;
            frame();
            check(ball_x == x0 - 4, "ball_x decreases by BALL_SPEED_X per frame");
            check(ball_y == y0 + 3, "ball_y increases by BALL_SPEED_Y per frame");
        end

        // --- paddle motion: single button moves it, both buttons cancel ---
        begin
            automatic int y0 = lpad_y;
            l_up = 1;
            frame();
            check(lpad_y == y0 - 4, "l_up alone moves left paddle up by PADDLE_SPEED");
            l_down = 1; // both held now
            y0 = lpad_y;
            frame();
            check(lpad_y == y0, "holding both l_up and l_down cancels paddle motion");
            l_up = 0; l_down = 0;
        end

        // --- top/bottom wall bounce: run long enough to hit both walls a few times ---
        begin
            frames(200);
            check(game_state == 3'd0, "still playing after bouncing around for a while (no accidental goal from wall bounce)");
        end

        // --- scoring: steer the left paddle away, drive the ball left until it scores ---
        rst = 1; @(posedge pixclk); @(negedge pixclk) rst = 0;
        begin
            automatic int guard = 0;
            // walk the left paddle down and out of the ball's row before the ball arrives
            r_down = 0; l_down = 1;
            frames(30); // paddle moves 4px/frame*30 = 120px, well past PAD_H=96 clearance
            l_down = 0;
            while (game_state == 3'd0 && guard < 500) begin
                frame();
                guard++;
            end
            check(guard < 500, "left paddle miss produced a state transition within 500 frames");
            check(game_state == 3'd2, "missed left paddle -> ST_GOAL_R (right scores)");
            check(score_r == 1, "score_r incremented to 1 on the miss");
            check(ball_x == BALL_X_CENTER && ball_y == BALL_Y_CENTER, "ball re-centered during serve delay");

            // serve delay: the goal-detecting frame already latched serve_timer_q
            // = SERVE_DELAY_FRAMES, so it takes SERVE_DELAY_FRAMES more frames to
            // count down to 0, plus one more for the FSM to see ==0 and switch.
            frames(89);
            check(game_state == 3'd2, "still in serve delay one frame before it elapses");
            frames(2);
            check(game_state == 3'd0, "serve delay elapsed -> back to ST_PLAY");
        end

        // --- game over: land one score short of SCORE_MAX, then force exactly one
        // more left-paddle miss. (Letting realistic multi-bounce physics decide
        // which side misses each round is not predictable round-over-round --
        // the serve-toward-the-side-that-missed rule plus wall bounces mean a
        // miss on one side doesn't guarantee the next miss lands on the same
        // side, so a real playthrough isn't a reliable way to drive score_r to
        // exactly SCORE_MAX. Poking the registered score directly targets the
        // ST_GOAL_R -> ST_GAME_OVER edge itself instead of hoping physics
        // cooperates.)
        rst = 1; @(posedge pixclk); @(negedge pixclk) rst = 0;
        begin
            automatic int guard = 0;
            dut.score_r_q = dut.SCORE_MAX - 1;
            l_down = 1; frames(30); l_down = 0;
            while (game_state == 3'd0 && guard < 500) begin frame(); guard++; end
            check(guard < 500, "final miss produced a state transition");
            check(game_state == 3'd2, "final miss -> ST_GOAL_R");
            frames(91); // clear the serve delay
            check(score_r == 7, "score_r saturated at SCORE_MAX (7)");
            check(game_state == 3'd3, "game_state == ST_GAME_OVER once score_r hits SCORE_MAX");

            // frozen: further frames shouldn't move the ball or change score
            begin
                automatic int gs = game_state, sr = score_r, bx = ball_x;
                frames(20);
                check(game_state == gs && score_r == sr && ball_x == bx, "ST_GAME_OVER is frozen (ignores frame_tick)");
            end

            // rst recovers from GAME_OVER
            rst = 1; @(posedge pixclk); @(negedge pixclk) rst = 0;
            check(game_state == 3'd0, "rst returns to ST_PLAY from ST_GAME_OVER");
            check(score_r == 0, "rst clears score_r");
        end

        if (errors == 0) $display("\nALL CHECKS PASSED");
        else              $display("\n%0d CHECK(S) FAILED", errors);

        $finish;
    end

endmodule
