`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/26/2026 04:07:18 PM
// Design Name: 
// Module Name: serializer_10to1
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


module serializer_10to1(
    input [9:0] d_in,
    input pixclk,
    input sysclk,
    input rst,
    output serial_out
    );
    
    wire cascade1;
    wire cascade2;
    
    
// OSERDESE2: Output SERial/DESerializer with bitslip
//            7 Series
// Xilinx HDL Language Template, version 2026.1

OSERDESE2 #(
   .DATA_RATE_OQ("DDR"),   // DDR, SDR
   .DATA_RATE_TQ("SDR"),   // DDR, BUF, SDR
   .DATA_WIDTH(10),         // Parallel data width (2-8,10,14)
   .INIT_OQ(1'b0),         // Initial value of OQ output (1'b0,1'b1)
   .INIT_TQ(1'b0),         // Initial value of TQ output (1'b0,1'b1)
   .SERDES_MODE("MASTER"), // MASTER, SLAVE
   .SRVAL_OQ(1'b0),        // OQ output value when RST is used (1'b0,1'b1)
   .SRVAL_TQ(1'b0),        // TQ output value when RST is used (1'b0,1'b1)
   .TBYTE_CTL("FALSE"),    // Enable tristate byte operation (FALSE, TRUE)
   .TBYTE_SRC("FALSE"),    // Tristate byte source (FALSE, TRUE)
   .TRISTATE_WIDTH(1)      // 3-state converter width (1,4)
)
OSERDESE2_MASTER_inst (
   .OFB(),             // 1-bit output: Feedback path for data
   .OQ(serial_out),               // 1-bit output: Data path output
   // SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
   .SHIFTOUT1(),
   .SHIFTOUT2(),
   .TBYTEOUT(),   // 1-bit output: Byte group tristate
   .TFB(),             // 1-bit output: 3-state control
   .TQ(),               // 1-bit output: 3-state control
   .CLK(sysclk),          // 1-bit input: High speed clock
   .CLKDIV(pixclk),       // 1-bit input: Divided clock
   // D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
   .D1(d_in[0]),
   .D2(d_in[1]),
   .D3(d_in[2]),
   .D4(d_in[3]),
   .D5(d_in[4]),
   .D6(d_in[5]),
   .D7(d_in[6]),
   .D8(d_in[7]),
   .OCE(1'b1),             // 1-bit input: Output data clock enable
   .RST(rst),             // 1-bit input: Reset
   // SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
   .SHIFTIN1(cascade1),
   .SHIFTIN2(cascade2),
   // T1 - T4: 1-bit (each) input: Parallel 3-state inputs
   .T1(1'b0),
   .T2(1'b0),
   .T3(1'b0),
   .T4(1'b0),
   .TBYTEIN(1'b0),     // 1-bit input: Byte group tristate
   .TCE(1'b0)              // 1-bit input: 3-state clock enable
);

OSERDESE2 #(
   .DATA_RATE_OQ("DDR"),   // DDR, SDR
   .DATA_RATE_TQ("SDR"),   // DDR, BUF, SDR
   .DATA_WIDTH(10),         // Parallel data width (2-8,10,14)
   .INIT_OQ(1'b0),         // Initial value of OQ output (1'b0,1'b1)
   .INIT_TQ(1'b0),         // Initial value of TQ output (1'b0,1'b1)
   .SERDES_MODE("SLAVE"), // MASTER, SLAVE
   .SRVAL_OQ(1'b0),        // OQ output value when RST is used (1'b0,1'b1)
   .SRVAL_TQ(1'b0),        // TQ output value when RST is used (1'b0,1'b1)
   .TBYTE_CTL("FALSE"),    // Enable tristate byte operation (FALSE, TRUE)
   .TBYTE_SRC("FALSE"),    // Tristate byte source (FALSE, TRUE)
   .TRISTATE_WIDTH(1)      // 3-state converter width (1,4)
)
OSERDESE2_SLAVE_inst (
   .OFB(),             // 1-bit output: Feedback path for data
   .OQ(),               // 1-bit output: Data path output
   // SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
   .SHIFTOUT1(cascade1),
   .SHIFTOUT2(cascade2),
   .TBYTEOUT(),   // 1-bit output: Byte group tristate
   .TFB(),             // 1-bit output: 3-state control
   .TQ(),               // 1-bit output: 3-state control
   .CLK(sysclk),          // 1-bit input: High speed clock
   .CLKDIV(pixclk),       // 1-bit input: Divided clock
   // D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
   .D1(1'b0),
   .D2(1'b0),
   .D3(d_in[8]),
   .D4(d_in[9]),
   .D5(1'b0),
   .D6(1'b0),
   .D7(1'b0),
   .D8(1'b0),
   .OCE(1'b1),             // 1-bit input: Output data clock enable
   .RST(rst),             // 1-bit input: Reset
   // SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
   .SHIFTIN1(1'b0),
   .SHIFTIN2(1'b0),
   // T1 - T4: 1-bit (each) input: Parallel 3-state inputs
   .T1(1'b0),
   .T2(1'b0),
   .T3(1'b0),
   .T4(1'b0),
   .TBYTEIN(1'b0),     // 1-bit input: Byte group tristate
   .TCE(1'b0)              // 1-bit input: 3-state clock enable
);


// End of OSERDESE2_inst instantiation

endmodule
