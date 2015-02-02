 module plotSelector(
									iP1B1_x_pos, iP1B1_y_pos, iP1B1_color, iP1B1_plot,
									iP1B2_x_pos, iP1B2_y_pos, iP1B2_color, iP1B2_plot,
									iP1B3_x_pos, iP1B3_y_pos, iP1B3_color, iP1B3_plot,
									iP1B4_x_pos, iP1B4_y_pos, iP1B4_color, iP1B4_plot,
									iP2B1_x_pos, iP2B1_y_pos, iP2B1_color, iP2B1_plot,
									iP2B2_x_pos, iP2B2_y_pos, iP2B2_color, iP2B2_plot,
									iP2B3_x_pos, iP2B3_y_pos, iP2B3_color, iP2B3_plot,
									iP2B4_x_pos, iP2B4_y_pos, iP2B4_color, iP2B4_plot,
									iTank_x, iTank_y, iTank_color, iTank_plot,
									iBulletSelector, iDrawingTank, 
									iErasingHeart, ix_heart, iy_heart, icolor_heart, iplot_heart,
									iStartClearField, ix_clear, iy_clear, icolor_clear, iplot_clear,
									DrawingWin, x_DrawPlayerWin, y_DrawPlayerWin, color_DrawPlayerWin, plot_DrawPlayerWin,
									oX_coordinate, oY_coordinate, oColor, oPlot
									);
				
// inputs
input [8:0]iP1B1_x_pos, iP1B2_x_pos, iP1B3_x_pos, iP1B4_x_pos, iP2B1_x_pos, iP2B2_x_pos, iP2B3_x_pos, iP2B4_x_pos, iTank_x, ix_heart, ix_clear, x_DrawPlayerWin;
input [7:0]iP1B1_y_pos, iP1B2_y_pos, iP1B3_y_pos, iP1B4_y_pos, iP2B1_y_pos, iP2B2_y_pos, iP2B3_y_pos, iP2B4_y_pos, iTank_y, iy_heart, iy_clear, y_DrawPlayerWin;
input [2:0]iP1B1_color, iP1B2_color, iP1B3_color, iP1B4_color, iP2B1_color, iP2B2_color, iP2B3_color, iP2B4_color, iTank_color, icolor_heart, icolor_clear, color_DrawPlayerWin;
input [2:0]iBulletSelector;
input iP1B1_plot, iP1B2_plot, iP1B3_plot, iP1B4_plot, iP2B1_plot, iP2B2_plot, iP2B3_plot, iP2B4_plot, iTank_plot, iDrawingTank, iErasingHeart, iplot_heart, iStartClearField, iplot_clear;
input DrawingWin, plot_DrawPlayerWin;

// outputs
output [8:0]oX_coordinate;
output [7:0]oY_coordinate;
output [2:0]oColor;
output oPlot;

// internal registers
reg [8:0]bullet_x;
reg [7:0]bullet_y;
reg [2:0]bullet_color;
reg bullet_plot;

wire [8:0]temp_x;
wire [7:0]temp_y;
wire [2:0]temp_color;
wire temp_plot;

wire [8:0]temp_x2;
wire [7:0]temp_y2;
wire [2:0]temp_color2;
wire temp_plot2;

wire [8:0]temp_x3;
wire [7:0]temp_y3;
wire [2:0]temp_color3;
wire temp_plot3;

assign oX_coordinate = DrawingWin ? x_DrawPlayerWin : temp_x3;							// mux to choose x position to vga
assign oY_coordinate = DrawingWin ? y_DrawPlayerWin : temp_y3;							// mux to choose y position to vga
assign oColor = DrawingWin ? color_DrawPlayerWin : temp_color3;   						// mux to choose color to vga
assign oPlot = DrawingWin ? plot_DrawPlayerWin : temp_plot3;								// mux to choose enable signal for vga

assign temp_x3 = iStartClearField ? ix_clear : temp_x2;							// mux to choose x position to vga
assign temp_y3 = iStartClearField ? iy_clear : temp_y2;							// mux to choose y position to vga
assign temp_color3 = iStartClearField ? icolor_clear : temp_color2;   						// mux to choose color to vga
assign temp_plot3 = iStartClearField ? iplot_clear : temp_plot2;								// mux to choose enable signal for vga

assign temp_x2 = iErasingHeart ? ix_heart : temp_x;							// mux to choose x position to vga
assign temp_y2 = iErasingHeart ? iy_heart : temp_y;							// mux to choose y position to vga
assign temp_color2 = iErasingHeart ? icolor_heart : temp_color;   						// mux to choose color to vga
assign temp_plot2 = iErasingHeart ? iplot_heart : temp_plot;								// mux to choose enable signal for vga

assign temp_x = iDrawingTank ? iTank_x : bullet_x;							// mux to choose x position to vga
assign temp_y = iDrawingTank ? iTank_y : bullet_y;							// mux to choose y position to vga
assign temp_color = iDrawingTank ? iTank_color : bullet_color;   						// mux to choose color to vga
assign temp_plot = iDrawingTank ? iTank_plot : bullet_plot;								// mux to choose enable signal for vga

always@(*)begin
	if(iBulletSelector == 3'b000) begin
		bullet_x = iP1B1_x_pos;
		bullet_y = iP1B1_y_pos;
		bullet_color = iP1B1_color;
		bullet_plot = iP1B1_plot;
	end
	else if(iBulletSelector == 3'b001) begin
		bullet_x = iP1B2_x_pos;
		bullet_y = iP1B2_y_pos;
		bullet_color = iP1B2_color;
		bullet_plot = iP1B2_plot;
	end
	else if(iBulletSelector == 3'b010) begin
		bullet_x = iP1B3_x_pos;
		bullet_y = iP1B3_y_pos;
		bullet_color = iP1B3_color;
		bullet_plot = iP1B3_plot;
	end
	else if(iBulletSelector == 3'b011) begin
		bullet_x = iP1B4_x_pos;
		bullet_y = iP1B4_y_pos;
		bullet_color = iP1B4_color;
		bullet_plot = iP1B4_plot;
	end
	else if(iBulletSelector == 3'b100) begin
		bullet_x = iP2B1_x_pos;
		bullet_y = iP2B1_y_pos;
		bullet_color = iP2B1_color;
		bullet_plot = iP2B1_plot;
	end
	else if(iBulletSelector == 3'b101) begin
		bullet_x = iP2B2_x_pos;
		bullet_y = iP2B2_y_pos;
		bullet_color = iP2B2_color;
		bullet_plot = iP2B2_plot;
	end
	else if(iBulletSelector == 3'b110) begin
		bullet_x = iP2B3_x_pos;
		bullet_y = iP2B3_y_pos;
		bullet_color = iP2B3_color;
		bullet_plot = iP2B3_plot;
	end
	else if(iBulletSelector == 3'b111) begin
		bullet_x = iP2B4_x_pos;
		bullet_y = iP2B4_y_pos;
		bullet_color = iP2B4_color;
		bullet_plot = iP2B4_plot;
	end
	else begin
		bullet_x = 0;
		bullet_y = 0;
		bullet_color = 0;
		bullet_plot = 0;
	end
end
	
endmodule
