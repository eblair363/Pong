module videoGen (
  input pixclk,
  output hsync, vsync,
  output [7:0] r,g,b,
  output blank // active-low: high = active video
);


  reg [9:0] h_count, v_count;
  wire [7:0] r, b, g;

  //Generate the horizontal pixels until 800,
  //then vertical for 525 to account for offscreen area
  always_ff @(posedge pixclk) begin
    if (h_count >= 799) begin
      h_count <= 0;
      v_count <= (v_count >= 524) ? 0 : v_count + 1;
    end else begin
      h_count <= h_count + 1;
    end
  end

  //implement the comparator to get hsync and vsync
  //for hsync and vsync, in the range of Active Video + Front Porch to this + Sync Pulse
  assign hsync = (h_count >= 656 && h_count < 752);
  assign vsync = (v_count >= 491 && v_count < 493);

  wire active = (h_count < 640) && (v_count < 480);
  assign blank = active;

	
  // Test pattern: color bars / gradient
  always_comb begin
    if (!active) begin
      r = 0; g = 0; b = 0;
    end else begin
      // Horizontal color bars (8 bars)
      case (h_count[9:7])
        3'd0: begin r = 8'hFF; g = 8'hFF; b = 8'hFF; end // white
        3'd1: begin r = 8'hFF; g = 8'hFF; b = 8'h00; end // yellow
        3'd2: begin r = 8'h00; g = 8'hFF; b = 8'hFF; end // cyan
        3'd3: begin r = 8'h00; g = 8'hFF; b = 8'h00; end // green
        3'd4: begin r = 8'hFF; g = 8'h00; b = 8'hFF; end // magenta
        3'd5: begin r = 8'hFF; g = 8'h00; b = 8'h00; end // red
        3'd6: begin r = 8'h00; g = 8'h00; b = 8'hFF; end // blue
        3'd7: begin r = 8'h00; g = 8'h00; b = 8'h00; end // black
      endcase
      // Gradient overlay on green from v_count
      g = g & v_count[7:0];
    end
  end

endmodule
