module baud_rate_generator(
	input clk,
	input rst,
	output logic en,
	input [7:0] data,
	input sel_low,
	input sel_high
	);

logic [15:0] divisor_buffer;
logic state, nxt_state;
logic load_counter, en_counter;
logic [11:0] counter;


typedef enum logic [0:0] {SEND_SIGNAL, WAIT} state_t;

always_ff @(posedge clk, posedge rst)
	if(rst)
		divisor_buffer <= 16'h0000;
	else if(sel_low)
		divisor_buffer <= {divisor_buffer[15:8], data};
	else if(sel_high)
		divisor_buffer <= {data, divisor_buffer[7:0]};

always_ff @(posedge clk, posedge rst)
	if(rst)
		state <= SEND_SIGNAL;
	else
		state <= nxt_state;

always_ff @(posedge clk, posedge rst)
	if(rst)
		counter <= 12'h000;
	else if(load_counter)
		counter <= divisor_buffer[11:0];
	else if(en_counter)
		counter <= counter - 12'h001;


always_comb begin
	en = 0;
	load_counter = 0;
	en_counter = 0;
	nxt_state = SEND_SIGNAL;
	case(state)
		SEND_SIGNAL : begin
			en = 1;
			load_counter = 1;
			nxt_state = WAIT;
		end
		WAIT : begin
			if(~(|counter))
				nxt_state = SEND_SIGNAL;
			else begin
				en_counter = 1;
				nxt_state = WAIT;
			end
		end
	endcase
end
endmodule
