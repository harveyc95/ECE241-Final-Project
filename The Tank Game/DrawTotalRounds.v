module DrawTotalRounds 
	(
	iCLOCK_50, 
	iresetn,
	idrawEn,
	NumSelect,
	ocolor_out,
	ox,
	oy,
	owriteEn,
	oDoneSignal,
	);
	
	input iCLOCK_50, iresetn, idrawEn;
	input [2:0]NumSelect;
	output [2:0]ocolor_out;
	output reg [8:0]ox;
	output reg [7:0]oy;
	output reg owriteEn;
	output reg oDoneSignal;
	
	reg [7:0]ix_pos = 194;
	reg [6:0]iy_pos = 218;
	
	reg [3:0]x_counter, y_counter; //up to 10 for x and 15 for y
	reg draw;
	
	always@(*) begin
	if(NumSelect == 3'b001) // 1 round
		mem_color = Num1_Color;
	else if(NumSelect == 3'b010) // 3 rounds
		mem_color = Num3_Color;
	else if(NumSelect == 3'b101) // 5 rounds
		mem_color = Num5_Color;
	else if(NumSelect == 3'b111) // 7 rounds
		mem_color = Num7_Color;
	else
		mem_color = 3'b100;
	end
	
	assign ocolor_out = mem_color;
	
	// RAM initialization controllers
	reg [7:0]ramAddress; //0 to 150
	reg [2:0]idata;
	reg ramWen;
	reg [2:0] mem_color;
	wire [2:0] Num1_Color;
	wire [2:0] Num3_Color;
	wire [2:0] Num5_Color;
	wire [2:0] Num7_Color;
	
	// INITIALIZIE RAM MODULES FOR COUNTDOWN IMAGES
	TotalRoundNum1 num1(ramAddress, iCLOCK_50, idata, ramWen, Num1_Color);
	TotalRoundNum3 num3(ramAddress, iCLOCK_50, idata, ramWen, Num3_Color);
	TotalRoundNum5 num5(ramAddress, iCLOCK_50, idata, ramWen, Num5_Color);
	TotalRoundNum7 num7(ramAddress, iCLOCK_50, idata, ramWen, Num7_Color);

	
	
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
					if (idrawEn)
						NState = ST_chooseColor;
					else
						NState = ST_idle;
				end
				ST_chooseColor:
						NState = ST_setMem;
				ST_setMem:
						NState = ST_draw;
				ST_draw: begin
					if (y_counter == 14 && x_counter == 9) // stop when y_counter reaches 16
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
			ramAddress = 0;
		end
		if (CState == ST_setMem) begin
			ramAddress = 0;
			x_counter = 0;
			y_counter = 0;
			end
		if (CState == ST_chooseColor)begin
				draw = 1;
			end
		if (CState == ST_count) begin
			owriteEn = 0;
			ramAddress = ramAddress + 1;
			if (x_counter < 9) // increments x_counter until x_counter is > 15
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
