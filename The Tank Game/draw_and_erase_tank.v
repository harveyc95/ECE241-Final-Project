module draw_and_erase_tank 
	(
	iCLOCK_50, 
	iresetn, 
	idrawEn, 
	ieraseEn, 
	ix_pos, 
	iy_pos, 
	ocolor_out, 
	ox, 
	oy, 
	owriteEn,
	oDoneSignal,
	iTankDirection1,
	iTankDirection2,
	iTank1Enable,
	iTank2Enable
	);
	
	input iCLOCK_50, iresetn, idrawEn, ieraseEn;
	input [1:0]iTankDirection1; // 00 = tank1 up, 01 = tank1 down, 10 = tank1 left, 11 = tank1 right
	input [1:0]iTankDirection2; // 00 = tank2 up, 01 = tank2 down, 10 = tank2 left, 11 = tank2 right
	input iTank1Enable, iTank2Enable;
	input [8:0]ix_pos;
	input [7:0]iy_pos;
	output [2:0]ocolor_out;
	output reg [8:0]ox;
	output reg [7:0]oy;
	output reg owriteEn;
	output reg oDoneSignal;
	
	reg [4:0]x_counter, y_counter; //up to 32
	reg draw;
	
	always@(*) begin
		if(iTank1Enable)begin
			if(iTankDirection1 == 2'b00) // tank1 up
				mem_color = Tank_1U_Color;
			else if(iTankDirection1 == 2'b01)
				mem_color = Tank_1D_Color;
			else if(iTankDirection1 == 2'b10)
				mem_color = Tank_1L_Color;
			else if(iTankDirection1 == 2'b11)
				mem_color = Tank_1R_Color;
		end
		if(iTank2Enable)begin
			if(iTankDirection2 == 2'b00) // tank2 up
				mem_color = Tank_2U_Color;
			else if(iTankDirection2 == 2'b01)
				mem_color = Tank_2D_Color;
			else if(iTankDirection2 == 2'b10)
				mem_color = Tank_2L_Color;
			else if(iTankDirection2 == 2'b11)
				mem_color = Tank_2R_Color;
		end
end
	
	assign ocolor_out = draw ? mem_color : 3'b111;
	
	// RAM initialization controllers
	reg [8:0]ramAddress; //0 to 512
	reg [2:0]idata;
	reg ramWen;
	reg [2:0] mem_color;
	wire [2:0] Tank_1U_Color;
	wire [2:0] Tank_1D_Color;
	wire [2:0] Tank_1L_Color;
	wire [2:0] Tank_1R_Color;
	wire [2:0] Tank_2U_Color;
	wire [2:0] Tank_2D_Color;
	wire [2:0] Tank_2L_Color;
	wire [2:0] Tank_2R_Color;
	
	// INITIALIZIE RAM MODULES FOR TANK 1
	TankOneUp     Tank_1U(ramAddress, iCLOCK_50, idata, ramWen, Tank_1U_Color);
	TankOneDown   Tank_1D(ramAddress, iCLOCK_50, idata, ramWen, Tank_1D_Color);
	TankOneLeft   Tank_1L(ramAddress, iCLOCK_50, idata, ramWen, Tank_1L_Color);
	TankOneRight  Tank_1R(ramAddress, iCLOCK_50, idata, ramWen, Tank_1R_Color);
	
	// INITIALIZIE RAM MODULES FOR TANK 2
	TankTwoUp     Tank_2U(ramAddress, iCLOCK_50, idata, ramWen, Tank_2U_Color);
	TankTwoDown   Tank_2D(ramAddress, iCLOCK_50, idata, ramWen, Tank_2D_Color);
	TankTwoLeft   Tank_2L(ramAddress, iCLOCK_50, idata, ramWen, Tank_2L_Color);
	TankTwoRight  Tank_2R(ramAddress, iCLOCK_50, idata, ramWen, Tank_2R_Color);
	
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
					if (y_counter == 21 && x_counter == 21) // stop when y_counter reaches 16
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
			if (x_counter < 21) // increments x_counter until x_counter is > 15
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