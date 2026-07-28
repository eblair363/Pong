`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: videoGen  -- 1280x720 @ 60Hz (CEA-861 Format 4), pixel clock 74.25 MHz
//   Horizontal: 1280 active + 110 front + 40 sync + 220 back = 1650 total
//   Vertical:    720 active +   5 front +  5 sync +  20 back =  750 total
//   Sync polarity: POSITIVE on both H and V
//   blank: 1 = blanking, 0 = active  (matches tmds_encoder convention)
//////////////////////////////////////////////////////////////////////////////////
module videoGen (
    input  logic        pixclk,
    input  logic        rst,
    output logic        hsync,
    output logic        vsync,
    output logic [10:0] beam_x,
    output logic [ 9:0] beam_y,
    output logic        blank,
    output logic        frame_tick
);
  logic [10:0] h_count;
  logic [ 9:0] v_count;

  // ---- free-running timing counters ----
  always_ff @(posedge pixclk) begin
    if (rst) begin
      h_count <= 11'd0;
      v_count <= 10'd0;
    end else if (h_count >= 11'd1649) begin
      h_count <= 11'd0;
      v_count <= (v_count >= 10'd749) ? 10'd0 : v_count + 10'd1;
    end else begin
      h_count <= h_count + 11'd1;
    end
  end

  assign frame_tick = (v_count == 10'd720) && (h_count == 11'd0);

  // ---- sync (POSITIVE polarity: high during the pulse) ----
  assign hsync = (h_count >= 11'd1390) && (h_count < 11'd1430);
  assign vsync = (v_count >= 10'd725) && (v_count < 10'd730);

  assign beam_x = h_count;
  assign beam_y = v_count;

  // ---- data enable / blanking ----
  logic active;
  assign active = (h_count < 11'd1280) && (v_count < 10'd720);
  assign blank  = ~active;

endmodule
