`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/22/2026 05:02:09 PM
// Design Name: 
// Module Name: minilab0
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


module minilab0(
    input en,
    input [7:0] address,
    input clk,
    output logic [7:0] data
    );
    
    always_ff @(posedge clk) begin
        if (~en)
            data <= '0;
        else begin
            case (address)
                8'h01: data <= 8'b00110011;
                8'b10000000: data <= 8'b10101010;
                8'b01000000: data <= 8'b00000010;
                8'b00100000: data <= 8'b00101000;
                8'b00010000: data <= 8'b11111111;
                8'b00001000: data <= 8'b11110000;
                8'b00000100: data <= 8'b00001111;
                8'b00000010: data <= 8'b11001100;
                default: data <= '0;
            endcase
        end
    end
    
    
endmodule
