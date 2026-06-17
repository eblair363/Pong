module tmds_encoder (
  input  logic        clk, rst,
  input  logic [1:0]  ctrl,
  input  logic [7:0]  d_in,
  input  logic        blank,
  output logic [9:0]  q_out
);

  //count ones, choose XOR vs XNOR
  wire [3:0] ones = $countones(d_in);
  wire use_xnor = (ones > 4) || (ones == 4 && d_in[0] == 0);

  // Build q_m via XOR or XNOR chain
  logic [8:0] q_m;
  always_comb begin
    q_m[0] = d_in[0];
    for (int i = 1; i <= 7; i++) begin
      q_m[i] = use_xnor ? (q_m[i-1] ~^ d_in[i])   // XNOR
                        : (q_m[i-1]  ^ d_in[i]);    // XOR
    end
    q_m[8] = ~use_xnor;  // 1 = used XOR, 0 = used XNOR
  end

  //DC balance 
  wire [3:0] qm_ones = $countones(q_m[7:0]);
  wire signed [4:0] qm_balance = (5'(qm_ones) << 1) - 5'd8;
  logic signed [4:0] disparity, next_disparity;
  logic [9:0] q_encoded;
  
  always_comb begin
	if (disparity == 0 || qm_balance == 0) begin
    //balanced, send as is
		q_encoded = {1'b0, q_m[8], q_m[7:0]};
		next_disparity = disparity + qm_balance;
	end
	else if ((disparity < 0 && qm_balance < 0) || (disparity > 0 && qm_balance > 0)) begin
		//invert
    q_encoded = {1'b1, q_m[8], ~q_m[7:0]};
		next_disparity = disparity - qm_balance;
	end
	else begin
		q_encoded = {1'b0, q_m[8], q_m[7:0]};
		next_disparity = disparity + qm_balance;
	end
  end

  always_ff @(posedge clk) begin
	if (rst || blank) disparity <= 0;
	else disparity <= next_disparity;
  end



  // Control tokens for blanking period
  logic [9:0] ctrl_token;
  always_comb begin
    case (ctrl)
      2'b00: ctrl_token = 10'b1101010100;
      2'b01: ctrl_token = 10'b0010101011;
      2'b10: ctrl_token = 10'b0101010100;
      2'b11: ctrl_token = 10'b1010101011;
    endcase
  end

  // Mux: blank selects control token, else encoded data
  assign q_out = blank ? ctrl_token : q_encoded;

endmodule