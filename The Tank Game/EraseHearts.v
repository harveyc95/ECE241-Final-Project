module EraseHearts 
	(
	iCLOCK_50, 
	iresetn,
	iEraseP1Heart,
	iEraseP2Heart,
	iP1Life,
	iP2Life,
	ocolor_out,
	ox,
	oy,
	owriteEn,
	oDoneSignal,
	);
	
	input iCLOCK_50, iresetn, iEraseP1Heart, iEraseP2Heart;
	input [1:0]iP1Life, iP2Life;
	output [2:0]ocolor_out;
	output reg [8:0]ox;
	output reg [7:0]oy;
	output reg owriteEn;
	output reg oDoneSignal;
	
	assign ocolor_out = 3'b111;
	
	reg [8:0]ix_pos;
	reg [7:0]iy_pos;
	
	always@(*) begin
		if(iEraseP1Heart) begin
			if(iP1Life == 2'b10) begin
				ix_pos = 5;
				iy_pos = 122;
			end
			else if(iP1Life == 2'b01) begin
				ix_pos = 5;
				iy_pos = 104;
			end
			else if(iP1Life == 2'b00) begin
				ix_pos = 5;
				iy_pos = 86;
			end
		end
		else if(iEraseP2Heart) begin
			if(iP2Life == 2'b10) begin
				ix_pos = 298;
				iy_pos = 122;
			end
			else if(iP2Life == 2'b01) begin
				ix_pos = 298;
				iy_pos = 104;
			end
			else if(iP2Life == 2'b00) begin
				ix_pos = 298;
				iy_pos = 86;
			end
		end
	end
	
	reg [4:0]x_counter, y_counter; //up to 15 for x and 15 for y
	
	//STATES and State FFs
	parameter [3:0] ST_idle = 0, ST_chooseColor = 4, ST_setMem = 1, ST_draw = 2, ST_count = 3, ST_Done = 5;
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
					if (iEraseP1Heart || iEraseP2Heart)
						NState = ST_setMem;
					else
						NState = ST_idle;
				end
				ST_setMem:
						NState = ST_draw;
				ST_draw: begin
					if (y_counter == 15 && x_counter == 15) // stop when y_counter reaches 16
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
			if (x_counter < 15) // increments x_counter until x_counter is > 15
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
