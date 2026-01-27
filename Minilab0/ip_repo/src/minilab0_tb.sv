`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/22/2026 05:12:29 PM
// Design Name: 
// Module Name: minilab0_tb
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


module minilab0_tb();

    logic clk, en;
    logic [7:0] address, data;

    minilab0 idut (.clk(clk), .address(address), .data(data), .en(en));

    initial begin
        clk = 0;
        en = 0;
        address = '0;
        
        // EN low
        @(posedge clk);
        @(negedge clk);
        
        if(data !== '0) begin
            $display("The output was not 0 for enable low.");
            $stop();
        end
        
        en = 1;
        address = 8'b10000000;
        @(posedge clk);
        @(negedge clk);
       
        if(data !== 8'b10101010) begin
            $display("Incorrect output for address 0.");
           $stop();
        end
        
        address = 8'b01000000;
        @(posedge clk);
        @(negedge clk);
       
        if(data !== 8'b00000010) begin
            $display("Incorrect output for address 1.");
            $stop();
        end
        
        address = 8'b00100000;
        @(posedge clk);
        @(negedge clk);
       
        if(data !== 8'b00101000) begin
            $display("Incorrect output for address 2.");
            $stop();
        end
        
        address = 8'b00010000;
        @(posedge clk);
        @(negedge clk);
       
        if(data !== 8'b11111111) begin
            $display("Incorrect output for address 3.");
            $stop();
        end
        
        address = 8'b00001000;
        @(posedge clk);
        @(negedge clk);
       
        if(data !== 8'b11110000) begin
            $display("Incorrect output for address 4.");
            $stop();
        end
        
            
            
        address = 8'b00000100;
        @(posedge clk);
        @(negedge clk);
       
        if(data !== 8'b00001111) begin
            $display("Incorrect output for address 5.");
            $stop();
        end
        
        address = 8'b00000010;
        @(posedge clk);
        @(negedge clk);
       
        if(data !== 8'b11001100) begin
            $display("Incorrect output for address 6.");
            $stop();
        end
        
        address = 8'b00000001;
        @(posedge clk);
        @(negedge clk);
       
        if(data !== 8'b00110011) begin
            $display("Incorrect output for address 7.");
            $stop();
        end
        
        $display("Tests passed.");
        $stop();
    
    end
    
    always #5 clk = ~clk;
    
    
endmodule
