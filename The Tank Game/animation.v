module animation
	(
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
	
// inputs	
input	CLOCK_50;				//	50 MHz
input resetn;
input	[3:0]	KEY;	 			//	Button[3:0]
input [17:0] SW;           // Switches [17:0]
input [9:0]GPIO_0;			// USER CONTROL CONNECTIONS USING GPIO (For Player1)
input [9:0]GPIO_1;			// USER CONTROL CONNECTIONS USING GPIO (For Player2)
	
// testing purposes
output [7:0] LEDG;
output [17:0] LEDR;

// outputs
output [8:0]x_animation;
output [7:0]y_animation;
output [2:0]color_animation;
output enable_animation;

output P1Life;
output P2Life;

assign P1Life = (P1HitCount == 2'b00);
assign P2Life = (P2HitCount == 2'b00);


// wires to outputs assignemnts
assign x_animation = x_plot;
assign y_animation = y_plot;
assign color_animation = color_plot;
assign enable_animation = enable_plot;
	
// internal wires
wire Up, Down, Left, Right, Shoot1; 			// control wires for player 1
wire Up2, Down2, Left2, Right2, Shoot2;		// control wires for player 2
wire Tank_plot, Bullet_plot, enable_plot;		// wires for different plot signals
wire [2:0]color_plot;								// color fed into submodules
wire [8:0]x_plot;										// x position fed into submodules
wire [7:0]y_plot; 						 			// y position fed into submodules

// internal wires assignemnts EXTERNAL CONTROLLERS' CONNECTIONS

assign Up = ~GPIO_0[0];	
assign Down = ~GPIO_0[2];
assign Left = ~GPIO_0[4];
assign Right = ~GPIO_0[6];
assign Shoot1 = ~GPIO_0[8];
assign Up2 = ~GPIO_0[1];
assign Down2 = ~GPIO_0[3];
assign Left2 = ~GPIO_0[5];
assign Right2 = ~GPIO_0[7];
assign Shoot2 = ~GPIO_0[9];

/*
assign Up = ~KEY[3];	
assign Down = ~KEY[2];
assign Left = ~KEY[1];
assign Right = ~KEY[0];
assign Shoot1 = SW[1];
assign Up2 = SW[17];
assign Down2 = SW[16];
assign Left2 = SW[15];
assign Right2 = SW[14];
assign Shoot2 = SW[13];
*/

wire [8:0]x_input; 						 // initial x position for player 1
wire [7:0]y_input; 						 // initial x position for player 2
assign x_input = 30; 					 // assigns switches to x position
assign y_input = 30; 					 // assigns switches to y position

reg rErase; 								 // to enable Erase in Draw_and_Erase FSM
reg rDraw; 									 // to enable Draw in Draw_and_Erase FSM
reg [8:0]x_count = 1; 					 // keeps track of x counter player 1
reg [7:0]y_count = 1; 					 // keeps track of y counter player 1
reg [8:0]x_count2 = 268; 				 // keeps track of x counter player 1
reg [7:0]y_count2 = 188; 				 // keeps track of y counter player 2
reg [8:0]tank1_pos_x;					 // tank 1 x position for collision detection
reg [7:0]tank1_pos_y;					 // tank 1 y position for collision detection
reg [8:0]tank2_pos_x; 					 // tank 2 x position for collision detection
reg [7:0]tank2_pos_y; 					 // tank 2 y position for collision detection
reg [8:0]tank1_x_abs;
reg [7:0]tank1_y_abs;
reg [8:0]tank2_x_abs;
reg [7:0]tank2_y_abs;
reg [8:0]x_translated; 					 // x position for the Draw_and_Erase FSM
reg [7:0]y_translated; 					 // y position for the Draw_and_Erase FSM
reg [26:0] delayCount; 					 // delay counter for player 1
reg [19:0] delayCount2; 			    // delay counter for state between the 2 Draw States
reg DoneDelay; 							 // allows Draw_and_Erase FSM to send a Done signal for player1 DRAW/ERASE
reg DoneDelay2; 							 // allows Draw_and_Erase FSM to send a Done signal for player2 DRAW/ERASE
wire DoneDrawOrErase; 					 // the output signal of the FSM

wire Tank1Hit, Tank2Hit;
assign Tank1Hit = (P1B1_coll || P1B2_coll || P1B3_coll || P1B4_coll);
assign Tank2Hit = (P2B1_coll || P2B2_coll || P2B3_coll || P2B4_coll);

// BEGIN OF STATE DECLARATIONS
	parameter [4:0] ST_Idle = 0, ST_ButtonBuffer = 20, ST_EraseCurrent = 1, ST_TurnOffErase = 2, ST_EraseCurrent2 = 3,
						 ST_Up = 4, ST_Down = 5, ST_Left = 6, ST_Right = 7, 
				    	 ST_Draw_Translated = 8, ST_TurnOffDraw = 9, ST_Draw_Translated2 = 10, 
						 ST_Delay = 11,
						 ST_Player1Bullet1 = 12, ST_Player1Bullet2 = 13, ST_Player1Bullet3 = 14, ST_Player1Bullet4 = 15,
						 ST_Player2Bullet1 = 16, ST_Player2Bullet2 = 17, ST_Player2Bullet3 = 18, ST_Player2Bullet4 = 19, 
						 ST_EraseP1Heart = 21, ST_EraseP2Heart = 22, ST_ResetPositons = 23, ST_ClearField = 24, ST_TurnOffClear = 25, ST_DrawWinner = 26;
// END OF STATE DECLARATIONS
		
// BEGIN OF STATE FLIPFLOPS
reg [4:0]CState, NState;
always@(posedge CLOCK_50) begin
	if (!resetn)
		CState <= ST_Idle;
	else if(P1B1_coll || P1B2_coll || P1B3_coll || P1B4_coll)
		CState <= ST_EraseP2Heart;
	else if(P2B1_coll || P2B2_coll || P2B3_coll || P2B4_coll)
		CState <= ST_EraseP1Heart;
	//else if(P1HitCount == 0 || P2HitCount == 0)
		//CState <= ST_DrawWinner;
	else
		CState <= NState;
end
// END OF STATE FLIPFLOPS
		
assign LEDG[4:0] = CState;
assign LEDR[7] = StartClearField;
		
		// BEGIN OF STATE TABLE
		always@(*) begin
			case(CState)
					ST_EraseP1Heart: begin
						if(DoneEraseHeart)
							NState <= ST_ResetPositons;
						else
							NState <= ST_EraseP1Heart;
					end
					ST_EraseP2Heart: begin
						if(DoneEraseHeart)
							NState <= ST_ResetPositons;
						else
							NState <= ST_EraseP2Heart;
					end
					ST_ResetPositons: begin
							NState <= ST_ClearField;
					end
					ST_ClearField: begin
							NState <= ST_TurnOffClear;
					end
					ST_TurnOffClear: begin
						if(DoneClearDelay)
							NState <= ST_Idle;
						else
							NState <= ST_TurnOffClear;
					end
					
					
					ST_Idle: begin
						if(Up || Down || Left || Right || 
							Up2 || Down2 || Left2 || Right2 || 
							Shoot1 || Shoot2 || 
							P1B1_Active || P1B2_Active || P1B3_Active || P1B4_Active || 
							P2B1_Active || P2B2_Active || P2B3_Active || P2B4_Active)
							NState <= ST_ButtonBuffer;
						else
							NState <= ST_Idle;
					end
					ST_ButtonBuffer: begin
						if(DoneButtonBuffer)
							NState <= ST_EraseCurrent;
						else
							NState <= ST_ButtonBuffer;
					end
					ST_EraseCurrent: begin
						if(DoneDrawOrErase)
							NState <= ST_TurnOffErase;
						else
							NState <= ST_EraseCurrent;
					end
					ST_TurnOffErase: begin // a state to turn off the rErase signal
							NState <= ST_EraseCurrent2; 
					end
					ST_EraseCurrent2: begin
						if(DoneDrawOrErase)
							NState <= ST_Up;
						else
							NState <= ST_EraseCurrent2;
					end
					ST_Up:
							NState <= ST_Down;
					ST_Down:
							NState <= ST_Left;
					ST_Left:
							NState <= ST_Right;
					ST_Right:
							NState <= ST_Draw_Translated;
					ST_Draw_Translated: begin
						if(DoneDrawOrErase)
							NState <= ST_TurnOffDraw;
						else
							NState <= ST_Draw_Translated;
					end
					ST_TurnOffDraw: begin
						if(DoneDelay2)
							NState <= ST_Draw_Translated2;
						else 
							NState <= ST_TurnOffDraw;
					end
					ST_Draw_Translated2: begin
						if(DoneDrawOrErase)
							NState <= ST_Delay;
						else
							NState <= ST_Draw_Translated2;
					end
					ST_Delay: begin
						if(DoneDelay)
							NState <= ST_Player1Bullet1;
						else
							NState <= ST_Delay;
					end
					ST_Player1Bullet1: begin
						if(Shoot1 && !P1B1_Active) begin
							if((!P1B2_Active || BulletBufferP1B2 > 45) && (!P1B3_Active || BulletBufferP1B3 > 45) && (!P1B4_Active || BulletBufferP1B4 > 45)) begin
								if(P1B1_DoneDraw)
									NState <= ST_Player1Bullet2;
								else
									NState <= ST_Player1Bullet1;
							end
								else
									NState <= ST_Player1Bullet2;
						end
							else if(P1B1_Active) begin
								if(P1B1_DoneDraw)
									NState <= ST_Player1Bullet2;
								else 
									NState <= ST_Player1Bullet1;
							end
							else
									NState <= ST_Player1Bullet2;
					end
					ST_Player1Bullet2: begin
						if(Shoot1 && P1B1_Active && !P1B2_Active) begin
							if((!P1B1_Active || BulletBufferP1B1 > 45) && (!P1B3_Active || BulletBufferP1B3 > 45) && (!P1B4_Active || BulletBufferP1B4 > 45)) begin
								if(P1B2_DoneDraw)
									NState <= ST_Player1Bullet3;
								else
									NState <= ST_Player1Bullet2;
							end
								else
									NState <= ST_Player1Bullet3;
						end
							else if(P1B2_Active) begin
								if(P1B2_DoneDraw)
									NState <= ST_Player1Bullet3;
								else 
									NState <= ST_Player1Bullet2;
							end
							else
									NState <= ST_Player1Bullet3;	
					end
					ST_Player1Bullet3: begin
						if((Shoot1 && P1B1_Active && P1B2_Active && !P1B3_Active)) begin
							if((!P1B1_Active || BulletBufferP1B1 > 45) && (!P1B2_Active || BulletBufferP1B2 > 45) && (!P1B4_Active || BulletBufferP1B4 > 45)) begin
								if(P1B3_DoneDraw)
									NState <= ST_Player1Bullet4;
								else
									NState <= ST_Player1Bullet3;
							end
								else
									NState <= ST_Player1Bullet4;
						end
							else if(P1B3_Active) begin
								if(P1B3_DoneDraw)
									NState <= ST_Player1Bullet4;
								else 
									NState <= ST_Player1Bullet3;
							end
								else
									NState <= ST_Player1Bullet4;
					end
					ST_Player1Bullet4: begin
						if((Shoot1 && P1B1_Active && P1B2_Active && P1B3_Active && !P1B4_Active)) begin
							if((!P1B1_Active || BulletBufferP1B1 > 45) && (!P1B2_Active || BulletBufferP1B2 > 45) && (!P1B3_Active || BulletBufferP1B3 > 45)) begin
								if(P1B4_DoneDraw)
									NState <= ST_Player2Bullet1;
								else
									NState <= ST_Player1Bullet4;
							end
								else
									NState <= ST_Player2Bullet1;
						end
							else if(P1B4_Active) begin
								if(P1B4_DoneDraw)
									NState <= ST_Player2Bullet1;
								else 
									NState <= ST_Player1Bullet4;
							end
							else
									NState <= ST_Player2Bullet1;
					end
					ST_Player2Bullet1: begin
						if(Shoot2 && !P2B1_Active) begin
							if((!P2B2_Active || BulletBufferP2B2 > 45) && (!P2B3_Active || BulletBufferP2B3 > 45) && (!P2B4_Active || BulletBufferP2B4 > 45)) begin
								if(P2B1_DoneDraw)
									NState <= ST_Player2Bullet2;
								else
									NState <= ST_Player2Bullet1;
							end
								else
									NState <= ST_Player2Bullet2;
						end
							else if(P2B1_Active) begin
								if(P2B1_DoneDraw)
									NState <= ST_Player2Bullet2;
								else 
									NState <= ST_Player2Bullet1;
							end
							else
									NState <= ST_Player2Bullet2;
					end
					ST_Player2Bullet2: begin
						if(Shoot2 && P2B1_Active && !P2B2_Active) begin
							if((!P2B1_Active || BulletBufferP2B1 > 45) && (!P2B3_Active || BulletBufferP2B3 > 45) && (!P2B4_Active || BulletBufferP2B4 > 45)) begin
								if(P2B2_DoneDraw)
									NState <= ST_Player2Bullet3;
								else
									NState <= ST_Player2Bullet2;
							end
								else
									NState <= ST_Player2Bullet3;
							end
							else if(P2B2_Active) begin
								if(P2B2_DoneDraw)
									NState <= ST_Player2Bullet3;
								else 
									NState <= ST_Player2Bullet2;
							end
							else
									NState <= ST_Player2Bullet3;	
					end
					ST_Player2Bullet3: begin
						if((Shoot2 && P2B1_Active && P2B2_Active && !P2B3_Active)) begin
							if((!P2B1_Active || BulletBufferP2B1 > 45) && (!P2B2_Active || BulletBufferP2B2 > 45) && (!P2B4_Active || BulletBufferP2B4 > 45)) begin
								if(P2B3_DoneDraw)
									NState <= ST_Player2Bullet4;
								else
									NState <= ST_Player2Bullet3;
							end
								else
									NState <= ST_Player2Bullet4;
						end
							else if(P2B3_Active) begin
								if(P2B3_DoneDraw)
									NState <= ST_Player2Bullet4;
								else 
									NState <= ST_Player2Bullet3;
							end
							else
									NState <= ST_Player2Bullet4;
					end
					ST_Player2Bullet4: begin
						if((Shoot2 && P2B1_Active && P2B2_Active && P2B3_Active && !P2B4_Active)) begin
							if((!P2B1_Active || BulletBufferP2B1 > 45) && (!P2B2_Active || BulletBufferP2B2 > 45) && (!P2B3_Active || BulletBufferP2B3 > 45)) begin
								if(P2B4_DoneDraw)
									NState <= ST_Idle;
								else
									NState <= ST_Player2Bullet4;
							end
								else
									NState <= ST_Idle;
						end
							else if(P2B4_Active) begin
								if(P2B4_DoneDraw)
									NState <= ST_Idle;
								else 
									NState <= ST_Player2Bullet4;
							end
							else
									NState <= ST_Idle;
					end
					
					default:
								NState <= ST_Idle;
			endcase
		end 
		// END OF STATE TABLE
		
		// BEGIN OF STATE LOGIC
		always@(posedge CLOCK_50)begin
			if(CState == ST_Idle)begin
					DoneDelay = 0;
					delayCount = 0;
					delayCount2 = 0;
					rErase = 0;
					rDraw = 0;
					Tank1Enable = 0;
					Tank2Enable = 0;
					tank1_pos_x <= x_input + x_count; // temporarily stores tank 1 x position for comparison
					tank1_pos_y <= y_input + y_count; // temporarily stores tank 1 y position for comparison
					tank2_pos_x <= x_count2;				// temporarily stores tank 2 x position for comparison
					tank2_pos_y <= y_count2;				// temporarily stores tank 2 y position for comparison
					tank1_x_abs <= (tank1_pos_x > tank2_pos_x)?(tank1_pos_x - tank2_pos_x):(tank2_pos_x - tank1_pos_x); // absolute value of tank1 x distance
					tank1_y_abs <= (tank1_pos_y > tank2_pos_y)?(tank1_pos_y - tank2_pos_y):(tank2_pos_y - tank1_pos_y); // absolute value of tank1 y distance
					tank2_x_abs <= (tank1_pos_x > tank2_pos_x)?(tank1_pos_x - tank2_pos_x):(tank2_pos_x - tank1_pos_x); // absolute value of tank2 x distance
					tank2_y_abs <= (tank1_pos_y > tank2_pos_y)?(tank1_pos_y - tank2_pos_y):(tank2_pos_y - tank1_pos_y); // absolute value of tank2 y distance
					RefreshP2B4 = 0; //reset the last bullet's triggers
					MakeP2B4 = 0;
					ButtonBuffer = 0;
					EraseP1Heart = 0;
					EraseP2Heart = 0;
					ErasingHeart = 0;
					StartClearField = 0;
					ClearDelayCounter = 0;
					DrawingWin = 0;
				end
			if(CState == ST_ButtonBuffer)begin
				ButtonBuffer = ButtonBuffer + 1;
				DoneButtonBuffer = (ButtonBuffer == 600000);
			end
			if(CState == ST_EraseCurrent) begin // erase tank1
					DrawingTank = 1;
					x_translated = x_input + x_count; // x-input initialized to 30
					y_translated = y_input + y_count; // y-input initialized to 30
					rErase = 1;
				end
			if(CState == ST_TurnOffErase) begin
					rErase = 0;
				end
			if(CState == ST_EraseCurrent2) begin // erase tank2
					x_translated = x_count2;
					y_translated = y_count2;
					rErase = 1;
				end
			if(CState == ST_Up)begin
					rErase = 0;
					if(Up) begin
						TankDirection1 = 2'b00;
						if((tank1_x_abs > 21) || (tank1_pos_y - tank2_pos_y > 22)) begin
							if(y_count > 0)
								y_count = y_count - 1;
							else
								y_count = 0;
						end
					end
					if(Up2) begin
						TankDirection2 = 2'b00;
						if((tank2_x_abs > 21) || (tank2_pos_y - tank1_pos_y > 22)) begin
							if(y_count2 > 30)
								y_count2 = y_count2 - 1;
							else
								y_count2 = 30;
						end
					end
			end
			if(CState == ST_Down)begin
					if(Down) begin
						TankDirection1 = 2'b01;
						if((tank1_x_abs > 21) || (tank2_pos_y - tank1_pos_y > 22)) begin
							if(y_count < 158)
								y_count = y_count + 1;
							else
								y_count = 158;
								end
						end
					if(Down2) begin
						TankDirection2 = 2'b01;
						if((tank2_x_abs > 21) || (tank1_pos_y - tank2_pos_y > 22)) begin
							if(y_count2 < 188)
								y_count2 = y_count2 + 1;
							else
								y_count2 = 188;
						end
					end
			end
			if(CState == ST_Left)begin
					if(Left) begin
						TankDirection1 = 2'b10;
						if((tank1_y_abs > 21) || (tank1_pos_x - tank2_pos_x > 22)) begin
							if(x_count > 0)
								x_count = x_count - 1;
							else
								x_count = 0;
							end
					end
					if(Left2) begin
						TankDirection2 = 2'b10;
						if((tank2_y_abs > 21) || (tank2_pos_x - tank1_pos_x > 22)) begin
							if(x_count2 > 30)
								x_count2 = x_count2 - 1;
							else
								x_count2 = 30;
						end
					end
			end
			if(CState == ST_Right)begin
					if(Right) begin
						TankDirection1 = 2'b11;
						if((tank1_y_abs > 21) || (tank2_pos_x - tank1_pos_x > 22)) begin
							if(x_count < 238)
								x_count = x_count + 1;
							else
								x_count = 238;
						end
					end
					if(Right2) begin
						TankDirection2 = 2'b11;
						if((tank2_y_abs > 21) || (tank1_pos_x - tank2_pos_x > 22)) begin
							if(x_count2 < 268)
								x_count2 = x_count2 + 1;
							else
								x_count2 = 268;
						end
					end
			end
			if(CState == ST_Draw_Translated) begin // draw tank1
						Tank1Enable = 1;
						x_translated = x_input + x_count;
						y_translated = y_input + y_count;
						rDraw = 1;
					end
			if(CState == ST_TurnOffDraw) begin // delay to wait for tank1 to finish drawingz
						rDraw = 0;
						delayCount2 = delayCount2 + 1;
						DoneDelay2 = (delayCount2 == 7000);		
					end
			if(CState == ST_Draw_Translated2) begin // draw tank2
						Tank2Enable = 1;
						x_translated = x_count2;
						y_translated = y_count2;
						rDraw = 1;
					end
			if(CState == ST_Delay)begin
						rDraw = 0;
						DrawingTank = 0;
						delayCount = delayCount + 1;
						DoneDelay = (delayCount == 262000);
						tank1_pos_x <= x_input + x_count; // temporarily stores tank 1 x position for comparison
						tank1_pos_y <= y_input + y_count; // temporarily stores tank 1 y position for comparison
						tank2_pos_x <= x_count2;				// temporarily stores tank 2 x position for comparison
						tank2_pos_y <= y_count2;				// temporarily stores tank 2 y position for comparison
						Tank1Enable = 0;
						Tank2Enable = 0;
					end
			if(CState == ST_Player1Bullet1)begin
						BulletSelector = 3'b000;
						if(Shoot1 && !P1B1_Active) begin // if P1B1 "should" be created
								if((!P1B2_Active || BulletBufferP1B2 > 45) && (!P1B3_Active || BulletBufferP1B3 > 45) && (!P1B4_Active || BulletBufferP1B4 > 45)) begin // if any bullet's buffer is < 45
									MakeP1B1 = 1;
								end
						end
						else if(P1B1_Active) begin
							RefreshP1B1 = 1;
						end
					end
			if(CState == ST_Player1Bullet2)begin
						BulletSelector = 3'b001;
						RefreshP1B1 = 0;
						MakeP1B1 = 0;
						if(Shoot1 && !P1B2_Active && P1B1_Active) begin // if P1B2 "should" be created
								if((!P1B1_Active || BulletBufferP1B1 > 45) && (!P1B3_Active || BulletBufferP1B3 > 45) && (!P1B4_Active || BulletBufferP1B4 > 45)) begin // if any bullet's buffer is < 45
									MakeP1B2 = 1;
								end
						end
						else if(P1B2_Active) begin
							RefreshP1B2 = 1;
						end
					end
			if(CState == ST_Player1Bullet3)begin
						BulletSelector = 3'b010;
						RefreshP1B2 = 0;
						MakeP1B2 = 0;
						if(Shoot1 && !P1B3_Active && P1B1_Active && P1B2_Active) begin // if P1B3 "should" be created
								if((!P1B1_Active || BulletBufferP1B1 > 45) && (!P1B2_Active || BulletBufferP1B2 > 45) && (!P1B4_Active || BulletBufferP1B4 > 45)) begin // if any bullet's buffer is < 45
									MakeP1B3 = 1;
								end
						end
						else if(P1B3_Active) begin
							RefreshP1B3 = 1;
						end
					end
			if(CState == ST_Player1Bullet4)begin
						BulletSelector = 3'b011;
						RefreshP1B3 = 0;
						MakeP1B3 = 0;
						if(Shoot1 && !P1B4_Active && P1B1_Active && P1B2_Active && P1B3_Active) begin // if P1B4 "should" be created
								if((!P1B1_Active || BulletBufferP1B1 > 45) && (!P1B2_Active || BulletBufferP1B2 > 45) && (!P1B3_Active || BulletBufferP1B3 > 45)) begin // if any bullet's buffer is < 45
									MakeP1B4 = 1;
								end
						end
						else if(P1B4_Active) begin
							RefreshP1B4 = 1;
						end	
					end
			if(CState == ST_Player2Bullet1)begin
						BulletSelector = 3'b100;
						RefreshP1B4 = 0;
						MakeP1B4 = 0;
						if(Shoot2 && !P2B1_Active) begin // if P2B1 "should" be created
								if((!P2B2_Active || BulletBufferP2B2 > 45) && (!P2B3_Active || BulletBufferP2B3 > 45) && (!P2B4_Active || BulletBufferP2B4 > 45)) begin // if any bullet's buffer is < 45
									MakeP2B1 = 1;
								end
						end
						else if(P2B1_Active) begin
							RefreshP2B1 = 1;
						end
					end
			if(CState == ST_Player2Bullet2)begin
						BulletSelector = 3'b101;
						RefreshP2B1 = 0;
						MakeP2B1 = 0;
						if(Shoot2 && !P2B2_Active && P2B1_Active) begin // if P2B2 "should" be created
								if((!P2B1_Active || BulletBufferP2B1 > 45) && (!P2B3_Active || BulletBufferP2B3 > 45) && (!P2B4_Active || BulletBufferP2B4 > 45)) begin // if any bullet's buffer is < 45
									MakeP2B2 = 1;
								end
						end
						else if(P2B2_Active) begin
							RefreshP2B2 = 1;
						end
					end
			if(CState == ST_Player2Bullet3)begin
						BulletSelector = 3'b110;
						RefreshP2B2 = 0;
						MakeP2B2 = 0;
						if(Shoot2 && !P2B3_Active && P2B1_Active && P2B2_Active) begin // if P2B3 "should" be created
								if((!P2B1_Active || BulletBufferP2B1 > 45) && (!P2B2_Active || BulletBufferP2B2 > 45) && (!P2B4_Active || BulletBufferP2B4 > 45)) begin // if any bullet's buffer is < 45
									MakeP2B3 = 1;
								end
						end
						else if(P2B3_Active) begin
							RefreshP2B3 = 1;
						end
					end
			if(CState == ST_Player2Bullet4)begin
						BulletSelector = 3'b111;
						RefreshP2B3 = 0;
						MakeP2B3 = 0;
						if(Shoot2 && !P2B4_Active && P2B1_Active && P2B2_Active && P2B3_Active) begin // if P2B4 "should" be created
								if((!P2B1_Active || BulletBufferP2B1 > 45) && (!P2B2_Active || BulletBufferP2B2 > 45) && (!P2B3_Active || BulletBufferP2B3 > 45)) begin // if any bullet's buffer is < 45
									MakeP2B4 = 1;
								end
						end
						else if(P2B4_Active) begin
							RefreshP2B4 = 1;
						end	
					end
			if(CState == ST_EraseP1Heart)begin
				EraseP1Heart = 1;
				ErasingHeart = 1;
			end
			if(CState == ST_EraseP2Heart)begin
				EraseP2Heart = 1;
				ErasingHeart = 1;
			end
			if(CState == ST_ResetPositons)begin
					x_count = 1;
					y_count = 1;
					x_count2 = 268;
					y_count2 = 188;
			end
			if(CState == ST_ClearField)begin
					StartClearField = 1;
			end
			if(CState == ST_TurnOffClear)begin
				ClearDelayCounter = ClearDelayCounter + 1;
				DoneClearDelay = (ClearDelayCounter == 140000);
			end
			if(CState == ST_DrawWinner)begin
				DrawingWin = 1;
				if (P1HitCount == 0)
					Player1Win = 1;
				else if (P2HitCount == 0)
					Player2Win = 1;
			end
	end
	// END OF STATE LOGIC
		
	 DrawPlayerWin winner(
	CLOCK_50, 
	resetn,
	Player1Win,
	Player2Win,
	color_DrawPlayerWin,
	x_DrawPlayerWin,
	y_DrawPlayerWin,
	plot_DrawPlayerWin
	);
	
	reg Player1Win;
	reg Player2Win;
	reg DrawingWin;
		
		reg DoneClearDelay;
		reg [17:0]ClearDelayCounter;
		
		wire [8:0]x_DrawPlayerWin;
		wire [7:0]y_DrawPlayerWin;
		wire [2:0]color_DrawPlayerWin;
		wire plot_DrawPlayerWin;
		
		// INPUTS INTO MULTIPLEXER
		// signals from tanks
		wire [8:0]Tank_x;
		wire [7:0]Tank_y;
		wire [2:0]Tank_color;
		reg [1:0]TankDirection1, TankDirection2;
		reg Tank1Enable, Tank2Enable;
		
		// selection signals
		reg DrawingTank;
		reg [2:0] BulletSelector; //increase mux selector bit size for more bullet capacity
		reg [22:0] ButtonBuffer;
		reg DoneButtonBuffer;
		
		// signals from 8 different bullets [x,y,color,plot,Make,Refresh,Active,DoneDraw,BulletBuffer]
		wire [8:0] P1B1_x_pos, P1B2_x_pos, P1B3_x_pos, P1B4_x_pos, P2B1_x_pos, P2B2_x_pos, P2B3_x_pos, P2B4_x_pos;
		wire [7:0] P1B1_y_pos, P1B2_y_pos, P1B3_y_pos, P1B4_y_pos, P2B1_y_pos, P2B2_y_pos, P2B3_y_pos, P2B4_y_pos;
		wire [2:0] P1B1_color, P1B2_color, P1B3_color, P1B4_color, P2B1_color, P2B2_color, P2B3_color, P2B4_color;
		wire P1B1_plot, P1B2_plot, P1B3_plot, P1B4_plot, P2B1_plot, P2B2_plot, P2B3_plot, P2B4_plot;
		reg MakeP1B1, MakeP1B2, MakeP1B3, MakeP1B4, MakeP2B1, MakeP2B2, MakeP2B3, MakeP2B4;
		reg RefreshP1B1, RefreshP1B2, RefreshP1B3, RefreshP1B4, RefreshP2B1, RefreshP2B2, RefreshP2B3, RefreshP2B4;
		wire P1B1_Active, P1B2_Active, P1B3_Active, P1B4_Active, P2B1_Active, P2B2_Active, P2B3_Active, P2B4_Active;
		wire P1B1_DoneDraw, P1B2_DoneDraw, P1B3_DoneDraw, P1B4_DoneDraw, P2B1_DoneDraw, P2B2_DoneDraw, P2B3_DoneDraw, P2B4_DoneDraw;
		wire [8:0]BulletBufferP1B1, BulletBufferP1B2, BulletBufferP1B3, BulletBufferP1B4, BulletBufferP2B1, BulletBufferP2B2, BulletBufferP2B3, BulletBufferP2B4;
		// END OF INPUTS
		
		plotSelector plot(
								P1B1_x_pos, P1B1_y_pos, P1B1_color, P1B1_plot,
								P1B2_x_pos, P1B2_y_pos, P1B2_color, P1B2_plot,
								P1B3_x_pos, P1B3_y_pos, P1B3_color, P1B3_plot,
								P1B4_x_pos, P1B4_y_pos, P1B4_color, P1B4_plot,
								P2B1_x_pos, P2B1_y_pos, P2B1_color, P2B1_plot,
								P2B2_x_pos, P2B2_y_pos, P2B2_color, P2B2_plot,
								P2B3_x_pos, P2B3_y_pos, P2B3_color, P2B3_plot,
								P2B4_x_pos, P2B4_y_pos, P2B4_color, P2B4_plot,
								Tank_x, Tank_y, Tank_color, Tank_plot,
								BulletSelector, DrawingTank,
								ErasingHeart, x_heart, y_heart, color_heart, plot_heart,
								StartClearField, x_clear, y_clear, color_clear, plot_clear,
								DrawingWin, x_DrawPlayerWin, y_DrawPlayerWin, color_DrawPlayerWin, plot_DrawPlayerWin,
								x_plot, y_plot, color_plot, enable_plot
								);
								
		BulletMaker P1B1(
								CLOCK_50, resetn, 
								MakeP1B1, RefreshP1B1, 
								tank1_pos_x, tank1_pos_y, TankDirection1, 
								P1B1_x_pos, P1B1_y_pos, P1B1_color, P1B1_plot, 
								P1B1_Active, P1B1_DoneDraw, BulletBufferP1B1,
								P1B1_coll, tank2_pos_x, tank2_pos_y);
								
		BulletMaker P1B2(
								CLOCK_50, resetn, 
								MakeP1B2, RefreshP1B2, 
								tank1_pos_x, tank1_pos_y, TankDirection1, 
								P1B2_x_pos, P1B2_y_pos, P1B2_color, P1B2_plot, 
								P1B2_Active, P1B2_DoneDraw, BulletBufferP1B2,
								P1B2_coll, tank2_pos_x, tank2_pos_y);
								
		BulletMaker P1B3(
								CLOCK_50, resetn, 
								MakeP1B3, RefreshP1B3, 
								tank1_pos_x, tank1_pos_y, TankDirection1, 
								P1B3_x_pos, P1B3_y_pos, P1B3_color, P1B3_plot, 
								P1B3_Active, P1B3_DoneDraw, BulletBufferP1B3,
								P1B3_coll, tank2_pos_x, tank2_pos_y);
								
		BulletMaker P1B4(
								CLOCK_50, resetn, 
								MakeP1B4, RefreshP1B4, 
								tank1_pos_x, tank1_pos_y, TankDirection1, 
								P1B4_x_pos, P1B4_y_pos, P1B4_color, P1B4_plot, 
								P1B4_Active, P1B4_DoneDraw, BulletBufferP1B4,
								P1B4_coll, tank2_pos_x, tank2_pos_y);
								
		BulletMaker P2B1(
								CLOCK_50, resetn, 
								MakeP2B1, RefreshP2B1, 
								tank2_pos_x, tank2_pos_y, TankDirection2, 
								P2B1_x_pos, P2B1_y_pos, P2B1_color, P2B1_plot, 
								P2B1_Active, P2B1_DoneDraw, BulletBufferP2B1,
								P2B1_coll, tank1_pos_x, tank1_pos_y); 
								
		BulletMaker P2B2(
								CLOCK_50, resetn, 
								MakeP2B2, RefreshP2B2, 
								tank2_pos_x, tank2_pos_y, TankDirection2, 
								P2B2_x_pos, P2B2_y_pos, P2B2_color, P2B2_plot, 
								P2B2_Active, P2B2_DoneDraw, BulletBufferP2B2,
								P2B2_coll, tank1_pos_x, tank1_pos_y);
								
		BulletMaker P2B3(
								CLOCK_50, resetn, 
								MakeP2B3, RefreshP2B3, 
								tank2_pos_x, tank2_pos_y, TankDirection2, 
								P2B3_x_pos, P2B3_y_pos, P2B3_color, P2B3_plot, 
								P2B3_Active, P2B3_DoneDraw, BulletBufferP2B3,
								P2B3_coll, tank1_pos_x, tank1_pos_y);
								
		BulletMaker P2B4(
								CLOCK_50, resetn, 
								MakeP2B4, RefreshP2B4, 
								tank2_pos_x, tank2_pos_y, TankDirection2, 
								P2B4_x_pos, P2B4_y_pos, P2B4_color, P2B4_plot, 
								P2B4_Active, P2B4_DoneDraw, BulletBufferP2B4,
								P2B4_coll, tank1_pos_x, tank1_pos_y);
		
		
		draw_and_erase_tank tank_animator(
														CLOCK_50, resetn, rDraw, rErase, 
														x_translated, y_translated, 
														Tank_color, Tank_x, Tank_y, Tank_plot, 
														DoneDrawOrErase, 
														TankDirection1, TankDirection2, 
														Tank1Enable, Tank2Enable);
		
				// debug
		assign LEDR[17] = Up;
		assign LEDR[16] = Down;
		assign LEDR[15] = Left;
		assign LEDR[14] = Right;
		assign LEDR[13] = Shoot1;
		assign LEDR[12] = Up2;
		assign LEDR[11] = Down2;
		assign LEDR[10] = Left2;
		assign LEDR[9] = Right2;
		assign LEDR[8] = Shoot2;
		
		reg ErasingHeart;
		reg EraseP1Heart, EraseP2Heart;
		wire DoneEraseHeart;
		// HITS COUNTER
		wire P1B1_coll, P1B2_coll, P1B3_coll, P1B4_coll, P2B1_coll, P2B2_coll, P2B3_coll, P2B4_coll;
		input resetLife;// = SW[10]; // control with super-top-level fsm
		wire [1:0]P1HitCount, P2HitCount;
		assign LEDG[7:6] = P1HitCount; // change later to erasing half a heart off the background every time a tank gets hit
	//	assign LEDR[10:9] = P2HitCount; // redraw the hearts from ram when the game is reset in super-top-level fsm
													
		hitCount deathmatch(CLOCK_50, resetLife, P1B1_coll, P1B2_coll, P1B3_coll, P1B4_coll, P2B1_coll, P2B2_coll, P2B3_coll, P2B4_coll, P1HitCount, P2HitCount);
		// END OF HITS COUNTER
		
		ClearField clear(CLOCK_50, resetn, StartClearField, color_clear, x_clear, y_clear, plot_clear, DoneClearField);
		reg StartClearField;
		wire [8:0]x_clear;
		wire [7:0]y_clear;
		wire [2:0]color_clear;
		wire plot_clear;
		wire DoneClearField;
		
		wire [8:0]x_heart;
		wire [7:0]y_heart;
		wire [2:0]color_heart;
		wire plot_heart;
		EraseHearts heartEraser(CLOCK_50, resetn, EraseP1Heart, EraseP2Heart, P1HitCount, P2HitCount, color_heart, x_heart, y_heart, plot_heart, DoneEraseHeart);
		
endmodule
		
module hitCount (iclock, iresetLife, iP1B1_coll, iP1B2_coll, iP1B3_coll, iP1B4_coll, iP2B1_coll, iP2B2_coll, iP2B3_coll, iP2B4_coll, oP1HitCount, oP2HitCount);
		input iclock, iresetLife; // active high reset @!
		input iP1B1_coll, iP1B2_coll, iP1B3_coll, iP1B4_coll, iP2B1_coll, iP2B2_coll, iP2B3_coll, iP2B4_coll;
		output reg [2:0]oP1HitCount, oP2HitCount; //increase size for greater life capacity
		
		// DEATH COUNTER
		always@(posedge iclock)begin
			if (iresetLife) begin
				oP1HitCount = 3;
				oP2HitCount = 3;
			end
			else if (iP1B1_coll || iP1B2_coll || iP1B3_coll || iP1B4_coll) begin
				oP2HitCount = oP2HitCount - 1;
			end
			else if (iP2B1_coll || iP2B2_coll || iP2B3_coll || iP2B4_coll) begin
				oP1HitCount = oP1HitCount - 1;
			end
		end
		//End of death counter
endmodule
