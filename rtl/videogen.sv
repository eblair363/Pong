module videoGen (
  input pixclk,
  output [9:0] hsync, vsync
);

reg [9:0] h_count, v_count;
wire [7:0] r, b, g;

//Generate the horizontal pixels until 800,
//then vertical for 525 to account for offscreen area
always_ff @(posedge pixclk) begin
  h_count <= (h_count >= 799) ? 0 : h_count + 2'b1;
  v_count <= (h_count == 799 && v_count >= 524) ? 0 : v_count + 2'b1;  
end

//implement the comparator to get hsync and vsync
//for hsync and vsync, in the range of Active Video + Front Porch to this + Sync Pulse
hsync = (h_count >= 656 && h_count < 752);
vsync = (v_count >= 491 && v_count < 493);

//pattern generation: arbitrary bitwise operations on red, green, blue signals
r = 


endmodule
