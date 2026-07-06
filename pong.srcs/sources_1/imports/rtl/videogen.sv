`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: videoGen  -- 1280x720 @ 60Hz (CEA-861 Format 4), pixel clock 74.25 MHz
//   Horizontal: 1280 active + 110 front + 40 sync + 220 back = 1650 total
//   Vertical:    720 active +   5 front +  5 sync +  20 back =  750 total
//   Sync polarity: POSITIVE on both H and V
//   blank: 1 = blanking, 0 = active  (matches tmds_encoder convention)
//////////////////////////////////////////////////////////////////////////////////
module videoGen (
    input  logic       pixclk,
    input  logic       rst,
    output logic       hsync,
    output logic       vsync,
    output logic [7:0] r, g, b,
    output logic       blank
);
    logic [10:0] h_count;
    logic [9:0]  v_count;

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

    // ---- sync (POSITIVE polarity: high during the pulse) ----
    assign hsync = (h_count >= 11'd1390) && (h_count < 11'd1430);
    assign vsync = (v_count >= 10'd725) && (v_count < 10'd730);

    // ---- data enable / blanking ----
    logic active;
    assign active = (h_count < 11'd1280) && (v_count < 10'd720);
    assign blank  = ~active;

    // bar index 0..7 across the 1280 active pixels (160 px each)
    logic [2:0] bar;
    assign bar = 3'(h_count / 11'd160);

    // ---- test pattern: 8 vertical color bars ----
    // Unconditional defaults first => provably combinational, no latch.
    always_comb begin
        r = 8'h00; g = 8'h00; b = 8'h00;
        if (active) begin
            case (bar)
                3'd0: begin r = 8'hFF; g = 8'hFF; b = 8'hFF; end // white
                3'd1: begin r = 8'hFF; g = 8'hFF; b = 8'h00; end // yellow
                3'd2: begin r = 8'h00; g = 8'hFF; b = 8'hFF; end // cyan
                3'd3: begin r = 8'h00; g = 8'hFF; b = 8'h00; end // green
                3'd4: begin r = 8'hFF; g = 8'h00; b = 8'hFF; end // magenta
                3'd5: begin r = 8'hFF; g = 8'h00; b = 8'h00; end // red
                3'd6: begin r = 8'h00; g = 8'h00; b = 8'hFF; end // blue
                3'd7: begin r = 8'h00; g = 8'h00; b = 8'h00; end // black
            endcase
        end
    end
endmodule