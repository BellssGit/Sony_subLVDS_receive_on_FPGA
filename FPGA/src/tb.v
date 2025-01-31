`timescale 1ns/1ps
module tb;

GSR GSR_INST(.GSR(1'b1));
PUR PUR_INST(.PUR(1'b1));

// 300MHz clock coming from the sensor
reg imx_clkin;
initial begin
	imx_clkin = 0;
	#(3.33333333/4);
	forever begin
		#(3.33333333/2); 
		imx_clkin = ~imx_clkin;
	end
end

reg sim_data_clk;
initial begin
	sim_data_clk = 0;
	forever begin
		#(3.33333333/2); 
		sim_data_clk = ~sim_data_clk;
	end
end

// 50MHz ref clock coming from xtal
reg ref_clkin;
initial ref_clkin = 0 ;
always #(20/2) ref_clkin = ~ref_clkin;


parameter SEND_SAV1 = 0;
parameter SEND_SAV2 = 1;
parameter SEND_SAV3 = 2;
parameter SEND_SAV4 = 3;
parameter SEND_Valid_data = 4;
parameter SEND_EAV1 = 5;
parameter SEND_EAV2 = 6;
parameter SEND_EAV3 = 7;
parameter SEND_EAV4 = 8;
parameter BLANK = 9;


reg [3:0] state = 0;
reg [31:0] data_clk_cnt = 0;

reg [7:0] cam_data = 0;

reg new_pack = 0;
reg [9:0] pack_clk_cnt = 0;
reg [9:0] pack_cnt = 0;
reg flag = 0;

always @(posedge sim_data_clk or negedge sim_data_clk) begin
	case (state)
		SEND_SAV1: begin
			// 1st vaild SAV: 0xFFF
			cam_data = 8'b11111111;

			// Count 12bit
			if (data_clk_cnt == 12) begin
				state <= SEND_SAV2;
				data_clk_cnt <= 0;
			end
			else begin
				data_clk_cnt <= data_clk_cnt + 1;
			end
		end
		SEND_SAV2: begin
			// 2nd vaild SAV: 0x000
			cam_data = 0;

			// Count 12bit
			if (data_clk_cnt == 11) begin
				state <= SEND_SAV3;
				data_clk_cnt <= 0;
			end
			else begin
				data_clk_cnt <= data_clk_cnt + 1;
			end			
		end
		SEND_SAV3: begin
			// 3rd vaild SAV: 0x000
			cam_data = 0;

			// Count 12bit
			if (data_clk_cnt == 11) begin
				state <= SEND_SAV4;
				data_clk_cnt <= 0;
			end
			else begin
				data_clk_cnt <= data_clk_cnt + 1;
			end			
		end
		SEND_SAV4: begin
			// 4th vaild SAV: 0x800

			if (data_clk_cnt == 0) begin
				cam_data = 8'b11111111;
			end
			else begin
				cam_data = 0;
			end

			if (data_clk_cnt == 11) begin
				state <= SEND_Valid_data;
				data_clk_cnt <= 0;
			end
			else begin
				data_clk_cnt <= data_clk_cnt + 1;
			end		
				
			pack_clk_cnt <= 0;
			pack_cnt <= 0;
			flag <= 0;

		end
		SEND_Valid_data: begin
			cam_data = $random;

			if (data_clk_cnt == 11*(293)) begin
				state <= SEND_EAV1;
				data_clk_cnt <= 0;
			end
			else begin
				data_clk_cnt <= data_clk_cnt + 1;
			end	

			if (!flag) begin
				if (pack_clk_cnt == 12) begin
					new_pack <= 1;

					pack_cnt <= pack_cnt + 1;
					pack_clk_cnt <= 0;
					flag <= 1;
				end
				else begin
					new_pack <= 0;
					pack_clk_cnt <= pack_clk_cnt + 1;
				end				
			end
			else begin
				if (pack_clk_cnt == 11) begin
					new_pack <= 1;

					pack_cnt <= pack_cnt + 1;
					pack_clk_cnt <= 0;
				end
				else begin
					new_pack <= 0;
					pack_clk_cnt <= pack_clk_cnt + 1;
				end							
			end

		end
		SEND_EAV1: begin
			// 1st vaild EAV: 0xFFF
			cam_data = 8'b11111111;

			// Count 12bit
			if (data_clk_cnt == 11) begin
				state <= SEND_EAV2;
				data_clk_cnt <= 0;
			end
			else begin
				data_clk_cnt <= data_clk_cnt + 1;
			end	
		end
		SEND_EAV2: begin
			// 2nd vaild SAV: 0x000
			cam_data = 0;

			// Count 12bit
			if (data_clk_cnt == 11) begin
				state <= SEND_EAV3;
				data_clk_cnt <= 0;
			end
			else begin
				data_clk_cnt <= data_clk_cnt + 1;
			end		
		end
		SEND_EAV3: begin
			// 3rd vaild SAV: 0x000
			cam_data = 0;

			// Count 12bit
			if (data_clk_cnt == 11) begin
				state <= SEND_EAV4;
				data_clk_cnt <= 0;
			end
			else begin
				data_clk_cnt <= data_clk_cnt + 1;
			end		
		end
		SEND_EAV4: begin
			if (data_clk_cnt == 0) begin
				cam_data = 8'b11111111;
			end
			else if (data_clk_cnt >= 1 && data_clk_cnt <= 2) begin
				cam_data = 0;
			end
			else if (data_clk_cnt >= 3 && data_clk_cnt <= 5) begin
				cam_data = 8'b11111111;
			end
			else if (data_clk_cnt == 6) begin
				cam_data = 0;
			end
			else if (data_clk_cnt == 7) begin
				cam_data = 8'b11111111;
			end
			else if (data_clk_cnt >= 8 && data_clk_cnt <= 11) begin
				cam_data = 0;
			end
			
			if (data_clk_cnt == 11) begin
				state <= BLANK;
				data_clk_cnt <= 0;
			end
			else begin
				data_clk_cnt <= data_clk_cnt + 1;
			end
		end
		BLANK: begin
			//if (data_clk_cnt == 11*30) begin
			if (data_clk_cnt == 11*30) begin
				state <= SEND_SAV1;
				data_clk_cnt <= 0;
			end
			else begin
				data_clk_cnt <= data_clk_cnt + 1;
			end
		end
		default: state <= SEND_SAV1;
	endcase
end

top inst (
	.imx_clkin(imx_clkin),
	.ref_clkin(ref_clkin),

	.imx_din(cam_data),
	.imx_hsync_in(),
	.imx_vsync_in()
);

initial
begin
  #(0.2*1000000) $stop;
end


endmodule
