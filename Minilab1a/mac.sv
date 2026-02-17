module MAC #
(
parameter DATA_WIDTH = 8
)
(
input clk,
input rst_n,
input En,
input Clr,
input [DATA_WIDTH-1:0] Ain,
input [DATA_WIDTH-1:0] Bin,
output [DATA_WIDTH*3-1:0] Cout
);

    // Internal accumulator
    logic [DATA_WIDTH*3-1:0] Acc;
    
    // Multiply and accumulate operation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
        Acc <= '0;
        end else if (Clr) begin
        Acc <= '0;
        end else if (En) begin
        Acc <= Acc + (Ain * Bin);
        end
    end
    
    assign Cout = Acc;

endmodule