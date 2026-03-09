`timescale 1ns/1ps

module spart_tb;

    logic clk;
    logic rst;
    logic [1:0] br_cfg;

    logic iocs;
    logic iorw;
    logic rda;
    logic tbr;
    logic [1:0] ioaddr;
    tri [7:0] databus;

    logic txd;
    logic rxd;

    localparam int CLK_PERIOD_NS = 20;
    localparam [1:0] BR_CFG = 2'b01; // 9600 baud setting used by driver
    localparam int DIVISOR = 16'h0145;
    localparam int BIT_CLKS = 16 * (DIVISOR + 1);

    logic [7:0] rx_in;
    logic [7:0] tx_out;

    driver drv0 (
        .clk(clk),
        .rst(rst),
        .br_cfg(br_cfg),
        .iocs(iocs),
        .iorw(iorw),
        .rda(rda),
        .tbr(tbr),
        .ioaddr(ioaddr),
        .databus(databus)
    );

    spart dut (
        .clk(clk),
        .rst(rst),
        .iocs(iocs),
        .iorw(iorw),
        .rda(rda),
        .tbr(tbr),
        .ioaddr(ioaddr),
        .databus(databus),
        .txd(txd),
        .rxd(rxd)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS/2) clk = ~clk;
    end

    task automatic send_uart_byte(input [7:0] data_byte);
        int bit_index;
        begin
            rxd = 1'b0;
            repeat (BIT_CLKS) @(posedge clk);

            for (bit_index = 0; bit_index < 8; bit_index++) begin
                rxd = data_byte[bit_index];
                repeat (BIT_CLKS) @(posedge clk);
            end

            rxd = 1'b1;
            repeat (BIT_CLKS) @(posedge clk);
        end
    endtask

    task automatic recv_uart_byte(output [7:0] data_byte);
        int bit_index;
        begin
            data_byte = 8'h00;

            @(negedge txd);

            repeat (BIT_CLKS/2) @(posedge clk);
            if (txd !== 1'b0) begin
                $error("TX start bit not valid at sample point");
            end

            repeat (BIT_CLKS) @(posedge clk);
            for (bit_index = 0; bit_index < 8; bit_index++) begin
                data_byte[bit_index] = txd;
                repeat (BIT_CLKS) @(posedge clk);
            end

            if (txd !== 1'b1) begin
                $error("TX stop bit not high");
            end
        end
    endtask

    initial begin


        br_cfg = BR_CFG;
        rxd = 1'b1;
        rst = 1'b1;

        repeat (5) @(posedge clk);
        rst = 1'b0;

        repeat (100) @(posedge clk);

        rx_in = 8'hA5;
        fork
            send_uart_byte(rx_in);
            recv_uart_byte(tx_out);
        join

        if (tx_out !== rx_in) begin
            $error("Echo mismatch: expected %02h, got %02h", rx_in, tx_out);
        end else begin
            $display("PASS: Echoed byte %02h", tx_out);
        end

        repeat (20) @(posedge clk);

        rx_in = 8'hDD;
        fork
            send_uart_byte(rx_in);
            recv_uart_byte(tx_out);
        join

        if (tx_out !== rx_in) begin
            $error("Echo mismatch: expected %02h, got %02h", rx_in, tx_out);
        end else begin
            $display("PASS: Echoed byte %02h", tx_out);
        end

        repeat (20) @(posedge clk);

        $stop();
    end

endmodule
