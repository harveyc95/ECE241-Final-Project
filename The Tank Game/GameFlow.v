module GameFlow(
						CLOCK_50,					//	On Board 50 MHz
						KEY,							//	Push Button[3:0]
						SW,                     // Switches [17:0]
						VGA_CLK,  					//	VGA Clock
						VGA_HS,						//	VGA H_SYNC
						VGA_VS,						//	VGA V_SYNC
						VGA_BLANK,					//	VGA BLANK
						VGA_SYNC,					//	VGA SYNC
						VGA_R,   					//	VGA Red[9:0]
						VGA_G,	 					//	VGA Green[9:0]
						VGA_B,   					//	VGA Blue[9:0]
						LEDG,
						LEDR,
						GPIO_0,
						GPIO_1
						);
// inputs
input CLOCK_50;
input	[3:0]	KEY;	 			//	Button[3:0]
input [17:0] SW;           // Switches [17:0]
input [9:0]GPIO_0;			// USER CONTROL CONNECTIONS USING GPIO (For Player1)
input [9:0]GPIO_1;			// USER CONTROL CONNECTIONS USING GPIO (For Player2)

// testing purposes
output [7:0] LEDG;
output [17:0] LEDR;

// outputs
output VGA_CLK;   			//	VGA Clock
output VGA_HS;					//	VGA H_SYNC
output VGA_VS;					//	VGA V_SYNC
output VGA_BLANK;				//	VGA BLANK
output VGA_SYNC;				//	VGA SYNC
output [9:0] VGA_R;			//	VGA Red[9:0]
output [9:0] VGA_G;			//	VGA Green[9:0]
output [9:0] VGA_B;			//	VGA Blue[9:0]

// internal wires
wire resetn;								 // wire to reset the VGA adapter
wire [2:0]color_plot;					 // colors fed into the VGA for plotting
wire [8:0]x_plot;							 // x position fed into the VGA for plotting
wire [7:0]y_plot; 						 // y position fed into the VGA for plotting
wire enable_plot;

wire [8:0]x_animation;
wire [7:0]y_animation;
wire [2:0]color_animation;
wire enable_animation;
wire [8:0]x_countdown;
wire [7:0]y_countdown;
wire [2:0]color_countdown;
wire enable_countdown;
wire DoneCountDown;
wire [8:0]x_DrawTotalRounds;
wire [7:0]y_DrawTotalRounds;
wire [2:0]color_DrawTotalRounds;
wire enable_DrawTotalRounds;
wire DoneDrawTotalRounds;
wire [8:0]x_DrawPlayerWin;
wire [7:0]y_DrawPlayerWin;
wire [2:0]color_DrawPlayerWin;
reg DrawEnable_DrawPlayerWin;
reg EraseEnable_DrawPlayerWin;
wire enable_DrawPlayerWin;
wire DoneDrawPlayerWin;
reg Player1Win, Player2Win;
wire [8:0]x_P1Reset;
wire [7:0]y_P1Reset;
wire [2:0]color_P1Reset;
wire enable_P1Reset;
wire DoneP1_Reset;
wire [8:0]x_P2Reset;
wire [7:0]y_P2Reset;
wire [2:0]color_P2Reset;
wire enable_P2Reset;
wire DoneP2_Reset;
wire [8:0]x_DrawCurrentRound;
wire [7:0]y_DrawCurrentRound;
wire [2:0]color_DrawCurrentRound;
wire enable_DrawCurrentRound;
wire DoneDrawCurrentRound;



// internal wire assignments
assign resetn = ~SW[0];					 // ties SW[0] to the reset signal

// internal registers
reg StartCountDown; // signals for CountDown FSM
reg [3:0]TotalNumofRounds; // stores the total number of rounds from SW inputs
reg [3:0]CurrentNumofRound;

reg StartDrawTotalRounds;
reg StartP1Reset;
reg StartP2Reset;
reg StartDrawCurrentRound;

reg animation;
reg resetLife;

ResetP1Hearts P1Reset (CLOCK_50, resetn, StartP1Reset, color_P1Reset, x_P1Reset, y_P1Reset, enable_P1Reset, DoneP1_Reset);
ResetP2Hearts P2Reset (CLOCK_50, resetn, StartP2Reset, color_P2Reset, x_P2Reset, y_P2Reset, enable_P2Reset, DoneP2_Reset);
DrawCurrentRound CurrentRound(CLOCK_50, resetn, StartDrawTotalRounds, TotalNumofRounds, 
									color_DrawTotalRounds, x_DrawTotalRounds, y_DrawTotalRounds, enable_DrawTotalRounds, DoneDrawTotalRounds);

// STATE Parameters
parameter [3:0] ST_Idle = 0, ST_Read_Inputs = 1, ST_DrawTotalRounds = 2, // initial states, only goes to the state once until FSM is reset to ST_Idle
					ST_PrepInitialScreen = 3, // draws the current round number and redraws 3 hearts for each player
					ST_Countdown = 4, // starts the countdown FSM
					ST_Start_Game = 5, // goes into the animation FSM until player died siganl is received
					ST_Player1Win = 6, ST_Player2Win = 7; // draws player1 win or player2 win

reg [3:0] CState, NState;
always@(posedge CLOCK_50) begin
	if(!resetn)
		CState <= ST_Idle;
	else
		CState <= NState;
end

always@(*) begin
	NState <= ST_Idle;
	case(CState)
		ST_Idle: begin
			if(SW[6]) // SWITCH 6 STARTS THE GAME
				NState <= ST_Start_Game;
			else
				NState <= ST_Idle;
		end
		
		ST_Read_Inputs: begin
				NState <= ST_DrawTotalRounds;
		end
		
		ST_DrawTotalRounds: begin
		
		end
		
		ST_PrepInitialScreen: begin
		
		end
		
		ST_Countdown: begin
		
		end
		
		ST_Start_Game: begin
			if(P1Life)
				NState <= ST_Player2Win;
			else if(P2Life)
				NState <= ST_Player1Win;
			else
				NState <= ST_Start_Game;
		end
		
		ST_Player1Win: begin
			if(DoneDrawPlayerWin)
				NState <= ST_Idle;
			else
				NState <= ST_Player1Win;
		end
		
		ST_Player2Win: begin
			if(DoneDrawPlayerWin)
				NState <= ST_Idle;
			else
				NState <= ST_Player2Win;
			
		end
		
		
	default:
		NState <= ST_Idle;
	endcase
end
/*
DrawPlayerWin PlayerWin (CLOCK_50, resetn, 
								DrawEnable_DrawPlayerWin, EraseEnable_DrawPlayerWin,
								Player1Win, Player2Win, color_DrawPlayerWin, x_DrawPlayerWin, y_DrawPlayerWin, enable_DrawPlayerWin, DoneDrawPlayerWin);
*/
always@(posedge CLOCK_50) begin
	if(CState == ST_Idle) begin
			resetLife = 1;
	end
	if(CState == ST_Read_Inputs) begin
		TotalNumofRounds <= SW[3:0];
	end
	if(CState == ST_DrawTotalRounds) begin
	
	end
	if(CState == ST_PrepInitialScreen) begin
	
	end
	if(CState == ST_Countdown) begin
	
	end
	if(CState == ST_Start_Game) begin
		animation = 1;
		resetLife = 0;
	end
	if(CState == ST_Player1Win) begin
		animation = 0;
		DrawEnable_DrawPlayerWin = 1;
		EraseEnable_DrawPlayerWin = 1;
		Player1Win = 1;
	
	end
	if(CState == ST_Player2Win) begin
		animation = 0;
		DrawEnable_DrawPlayerWin = 1;
		EraseEnable_DrawPlayerWin = 1;
		Player2Win = 1;
	end
end


DrawTotalRounds drawtotalrounds(CLOCK_50, resetn, StartDrawTotalRounds, TotalNumofRounds, 
									color_DrawTotalRounds, x_DrawTotalRounds, y_DrawTotalRounds, enable_DrawTotalRounds, DoneDrawTotalRounds);
CountDown countdown(CLOCK_50, resetn, StartCountDown, DoneCountDown, x_countdown, y_countdown, color_countdown, enable_countdown);

//assign x_plot = animation ? x_animation : x_DrawPlayerWin;
//assign y_plot = animation ? y_animation : y_DrawPlayerWin;
//assign enable_plot = animation ? enable_animation : enable_DrawPlayerWin;
//assign color_plot = animation ? color_animation : color_DrawPlayerWin;



vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(color_animation),
			.x(x_animation),
			.y(y_animation),
			.plot(enable_animation),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK),
			.VGA_SYNC(VGA_SYNC),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "background_new.mif";

wire P1Life, P2Life;
		
animation	gamegraphics(
									CLOCK_50,						//	On Board 50 MHz
									KEY,								//	Push Button[3:0]
									SW,                        // Switches [17:0]
									resetLife,
									resetn,
									LEDG,
									LEDR,
									GPIO_0,
									GPIO_1,
									x_animation,
									y_animation,
									color_animation,
									enable_animation,
									P1Life,
									P2Life
								);		

endmodule






module CountDown (iCLOCK_50, iresetn, iStartCountDown, oDoneCountDown, x_out, y_out, color_out, plot_out);
// inputs
input iCLOCK_50, iresetn;
input iStartCountDown;

// outputs
output reg oDoneCountDown;
output reg [8:0]x_out;
output reg [7:0]y_out;
output reg [2:0]color_out;
output reg plot_out;

// internal wires
wire [8:0]x;
wire [7:0]y;
wire [2:0]color;
wire plot;
wire DoneDraworErase;

// internal registers
reg OneSecCounter1, OneSecCounter2, OneSecCounter3;
reg [25:0]Counter; // Counts up to 50,000,000 for 1 second delay
reg [1:0]PicSelect;
reg rDraw, rErase;

draw_and_erase_countdown drawanderase(iCLOCK_50, iresetn, rErase, rDraw, PicSelect, color, x, y, plot, DoneDraworErase);

// STATE Parameters
parameter [2:0]
					ST_Idle = 0, ST_Draw1 = 1, ST_Draw2 = 2, ST_Draw3 = 3, ST_Erase3 = 4, ST_SendDone = 5;

reg [2:0] CState, NState;
always@(posedge iCLOCK_50) begin
	if(!iresetn)
		CState <= ST_Idle;
	else
		CState <= NState;
end

always@(*)begin
	NState <= ST_Idle;
	case(CState)
		ST_Idle: begin
			if(iStartCountDown)
				NState <= ST_Draw1;
			else
				NState <= ST_Idle;
		end
		ST_Draw1: begin
			if(OneSecCounter1)
				NState <= ST_Draw2;
			else
				NState <= ST_Draw1;
		end
		ST_Draw2: begin
			if(OneSecCounter2)
				NState <= ST_Draw3;
			else
				NState <= ST_Draw2;
		end
		ST_Draw3: begin
			if(OneSecCounter3)
				NState <= ST_Erase3;
			else
				NState <= ST_Draw3;
		end
		ST_Erase3: begin
			if(DoneDraworErase)
				NState <= ST_SendDone;
			else
				NState <= ST_Erase3;
		end
		ST_SendDone: begin
			NState <= ST_Idle;
		end
		default:
			NState <= ST_Idle;
	endcase
end

always@(posedge iCLOCK_50) begin
	if(CState == ST_Idle) begin
		OneSecCounter1 = 0;
		OneSecCounter2 = 0;
		OneSecCounter3 = 0;
		Counter = 0;
		oDoneCountDown = 0;
	end
	if(CState == ST_Draw1) begin
		rDraw = 1;
		PicSelect = 2'b00;
		Counter = Counter + 1;
		OneSecCounter1 = (Counter == 50000000);
	end
	if(CState == ST_Draw2) begin
		PicSelect = 2'b01;
		Counter = Counter + 1;
		OneSecCounter2 = (Counter == 50000000);
	end
	if(CState == ST_Draw3) begin
		PicSelect = 2'b10;
		Counter = Counter + 1;
		OneSecCounter3 = (Counter == 50000000);
	end
	if(CState == ST_Erase3) begin
		rDraw = 0;
		rErase = 1;
	end
	if(CState == ST_SendDone) begin
		rErase = 0;
		oDoneCountDown = 1;
	end
end

endmodule


module draw_and_erase_countdown 
	(
	iCLOCK_50, 
	iresetn,
	ieraseEn,
	idrawEn,
	iPicSelect,
	ocolor_out,
	ox,
	oy,
	owriteEn,
	oDoneSignal,
	);
	
	input iCLOCK_50, iresetn, ieraseEn, idrawEn;
	input [1:0]iPicSelect;
	output [2:0]ocolor_out;
	output reg [8:0]ox;
	output reg [7:0]oy;
	output reg owriteEn;
	output reg oDoneSignal;
	
	reg [7:0]ix_pos = 110;
	reg [6:0]iy_pos = 40;
	reg [2:0]PicSelect;
	
	reg [7:0]x_counter, y_counter; //up to 126 for x and 149 for y
	reg draw;
	
	always@(*) begin
	if(PicSelect == 2'b00)
		mem_color = Num1_Color;
	else if(PicSelect == 2'b01)
		mem_color = Num2_Color;
	else if(PicSelect == 2'b10)
		mem_color = Num3_Color;
	else
		mem_color = 3'b100;
	end
	
	assign ocolor_out = draw ? mem_color : 3'b111;
	
	// RAM initialization controllers
	reg [14:0]ramAddress; //0 to 19050
	reg [2:0]idata;
	reg ramWen;
	reg [2:0] mem_color;
	wire [2:0] Num1_Color;
	wire [2:0] Num2_Color;
	wire [2:0] Num3_Color;
	
	// INITIALIZIE RAM MODULES FOR COUNTDOWN IMAGES
	CountDown_1 num1(ramAddress, iCLOCK_50, idata, ramWen, Num1_Color);
	CountDown_2 num2(ramAddress, iCLOCK_50, idata, ramWen, Num2_Color);
	CountDown_3 num3(ramAddress, iCLOCK_50, idata, ramWen, Num3_Color);
	
	
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
					else if (ieraseEn)
						NState = ST_chooseColor;
					else
						NState = ST_idle;
				end
				ST_chooseColor:
						NState = ST_setMem;
				ST_setMem:
						NState = ST_draw;
				ST_draw: begin
					if (y_counter == 149 && x_counter == 126) // stop when y_counter reaches 16
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
			if(idrawEn)
				draw = 1;
			else if(ieraseEn)
				draw = 0;
			end
		if (CState == ST_count) begin
			owriteEn = 0;
			ramAddress = ramAddress + 1;
			if (x_counter < 126) // increments x_counter until x_counter is > 15
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
