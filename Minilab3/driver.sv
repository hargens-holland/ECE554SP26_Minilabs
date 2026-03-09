module driver(
    input clk,
    input rst,
    input [1:0] br_cfg,
    output logic iocs,
    output logic iorw,
    input rda,
    input tbr,
    output logic [1:0] ioaddr,
    inout [7:0] databus
    );

	// State encodings
	typedef enum logic [1:0] { INIT_LOW_DB, INIT_HIGH_DB, RECEIVE_WAIT, RECEIVE} state_t;

    // Control signals
    logic sel,wrt;

    logic [2:0] state, nxt_state;
    logic [7:0] data_out, rx_data;

	assign databus = sel ? data_out : 8'bz;
	
	always_ff @(posedge clk, posedge rst) begin
		if(rst)
			rx_data <= 8'h00;
		else if (wrt)
			rx_data <= databus;
	end
	
	always_ff @(posedge clk, posedge rst) begin
		if(rst)
			state <= 2'b00;
		else
			state <= nxt_state;
	end

    always_comb begin
		ioaddr = 2'b00;
		sel = 0;
		iocs = 1;
		iorw = 1;
		nxt_state = INIT_LOW_DB;
		data_out = 8'h00;
		wrt = 0;
		
		case(state)
            // Lower byte
			INIT_LOW_DB: begin 
					ioaddr = 2'b10;
					sel = 1;
					nxt_state = INIT_HIGH_DB;
					case(br_cfg)	
						2'b00: 
								data_out = 8'h8a;		// 4800
						2'b01:
								data_out = 8'h45;		// 9600	
						2'b10: 
								data_out = 8'ha3;		// 19200	
						2'b11:
								data_out = 8'h51;		// 38400
					endcase	
			end
			// upper byte
			INIT_HIGH_DB: begin
					ioaddr = 2'b11;
					sel = 1;
					nxt_state = RECEIVE_WAIT;
					case(br_cfg)	
						2'b00: 
								data_out = 8'h02;		// 4800
						2'b01:
								data_out = 8'h01;		// 9600	
						2'b10: 
								data_out = 8'h00;		// 19200	
						2'b11:
								data_out = 8'h00;		// 38400
					endcase	
			end
			RECEIVE_WAIT: begin
					if(~rda) begin
						nxt_state = RECEIVE_WAIT;
						iocs = 0;
					end
					else begin
						nxt_state = RECEIVE;
						wrt = 1;
						ioaddr = 2'b00;
					end
			end
			RECEIVE: begin
				if(tbr) begin
					nxt_state = RECEIVE_WAIT;					
					ioaddr = 2'b00;
					iorw = 0;
					data_out = rx_data;
					sel = 1;
				end
				else begin
					nxt_state = RECEIVE;
				end
			end
		endcase
	end		
endmodule
