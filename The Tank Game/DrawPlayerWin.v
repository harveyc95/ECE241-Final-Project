module DrawPlayerWin 
	(
	iCLOCK_50, 
	iresetn,
	iPlayer1Win,
	iPlayer2Win,
	ocolor_out,
	ox,
	oy,
	owriteEn
	);
	
	input iCLOCK_50, iresetn;
	input iPlayer1Win, iPlayer2Win;
	output [2:0]ocolor_out;
	output reg [8:0]ox;
	output reg [7:0]oy;
	output reg owriteEn;
	
	reg [7:0]ix_pos = 110;
	reg [6:0]iy_pos = 40;
	reg [2:0]PicSelect;
	
	reg [7:0]x_counter, y_counter; //up to 126 for x and 149 for y
	reg draw;
	
	always@(*) begin
	if(iPlayer1Win)
		mem_color = Player1_Color;
	else if(iPlayer2Win)
		mem_color = Player2_Color;
	else
		mem_color = 3'b000;
	end
	
	assign ocolor_out = draw ? mem_color : 3'b111;
	
	
	// RAM initialization controllers
	reg [12:0]ramAddress; //0 to 7700
	reg [2:0]idata;
	reg ramWen;
	reg [2:0] mem_color;
	wire [2:0] Player1_Color;
	wire [2:0] Player2_Color;
	
	// INITIALIZIE RAM MODULES FOR COUNTDOWN IMAGES
	Player1Win player1_color(ramAddress, iCLOCK_50, idata, ramWen, Player1_Color);
	Player2Win player2_color(ramAddress, iCLOCK_50, idata, ramWen, Player2_Color);
	
	
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
					if (iPlayer1Win || iPlayer2Win)
						NState = ST_chooseColor;
					else
						NState = ST_idle;
				end
				ST_chooseColor:
						NState = ST_setMem;
				ST_setMem:
						NState = ST_draw;
				ST_draw: begin
					if (y_counter == 69 && x_counter == 109) // stop when y_counter reaches 16
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
			if (x_counter < 109) // increments x_counter until x_counter is > 15
				x_counter = x_counter + 1;
			else begin
				x_counter = 0; // resets x_counter
				y_counter = y_counter + 1; // increments y_counter
				end
			end
		if (CState == ST_draw)
			owriteEn = 1;
		if (CState == ST_Done)
		ox = ix_pos + x_counter;
		oy = iy_pos + y_counter;
	end
	// end counters
endmodule
