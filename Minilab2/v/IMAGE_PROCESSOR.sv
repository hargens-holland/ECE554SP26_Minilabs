module IMAGE_PROCESSOR(
    output [11:0] oGrey_R,
    output [11:0] oGrey_G,
    output [11:0] oGrey_B,
    output        oDVAL,
    input  [10:0] iX_Cont,
    input  [10:0] iY_Cont,
    input  [11:0] iDATA,
    input         iDVAL,
    input         iCLK,
    input         iRST,
    input         iSW
);

    wire [11:0] oRed;
    wire [11:0] oGreen;
    wire [11:0] oBlue;
    wire [11:0] oGrey;  // intermediate gray value computed from RGB
    
    wire [11:0] y;
    wire [11:0] abs_y;
    wire [11:0] out_y;
    
    wire [11:0] mDATA_0;
    wire [11:0] mDATA_1;
    
    wire [11:0] cDATA_0;
    wire [11:0] cDATA_1;
    wire [11:0] cDATA_2;

    // Image boundary detection for zero padding.
    localparam int unsigned X_MAX = 11'd1279;
    localparam int unsigned Y_MAX = 11'd959;
    wire at_left;
    wire at_right;
    wire at_top;
    wire at_bottom;

    assign at_left = (iX_Cont == 0);
    assign at_right = (iX_Cont == X_MAX);
    assign at_top = (iY_Cont == 0);
    assign at_bottom = (iY_Cont == Y_MAX);

    // Zero-padded 3x3 window taps.
    wire signed [11:0] zp_p0;
    wire signed [11:0] zp_p1;
    wire signed [11:0] zp_p2;
    wire signed [11:0] zp_p3;
    wire signed [11:0] zp_p4;
    wire signed [11:0] zp_p5;
    wire signed [11:0] zp_p6;
    wire signed [11:0] zp_p7;
    wire signed [11:0] zp_p8;

    assign zp_p0 = (at_top || at_left) ? 12'sd0 : $signed(cDATAdd_2);
    assign zp_p1 = at_top ? 12'sd0 : $signed(cDATAd_2);
    assign zp_p2 = (at_top || at_right) ? 12'sd0 : $signed(cDATA_2);
    assign zp_p3 = at_left ? 12'sd0 : $signed(cDATAdd_1);
    assign zp_p4 = $signed(cDATAd_1);
    assign zp_p5 = at_right ? 12'sd0 : $signed(cDATA_1);
    assign zp_p6 = (at_bottom || at_left) ? 12'sd0 : $signed(cDATAdd_0);
    assign zp_p7 = at_bottom ? 12'sd0 : $signed(cDATAd_0);
    assign zp_p8 = (at_bottom || at_right) ? 12'sd0 : $signed(cDATA_0);
    
    // Delay registers for the outputs of the first line buffer.
    reg [11:0] mDATAd_0;
    reg [11:0] mDATAd_1;
    
    // Registers for delaying the 3-tap outputs (so that the 3x3 window is formed).
    reg [11:0] cDATAd_0;
    reg [11:0] cDATAd_1;
    reg [11:0] cDATAd_2;
    
    reg [11:0] cDATAdd_0;
    reg [11:0] cDATAdd_1;
    reg [11:0] cDATAdd_2;
    
    // Registers to create an RGB combination from the line buffer data.
    reg [11:0] mCCD_R;
    reg [12:0] mCCD_G;
    reg [11:0] mCCD_B;
    reg        mDVAL;
    
    // The raw RGB values (from the CCD processing) are available here.
    assign oRed   = mCCD_R;
    assign oGreen = mCCD_G[12:1];
    assign oBlue  = mCCD_B;
    
    // Generate the gray value.
    assign oGrey = (oRed + oGreen + oGreen + oBlue) / 4;
    
    assign oGrey_R = out_y;
    assign oGrey_G = out_y;
    assign oGrey_B = out_y;
    
    assign oDVAL = mDVAL;

    Line_Buffer1 u0 (
        .clken(iDVAL),
        .clock(iCLK),
        .shiftin(iDATA),
        .taps0x(mDATA_1),
        .taps1x(mDATA_0)
    );

    Line_Buffer2 u1 (
        .clken(mDVAL),
        .clock(iCLK),
        .shiftin(oGrey),
        .taps0x(cDATA_0),
        .taps1x(cDATA_1),
        .taps2x(cDATA_2)
    );
    
    Convolution_Filter conv_filter (
        .clk(iCLK),
        .isHorz(iSW),
        .X_p0(zp_p0),
        .X_p1(zp_p1),
        .X_p2(zp_p2),
        .X_p3(zp_p3),
        .X_p4(zp_p4),
        .X_p5(zp_p5),
        .X_p6(zp_p6),
        .X_p7(zp_p7),
        .X_p8(zp_p8),
        .y(y)
    );

    Abs a1 (
        .in(y),
        .out(abs_y)
    );
    
    // With zero padding, keep the convolution output for all pixels.
    assign out_y = abs_y;
                    
    always @(posedge iCLK or negedge iRST) begin
        if (!iRST) begin
            mCCD_R    <= 0;
            mCCD_G    <= 0;
            mCCD_B    <= 0;
            mDATAd_0  <= 0;
            mDATAd_1  <= 0;
            cDATAd_0  <= 0;
            cDATAd_1  <= 0;
            cDATAd_2  <= 0;
            cDATAdd_0 <= 0;
            cDATAdd_1 <= 0;
            cDATAdd_2 <= 0;
            mDVAL     <= 0;
        end else begin
            mDATAd_0  <= mDATA_0;
            mDATAd_1  <= mDATA_1;
            // Delay for convolution line buffer taps.
            cDATAd_0  <= cDATA_0;
            cDATAd_1  <= cDATA_1;
            cDATAd_2  <= cDATA_2;
            cDATAdd_0 <= cDATAd_0;
            cDATAdd_1 <= cDATAd_1;
            cDATAdd_2 <= cDATAd_2;
            mDVAL     <= ({iY_Cont[0], iX_Cont[0]} == 2'b00) ? iDVAL : 1'b0;
            
            if ({iY_Cont[0], iX_Cont[0]} == 2'b10) begin
                mCCD_R <= mDATA_0;
                mCCD_G <= mDATAd_0 + mDATA_1;
                mCCD_B <= mDATAd_1;
            end else if ({iY_Cont[0], iX_Cont[0]} == 2'b11) begin
                mCCD_R <= mDATAd_0;
                mCCD_G <= mDATA_0 + mDATAd_1;
                mCCD_B <= mDATA_1;
            end else if ({iY_Cont[0], iX_Cont[0]} == 2'b00) begin
                mCCD_R <= mDATA_1;
                mCCD_G <= mDATA_0 + mDATAd_1;
                mCCD_B <= mDATAd_0;
            end else if ({iY_Cont[0], iX_Cont[0]} == 2'b01) begin
                mCCD_R <= mDATAd_1;
                mCCD_G <= mDATAd_0 + mDATA_1;
                mCCD_B <= mDATA_0;
            end
        end
    end

endmodule

module Convolution_Filter (
    input                  clk,
    input                  isHorz,
    input  signed [11:0]   X_p0, 
    input  signed [11:0]   X_p1, 
    input  signed [11:0]   X_p2, 
    input  signed [11:0]   X_p3, 
    input  signed [11:0]   X_p4,
    input  signed [11:0]   X_p5, 
    input  signed [11:0]   X_p6, 
    input  signed [11:0]   X_p7,  
    input  signed [11:0]   X_p8, 
    output signed [11:0]   y
);

    wire signed [11:0] k_tl, k_tc, k_tr;
    wire signed [11:0] k_ml, k_mc, k_mr;
    wire signed [11:0] k_bl, k_bc, k_br;

    // Set coefficients based on the filter direction.
    // For horizontal filtering (isHorz == 1):
    //   k_tl =  -1,  k_tc =  -2,  k_tr =  -1,
    //   k_ml =  0,  k_mc =  0,  k_mr =  0,
    //   k_bl = 1,  k_bc = 2 k_br = 1.
    //
    // For vertical filtering (isHorz == 0):
    //   k_tl =  -1,  k_tc =  0,  k_tr =  1,
    //   k_ml =  -2,  k_mc =  0,  k_mr = 2,
    //   k_bl =  -1,  k_bc =  0,  k_br = 1.
    assign k_tl = -12'd1;
    assign k_tc =  isHorz ? -12'd2 : 12'd0;
    assign k_tr =  isHorz ? -12'd1 : 12'd1;
    assign k_ml =  isHorz ? 12'd0 : -12'd2;
    assign k_mc =  12'd0;
    assign k_mr =  isHorz ? 12'd0 : 12'd2;
    assign k_bl =  isHorz ? 12'd1 : -12'd1;
    assign k_bc =  isHorz ? 12'd2 : 12'd0;
    assign k_br = 12'd1;

    assign y = (X_p0 * k_tl) + (X_p1 * k_tc) + (X_p2 * k_tr) +
               (X_p3 * k_ml) + (X_p4 * k_mc) + (X_p5 * k_mr) +
               (X_p6 * k_bl) + (X_p7 * k_bc) + (X_p8 * k_br);

endmodule