module ClearField 
	(
	iCLOCK_50, 
	iresetn,
	ienable,
	ocolor_out,
	ox,
	oy,
	owriteEn,
	oDoneSignal,
	);
	
	input iCLOCK_50, iresetn, ienable;
	output [2:0]ocolor_out;
	output reg [8:0]ox;
	output reg [7:0]oy;
	output reg owriteEn;
	output reg oDoneSignal;
	
	assign ocolor_out = 3'b111;
	
	reg [8:0]ix_pos = 30;
	reg [7:0]iy_pos = 30;
	
	
	reg [8:0]x_counter;
	reg [7:0]y_counter; //up to 259 for x and 179 for y
	
	//STATES and State FFs
	parameter [3:0] ST_idle = 0, ST_setMem = 1, ST_draw = 2, ST_count = 3, ST_Done = 4;
	reg [3:0] CState, NState;
	always@(posedge iCLOCK_50) begin
		if (!iresetn)
			CState = ST_idle;
		else
			CState = NState;
	end
	//end fsm setup
	
	//CHANGING STATE
	always@(*) begin
		NState = ST_idle; //blocking or nonblock?
		case(CState)
				ST_idle: begin
					if (ienable)
						NState = ST_setMem;
					else
						NState = ST_idle;
				end
				ST_setMem:
						NState = ST_draw;
				ST_draw: begin
					if (y_counter == 179 && x_counter == 259) // stop when y_counter reaches 16
						NState = ST_Done;
					else
						NState = ST_count;
				end
				ST_count:
						NState = ST_draw;
				ST_Done:
						NState = ST_idle;
				default:
						NState = ST_idle; 
		endcase
	end
	// end state rules
	
	//VARIOUS COUNTERS
	always@(posedge iCLOCK_50) begin
		if (CState == ST_idle) begin
			owriteEn = 0;
			oDoneSignal = 0;
		end
		if (CState == ST_setMem) begin
			x_counter = 0;
			y_counter = 0;
			end
		if (CState == ST_count) begin
			owriteEn = 0;
			if (x_counter < 259) // increments x_counter until x_counter is > 15
				x_counter = x_counter + 1;
			else begin
				x_counter = 0; // resets x_counter
				y_counter = y_counter + 1; // increments y_counter
				end
			end
		if (CState == ST_draw)
			owriteEn = 1;
		if (CState == ST_Done)
			oDoneSignal = 1;
		ox = ix_pos + x_counter;
		oy = iy_pos + y_counter;
	end
	// end counters
endmodule
