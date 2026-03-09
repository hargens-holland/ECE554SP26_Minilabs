module spart(
    input  logic       clk,
    input  logic       rst,
    input  logic       iocs,
    input  logic       iorw,
    output logic       rda,
    output logic       tbr,
    input  logic [1:0] ioaddr,
    inout  wire  [7:0] databus,
    output logic       txd,
    input  logic       rxd
);

    ///////////////////////////////////
    // Interconnects between modules //
    ///////////////////////////////////
    logic [7:0] databus_out, bus_interface_out, rx_data_out;
    logic sel, wrt_db_low, wrt_db_high, wrt_tx, tx_rx_en, rd_rx;

    // Tri-state buffer used to receive and send data via the databus
    // Sel high = output, Sel low = input
    assign databus = sel ? databus_out : 8'bz;

    // Bus Interface Module
    bus_interface bus0(
        .iocs(iocs),
        .iorw(iorw),
        .ioaddr(ioaddr),
        .rda(rda),
        .tbr(tbr),
        .databus_in(databus),
        .databus_out(databus_out),
        .data_in(rx_data_out),
        .data_out(bus_interface_out),
        .wrt_db_low(wrt_db_low),
        .wrt_db_high(wrt_db_high),
        .wrt_tx(wrt_tx),
        .rd_rx(rd_rx),
        .databus_sel(sel)
    );

    // Rate Generator Module
    baud_rate_generator baud0(
        .clk(clk),
        .rst(rst),
        .en(tx_rx_en),
        .data(bus_interface_out),
        .sel_low(wrt_db_low),
        .sel_high(wrt_db_high)
    );

    // TX Module (Sends data out)
    tx tx0(
        .clk(clk),
        .rst(rst),
        .data(bus_interface_out),
        .en(tx_rx_en),
        .en_tx(wrt_tx),
        .tbr(tbr),
        .TxD(txd)
    );

    // RX Module (Receives data in)
    rx rx0(
        .clk(clk),
        .rst(rst),
        .RxD(rxd),
        .Baud(tx_rx_en),
        .RxD_data(rx_data_out),
        .RDA(rda),
        .rd_rx(rd_rx)
    );

endmodule

module bus_interface(
    input  logic       iocs,
    input  logic       iorw,
    input  logic [1:0] ioaddr,
    input  logic       rda,
    input  logic       tbr,
    input  logic [7:0] databus_in,
    output logic [7:0] databus_out,
    input  logic [7:0] data_in,
    output logic [7:0] data_out,
    output logic       wrt_db_low,
    output logic       wrt_db_high,
    output logic       wrt_tx,
    output logic       rd_rx,
    output logic       databus_sel
);

    // defaulting/initializing the signals
    always_comb begin
        data_out = 8'h00;
        wrt_db_low = 1'b0;
        wrt_db_high = 1'b0;
        wrt_tx = 1'b0;
        databus_sel = 1'b0;
        databus_out = 8'h00;
        rd_rx = 1'b0;

        // getting into different cases only when chip select is high
        if (iocs) begin
            case (ioaddr)
                2'b00: begin
                    // Receive Buffer
                    if (iorw) begin
                        databus_sel = 1'b1;
                        databus_out = data_in;
                        rd_rx = 1'b1;
                    end
                    // Transmit Buffer
                    else begin
                        data_out = databus_in;
                        wrt_tx = 1'b1;
                    end
                end
                2'b01: begin
                    // Status register
                    if (iorw) begin
                        databus_sel = 1'b1;
                        databus_out = {6'b000000, rda, tbr};
                    end
                end
                2'b10: begin
                    // low division buffer
                    data_out = databus_in;
                    wrt_db_low = 1'b1;
                end
                2'b11: begin
                    // high division buffer
                    data_out = databus_in;
                    wrt_db_high = 1'b1;
                end
                default: begin
                end
            endcase
        end
    end
endmodule

module rx(
    input  logic       clk,
    input  logic       rst,
    input  logic       RxD,
    input  logic       Baud,
    output logic [7:0] RxD_data,
    output logic       RDA,
    input  logic       rd_rx
);

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        STRTBIT = 2'b01,
        RCV     = 2'b10,
        DONE    = 2'b11
    } rx_state_t;

    rx_state_t state, nxt_state;

    logic RxD_ff1, RxD_ff2;
    logic shift, set_RDA;
    logic [7:0] RxD_shift;
    logic [3:0] bit_cnt;
    logic [4:0] baud_cnt;
    logic rst_bit_cnt, rst_baud_cnt;

    logic negedgeRxD;
    logic strt_shift;

    assign strt_shift = (baud_cnt == 5'b01000);
    assign negedgeRxD = (~RxD_ff1 && RxD_ff2);
    assign RxD_data = RxD_shift;

    ////////////////////
    // Double flop RX //
    ////////////////////
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            RxD_ff1 <= 1'b0;
            RxD_ff2 <= 1'b0;
        end else begin
            RxD_ff1 <= RxD;
            RxD_ff2 <= RxD_ff1;
        end
    end

    ///////////////////////
    // RX shift register //
    ///////////////////////
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            RxD_shift <= 8'h00;
        end else if (shift) begin
            RxD_shift <= {RxD_ff2, RxD_shift[7:1]};
        end
    end

    ////////////////////
    // Bit counter FF //
    ////////////////////
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            bit_cnt <= 4'h0;
        end else if (rst_bit_cnt) begin
            bit_cnt <= 4'h0;
        end else if (shift) begin
            bit_cnt <= bit_cnt + 4'b0001;
        end
    end

    //////////////////////////
    // Baud tick counter FF //
    //////////////////////////
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            baud_cnt <= 5'h0;
        end else if (rst_baud_cnt) begin
            baud_cnt <= 5'h0;
        end else if (Baud) begin
            baud_cnt <= baud_cnt + 5'b00001;
        end
    end

    //////////////
    // State FF //
    //////////////
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= nxt_state;
        end
    end

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            RDA <= 1'b0;
        end else begin
            RDA <= set_RDA;
        end
    end

    // Combinational logic for state machine
    always_comb begin
        rst_bit_cnt = 1'b0;
        rst_baud_cnt = 1'b0;
        set_RDA = 1'b0;
        nxt_state = IDLE;
        shift = 1'b0;

        case (state)
            IDLE: begin
                if (negedgeRxD) begin
                    nxt_state = STRTBIT;
                    rst_baud_cnt = 1'b1;
                end
            end
            STRTBIT: begin
                if (strt_shift) begin
                    rst_baud_cnt = 1'b1;
                    shift = 1'b1;
                    rst_bit_cnt = 1'b1;
                    nxt_state = RCV;
                end else begin
                    nxt_state = STRTBIT;
                end
            end
            RCV: begin
                if (baud_cnt == 5'b10000) begin
                    shift = 1'b1;
                    rst_baud_cnt = 1'b1;
                    if (bit_cnt == 4'h7) begin
                        nxt_state = DONE;
                        set_RDA = 1'b1;
                    end else begin
                        nxt_state = RCV;
                    end
                end else begin
                    nxt_state = RCV;
                end
            end
            DONE: begin
                if (rd_rx) begin
                    nxt_state = IDLE;
                end else begin
                    nxt_state = DONE;
                    set_RDA = 1'b1;
                end
            end
            default: begin
                nxt_state = IDLE;
            end
        endcase
    end

endmodule

module tx(
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] data,
    input  logic       en,
    input  logic       en_tx,
    output logic       tbr,
    output logic       TxD
);

    typedef enum logic {
        IDLE  = 1'b0,
        TRANS = 1'b1
    } tx_state_t;

    // 10-bit receive buffer (including start and stop bit)
    logic [9:0] receive_buffer;

    // 4-bit counters for enable ticks and number of shifts
    logic [3:0] en_counter, shft_counter;

    tx_state_t state, nxt_state;
    logic shft_start, shft_tick;
    logic en_start, en_tick;
    logic load, shft;

    //////////////
    // State FF //
    //////////////
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= nxt_state;
        end
    end

    ////////////////////
    // Receive Buffer //
    ////////////////////
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            receive_buffer <= 10'h001;
        end else if (load) begin
            receive_buffer <= {1'b1, data, 1'b0};
        end else if (shft) begin
            receive_buffer <= {1'b1, receive_buffer[9:1]};
        end
    end

    ////////////////////////////////
    // Enable (baud tick) counter //
    ////////////////////////////////
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            en_counter <= 4'h0;
        end else if (en_start) begin
            en_counter <= 4'hF;
        end else if (en_tick) begin
            en_counter <= en_counter - 4'b0001;
        end
    end

    ///////////////////////
    // Shift reg counter //
    ///////////////////////
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            shft_counter <= 4'h0;
        end else if (shft_start) begin
            shft_counter <= 4'h9;
        end else if (shft_tick) begin
            shft_counter <= shft_counter - 4'b0001;
        end
    end

    // TxD always gets LSB of receive_buffer
    assign TxD = receive_buffer[0];

    // Combinational FSM/output logic
    always_comb begin
        nxt_state = IDLE;
        load = 1'b0;
        en_start = 1'b0;
        en_tick = 1'b0;
        shft_start = 1'b0;
        shft_tick = 1'b0;
        shft = 1'b0;
        tbr = 1'b0;

        case (state)
            IDLE: begin
                tbr = 1'b1;
                if (en_tx) begin
                    load = 1'b1;
                    en_start = 1'b1;
                    shft_start = 1'b1;
                    nxt_state = TRANS;
                end
            end
            TRANS: begin
                tbr = 1'b0;
                if (en) begin
                    if (~(|en_counter)) begin
                        if (~(|shft_counter)) begin
                            nxt_state = IDLE;
                        end else begin
                            en_start = 1'b1;
                            shft_tick = 1'b1;
                            shft = 1'b1;
                            nxt_state = TRANS;
                        end
                    end else begin
                        en_tick = 1'b1;
                        nxt_state = TRANS;
                    end
                end else begin
                    nxt_state = TRANS;
                end
            end
            default: begin
                nxt_state = IDLE;
            end
        endcase
    end

endmodule
