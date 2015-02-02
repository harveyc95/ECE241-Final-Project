//MAKE and MOVE single bullets to edge of boundary
module BulletMaker(iCLOCK_50, iresetn, iMakeBullet, iBulletRefresh, iX_starting_pos, iY_starting_pos, iDirection, oX, oY, oColor, 
							owriteEn, oactive, oDoneBulletCycle, oBulletBuffer, oCollision, iotherTank_x, iotherTank_y);
	
	input iCLOCK_50, iresetn, iMakeBullet, iBulletRefresh;
	input [8:0]iX_starting_pos;
	input [7:0]iY_starting_pos;
	input [1:0]iDirection;
	output [8:0]oX;
	output [7:0]oY;
	output [2:0]oColor;
	output owriteEn;
	output reg oactive, oDoneBulletCycle;
	output reg [8:0] oBulletBuffer;
	output reg oCollision;
	input [8:0]iotherTank_x;
	input [7:0]iotherTank_y;
	
	// bullet data
	reg [8:0] translated_bullet_x;
	reg [7:0] translated_bullet_y;
	reg [1:0] bullet_direction;
	// drawing controls
	reg rErase, rDraw;
	wire DoneDrawOrErase;
	
	//states in order
	parameter [3:0] ST_Idle = 0, ST_SetValues = 1,
						 ST_DrawBullet = 2, ST_TurnOffDraw = 3,
						 ST_SendDoneSignal = 4,
						 ST_Delay = 5,
						 ST_deIncrementBullet = 6,
						 ST_EraseBullet = 7, ST_TurnOffErase = 8,
						 ST_CollisionDetect = 9,
						 ST_IncrementBullet = 10;
						 
	
	// begin of state flip flops
	reg [3:0] CState, NState;
	always@(posedge iCLOCK_50)begin
		if(!iresetn)
			CState <= ST_Idle;
		else
			CState <= NState;
	end
	// end of state flip flops
	
	// begin of state table
	always@(*) begin
		case(CState)
			ST_Idle: begin
				if(iMakeBullet)
					NState <= ST_SetValues;
				else
					NState <= ST_Idle;
			end
			ST_SetValues: begin
					NState <= ST_DrawBullet;
			end
			ST_DrawBullet: begin
				if(DoneDrawOrErase)
					NState <= ST_TurnOffDraw;
				else
					NState <= ST_DrawBullet;
			end
			ST_TurnOffDraw: begin
				if (donebuffering)
					NState <= ST_SendDoneSignal;
				else
					NState <= ST_TurnOffDraw;
			end
			ST_SendDoneSignal: begin
					NState <= ST_Delay;
			end
			ST_Delay: begin
				if(iBulletRefresh)
					NState <= ST_deIncrementBullet;
				else 
					NState <= ST_Delay;
			end
			ST_deIncrementBullet: begin
					NState <= ST_EraseBullet;
			end
			ST_EraseBullet: begin
				if(DoneDrawOrErase)
					NState <= ST_TurnOffErase;
				else
					NState <= ST_EraseBullet;
			end
			ST_TurnOffErase: begin
					NState <= ST_CollisionDetect;
			end
			ST_CollisionDetect: begin
				if (Bcollided_w_tank || Bcollided_w_wall)
					NState <= ST_Idle;
				else
					NState <= ST_IncrementBullet;
			end
			ST_IncrementBullet: begin
					NState <= ST_DrawBullet;
			end
			
			default:
					NState <= ST_Idle;
		endcase
	end
	// eoftable
	
	// begin of state logic
	always@(posedge iCLOCK_50)begin
		if(CState == ST_Idle)begin
			oactive = 0;
			oDoneBulletCycle = 0;
			oBulletBuffer = 0;
			oCollision = 0;
			bullet_direction = iDirection;
		end
		else if(CState == ST_SetValues)begin
			oactive = 1;
			if(bullet_direction == 2'b00)begin // UP
				translated_bullet_x = iX_starting_pos + 10;
				translated_bullet_y = iY_starting_pos - 1;
			end
			else if(bullet_direction == 2'b01)begin // DOWN
				translated_bullet_x = iX_starting_pos + 10;
				translated_bullet_y = iY_starting_pos + 22;
			end
			else if(bullet_direction == 2'b10)begin // LEFT
				translated_bullet_x = iX_starting_pos - 2;
				translated_bullet_y = iY_starting_pos + 10;
			end
			else if(bullet_direction == 2'b11)begin // RIGHT
				translated_bullet_x = iX_starting_pos + 22;
				translated_bullet_y = iY_starting_pos + 10;
			end
		end
		else if (CState == ST_deIncrementBullet) begin
			if(bullet_direction == 2'b00) // UP
				translated_bullet_y = translated_bullet_y + 1;
			else if(bullet_direction == 2'b01) // DOWN
				translated_bullet_y = translated_bullet_y - 1;				
			else if(bullet_direction == 2'b10) // LEFT
				translated_bullet_x = translated_bullet_x + 1;
			else if(bullet_direction == 2'b11) // RIGHT
				translated_bullet_x = translated_bullet_x - 1;
			end
		else if(CState == ST_EraseBullet)begin
			rErase = 1;
		end
		else if(CState == ST_TurnOffErase)begin
			rErase = 0;
		end
		else if(CState == ST_IncrementBullet)begin
			if(bullet_direction == 2'b00) // UP
				translated_bullet_y = translated_bullet_y - 2;
			else if(bullet_direction == 2'b01) // DOWN
				translated_bullet_y = translated_bullet_y + 2;				
			else if(bullet_direction == 2'b10) // LEFT
				translated_bullet_x = translated_bullet_x - 2;
			else if(bullet_direction == 2'b11) // RIGHT
				translated_bullet_x = translated_bullet_x + 2;
		end
		else if(CState == ST_DrawBullet)begin
			rDraw = 1;
			drawbuffer = 0;
			donebuffering = 0;
		end
		else if(CState == ST_TurnOffDraw)begin
			rDraw = 0;
			drawbuffer = drawbuffer + 1;
			donebuffering = (drawbuffer == 32);
		end
		else if(CState == ST_SendDoneSignal)begin
			oBulletBuffer = oBulletBuffer + 1;
			oDoneBulletCycle = 1;
		end
		else if(CState == ST_Delay)begin
			oDoneBulletCycle = 0;
		end
		else if (CState == ST_CollisionDetect)begin
			if (Bcollided_w_tank)
				oCollision = 1;
			else
				oCollision = 0;
		end
	end
	// eoflogic
	
	// buffer to fix drawing problem, allow time for output to vga -> monitor
	reg donebuffering;
	reg [5:0]drawbuffer;
	
	// collision detection flags
	wire Bcollided_w_tank;
	assign Bcollided_w_tank = ((translated_bullet_x + 1) > iotherTank_x) && (translated_bullet_x < (iotherTank_x + 21)) && ((translated_bullet_y + 1) > iotherTank_y) && (translated_bullet_y < (iotherTank_y + 21));
	wire Bcollided_w_wall;
	assign Bcollided_w_wall = (translated_bullet_x < 30) || (translated_bullet_x > 287) || (translated_bullet_y < 30) || (translated_bullet_y > 207);
	
	// outputting back to vga->monitor
	drawPLUSerase drawneraseit(iCLOCK_50, iresetn, rDraw, rErase, 
										translated_bullet_x, translated_bullet_y, oColor, 
										oX, oY, owriteEn, DoneDrawOrErase);
	
endmodule



module drawPLUSerase (iCLOCK_50, iresetn, idrawEn, ieraseEn, 
							 ix_pos, iy_pos, ocolor_out, 
							 ox, oy, owriteEn, oDoneSignal);
	
	input iCLOCK_50, iresetn, idrawEn, ieraseEn;
	input [8:0]ix_pos;
	input [7:0]iy_pos;
	output [2:0]ocolor_out;
	output reg [8:0]ox;
	output reg [7:0]oy;
	output reg owriteEn;
	output reg oDoneSignal;
	
	//store starting values
	reg [8:0]x_start;
	reg [7:0]y_start;
	
	reg [2:0]x_counter, y_counter; //up to 2
	reg draw;
	assign ocolor_out = draw ? 3'b000 : 3'b111; // DRAW RED, ERASE WHITE
	
	//STATES and State FFs
	parameter [2:0] ST_idle = 0, ST_chooseColor = 1, ST_setMem = 2, ST_draw = 3, ST_count = 4, ST_Done = 5, ST_Done_Delay = 6;
	
	reg [2:0] CState, NState;
	always@(posedge iCLOCK_50) begin
		if (!iresetn)
			CState <= ST_idle;
		else
			CState <= NState;
	end
	//end fsm setup
	
	//CHANGING STATE
	always@(*) begin
		NState <= ST_idle;
		case(CState)
				ST_idle: begin
					if (idrawEn || ieraseEn)
						NState <= ST_chooseColor;
					else
						NState <= ST_idle;
					end
				ST_chooseColor:
						NState <= ST_setMem;
				ST_setMem:
						NState <= ST_draw;
				ST_draw: begin
					if (y_counter == 1 && x_counter == 1) // stop when y_counter at pt (1,1)
						NState <= ST_Done;
					else
						NState <= ST_count;
					end
				ST_count:
						NState <= ST_draw;
				ST_Done:
						NState <= ST_idle;
				default:
						NState <= ST_idle;
		endcase
	end
	// end state rules
	
	//VARIOUS COUNTERS
	always@(posedge iCLOCK_50) begin
		if (CState == ST_idle) begin
			owriteEn = 0;
			oDoneSignal = 0;
			
			if(idrawEn)
				draw = 1;
			else if(ieraseEn)
				draw = 0;
			
			x_start = ix_pos;
			y_start = iy_pos;
			
			end
		if (CState == ST_chooseColor) begin
			
			end
		if (CState == ST_setMem) begin
			x_counter = 0;
			y_counter = 0;
			end
		if (CState == ST_count) begin
			owriteEn = 0;
			if (x_counter < 1) // increments x_counter until x_counter is > 1
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

		ox = x_start + x_counter;
		oy = y_start + y_counter;
	end	
	// end counters
endmodule
