module RAW2EDGE(
    // Inputs (same as RAW2RGB)
    input  [10:0] iX_Cont,
    input  [10:0] iY_Cont,
    input  [11:0] iDATA,
    input         iDVAL,
    input         iCLK, 
    input         iRST,
    output reg [11:0] oEdge,
    output reg        oDVAL 
);

    wire [11:0] gray;
    wire        rgb_dval;
   
    RAW2GRAY u_raw2gray (
        .iX_Cont(iX_Cont),
        .iY_Cont(iY_Cont),
        .iDATA(iDATA),
        .iDVAL(iDVAL),
        .iCLK(iCLK),
        .iRST(iRST),
        .oGray(gray),
        .oDVAL(rgb_dval)
    );

    always @(posedge iCLK or negedge iRST) begin
        if (!iRST) begin
            oEdge <= 12'd0;
            oDVAL <= 1'b0;
        end else begin
            if (rgb_dval) begin
                oEdge <= 
                oDVAL <= 1'b1;
            end else begin
                oDVAL <= 1'b0;
            end
        end
    end

endmodule