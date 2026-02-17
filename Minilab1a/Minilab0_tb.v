`timescale 1ns / 1ps

//=======================================================
//  Testbench for Minilab0
//=======================================================

module Minilab0_tb;

// Parameters
parameter CLOCK_PERIOD = 20; // 50MHz clock (20ns period)

// DUT inputs
reg CLOCK2_50;
reg CLOCK3_50;
reg CLOCK4_50;
reg CLOCK_50;
reg [3:0] KEY;
reg [9:0] SW;

// DUT outputs
wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
wire [9:0] LEDR;

// Test variables
integer i;
reg [23:0] expected_result;

//=======================================================
//  DUT Instantiation
//=======================================================

Minilab0 dut (
    .CLOCK2_50(CLOCK2_50),
    .CLOCK3_50(CLOCK3_50),
    .CLOCK4_50(CLOCK4_50),
    .CLOCK_50(CLOCK_50),
    .HEX0(HEX0),
    .HEX1(HEX1),
    .HEX2(HEX2),
    .HEX3(HEX3),
    .HEX4(HEX4),
    .HEX5(HEX5),
    .LEDR(LEDR),
    .KEY(KEY),
    .SW(SW)
);

//=======================================================
//  Clock Generation
//=======================================================

initial begin
    CLOCK_50 = 0;
    forever #(CLOCK_PERIOD/2) CLOCK_50 = ~CLOCK_50;
end

initial begin
    CLOCK2_50 = 0;
    forever #(CLOCK_PERIOD/2) CLOCK2_50 = ~CLOCK2_50;
end

initial begin
    CLOCK3_50 = 0;
    forever #(CLOCK_PERIOD/2) CLOCK3_50 = ~CLOCK3_50;
end

initial begin
    CLOCK4_50 = 0;
    forever #(CLOCK_PERIOD/2) CLOCK4_50 = ~CLOCK4_50;
end

//=======================================================
//  Test Stimulus
//=======================================================

initial begin
    // Initialize waveform dump
    $dumpfile("Minilab0_tb.vcd");
    $dumpvars(0, Minilab0_tb);
    
    // Initialize inputs
    KEY = 4'b1111;
    SW = 10'b0;
    
    $display("==============================================");
    $display("Starting Minilab0 Testbench");
    $display("==============================================");
    
    // Apply reset
    $display("\nTime %0t: Asserting reset (KEY[0] = 0)", $time);
    KEY[0] = 0;
    #(CLOCK_PERIOD * 2);
    
    // Release reset
    $display("Time %0t: Releasing reset (KEY[0] = 1)", $time);
    KEY[0] = 1;
    #(CLOCK_PERIOD);
    
    // Wait for FILL state to complete
    $display("\nTime %0t: Entering FILL state", $time);
    $display("Waiting for FIFOs to fill...");
    
    // Monitor state transitions
    wait(LEDR[1:0] == 2'b01); // Wait for EXEC state
    $display("Time %0t: Entered EXEC state (LEDR = %b)", $time, LEDR[1:0]);
    
    wait(LEDR[1:0] == 2'b10); // Wait for DONE state
    $display("Time %0t: Entered DONE state (LEDR = %b)", $time, LEDR[1:0]);
    
    // Calculate expected result
    // FIFO is filled 8 times with:
    // datain[0] = 5, 10, 15, 20, 25, 30, 35, 40
    // datain[1] = 10, 20, 30, 40, 50, 60, 70, 80
    // MAC result = sum of (datain[0] * datain[1])
    expected_result = (5*10) + (10*20) + (15*30) + (20*40) + (25*50) + (30*60) + (35*70) + (40*80);
    
    $display("\nExpected MAC result: %d (0x%h)", expected_result, expected_result);
    
    // Wait a few cycles in DONE state
    #(CLOCK_PERIOD * 5);
    
    // Test HEX display by enabling SW[0]
    $display("\nTime %0t: Enabling HEX display (SW[0] = 1)", $time);
    SW[0] = 1;
    #(CLOCK_PERIOD * 2);
    
    // Check HEX outputs
    $display("\nHEX Display Values:");
    $display("  HEX5 = 7'b%b", HEX5);
    $display("  HEX4 = 7'b%b", HEX4);
    $display("  HEX3 = 7'b%b", HEX3);
    $display("  HEX2 = 7'b%b", HEX2);
    $display("  HEX1 = 7'b%b", HEX1);
    $display("  HEX0 = 7'b%b", HEX0);
    
    // Disable HEX display
    #(CLOCK_PERIOD * 2);
    $display("\nTime %0t: Disabling HEX display (SW[0] = 0)", $time);
    SW[0] = 0;
    #(CLOCK_PERIOD * 2);
    
    // Verify HEX displays are off
    if (HEX0 == 7'b1111111 && HEX1 == 7'b1111111 && HEX2 == 7'b1111111 &&
        HEX3 == 7'b1111111 && HEX4 == 7'b1111111 && HEX5 == 7'b1111111) begin
        $display("PASS: HEX displays turned off correctly");
    end else begin
        $display("FAIL: HEX displays did not turn off properly");
    end
    
    // Test reset during operation
    $display("\n==============================================");
    $display("Testing reset during operation");
    $display("==============================================");
    
    #(CLOCK_PERIOD * 2);
    KEY[0] = 0; // Assert reset
    #(CLOCK_PERIOD * 2);
    
    if (LEDR[1:0] == 2'b00) begin
        $display("PASS: Reset returns to FILL state");
    end else begin
        $display("FAIL: Reset did not return to FILL state");
    end
    
    KEY[0] = 1; // Release reset
    #(CLOCK_PERIOD * 2);
    
    // Wait for complete cycle again
    wait(LEDR[1:0] == 2'b10); // Wait for DONE state
    $display("Time %0t: Second cycle completed - DONE state reached", $time);
    
    // Final wait
    #(CLOCK_PERIOD * 10);
    
    $display("\n==============================================");
    $display("Testbench completed successfully!");
    $display("==============================================");
    
    $finish;
end

//=======================================================
//  Monitor state changes
//=======================================================

reg [1:0] prev_state;

initial begin
    prev_state = 2'b00;
    @(posedge CLOCK_50);
    forever begin
        @(posedge CLOCK_50);
        if (LEDR[1:0] !== prev_state) begin
            case(LEDR[1:0])
                2'b00: $display("Time %0t: State = FILL", $time);
                2'b01: $display("Time %0t: State = EXEC", $time);
                2'b10: $display("Time %0t: State = DONE", $time);
                default: $display("Time %0t: State = UNKNOWN", $time);
            endcase
            prev_state = LEDR[1:0];
        end
    end
end

//=======================================================
//  Timeout watchdog
//=======================================================

initial begin
    #(CLOCK_PERIOD * 1000); // Timeout after 1000 clock cycles
    $display("\nERROR: Testbench timeout!");
    $finish;
end

endmodule
