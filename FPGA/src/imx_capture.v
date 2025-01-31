module imx_capture (
	input clk,
	input fifo_rd_clk,
	input rst_n,

	input ddr_rdy,
	input [31:0] datain,

	output line_sync_out,
	output data_vaild,

	input fifo_rd,
	output [95:0] fifo_dout,
	output fifo_empty,
	output fifo_full
);

reg [47:0] channel_0_temp;
reg [47:0] channel_1_temp;
reg [47:0] channel_2_temp;
reg [47:0] channel_3_temp;
reg [47:0] channel_4_temp;
reg [47:0] channel_5_temp;
reg [47:0] channel_6_temp;
reg [47:0] channel_7_temp;

parameter SAV_Valid_12b = {12'hfff, 12'h000, 12'h000, 12'h800};
parameter EAV_Valid_12b = {12'hfff, 12'h000, 12'h000, 12'h9d0};
parameter SAV_Invalid_12b = {12'hfff, 12'h000, 12'h000, 12'hab0};
parameter EAV_Invalid_12b = {12'hfff, 12'h000, 12'h000, 12'hb60};

reg vaild_line_sync = 0 /* synthesis syn_preserve=1 */; // pre assign value only for simulation
reg invaild_line_sync = 0 /* synthesis syn_preserve=1 */; // pre assign value only for simulation

assign line_sync_out = vaild_line_sync || invaild_line_sync;
assign data_vaild = vaild_line_sync;

reg [1:0] pix_clk_cnt;

reg fifo_we;
reg fifo_selector, fifo_need_switch_n;

reg ahead_one_beat_done;
reg ahead_one_beat_cnt;

always @(posedge clk ) begin
	// Shift registers
	channel_0_temp <= {channel_0_temp[43:0], datain[0],datain[8],datain[16],datain[24]};
	channel_1_temp <= {channel_1_temp[43:0], datain[1],datain[9],datain[17],datain[25]};
	channel_2_temp <= {channel_2_temp[43:0], datain[2],datain[10],datain[18],datain[26]};
	channel_3_temp <= {channel_3_temp[43:0], datain[3],datain[11],datain[19],datain[27]};
	channel_4_temp <= {channel_4_temp[43:0], datain[4],datain[12],datain[20],datain[28]};
	channel_5_temp <= {channel_5_temp[43:0], datain[5],datain[13],datain[21],datain[29]};
	channel_6_temp <= {channel_6_temp[43:0], datain[6],datain[14],datain[22],datain[30]};
	channel_7_temp <= {channel_7_temp[43:0], datain[7],datain[15],datain[23],datain[31]};
end

always @(posedge clk ) begin
    if (!ddr_rdy) begin
		vaild_line_sync <= 0; fifo_we <= 0; fifo_selector <= 0; fifo_need_switch_n <= 0;
	end
	else begin
		if (channel_0_temp == SAV_Valid_12b) begin
			vaild_line_sync <= 1;

			fifo_need_switch_n <= 0;
		end
		else if (channel_0_temp == EAV_Valid_12b) begin
			vaild_line_sync <= 0;
			
			if (!fifo_need_switch_n) begin
				fifo_selector <= ~fifo_selector;
				fifo_need_switch_n <= 1;
			end

		end

		if (channel_0_temp == SAV_Invalid_12b) begin
			invaild_line_sync <= 1;
		end
		else if(channel_0_temp == EAV_Invalid_12b) begin
			invaild_line_sync <= 0;
		end
	end

	// ahead one beat at the very first capture
	if (ahead_one_beat_cnt && vaild_line_sync) begin
		ahead_one_beat_done <= 1;
	end
	else if(vaild_line_sync) begin
		ahead_one_beat_cnt <= ahead_one_beat_cnt + 1;
	end
	else begin
		ahead_one_beat_cnt <= 0;
		ahead_one_beat_done <= 0;
	end

/*
	if (!ahead_one_beat_done && vaild_line_sync) begin
		if (pix_clk_cnt == 0) begin
			fifo_we <= 1;
			pix_clk_cnt <= pix_clk_cnt + 1;
		end
		else if (pix_clk_cnt == 1) begin
			pix_clk_cnt <= 0;
			fifo_we <= 0;
		end
		else begin 
			pix_clk_cnt <= pix_clk_cnt + 1;
		end		
	end
*/
	if (vaild_line_sync) begin
		if (pix_clk_cnt == 1) begin
			fifo_we <= 1;
			pix_clk_cnt <= pix_clk_cnt + 1;
		end
		else if (pix_clk_cnt == 2) begin
			pix_clk_cnt <= 0;
			fifo_we <= 0;
		end
		else begin
			pix_clk_cnt <= pix_clk_cnt + 1;
		end
	end
	else begin
		pix_clk_cnt <= 0;
		fifo_we <= 0;
	end

end

/*----DEBUG----*/

reg [15:0] pix_cnt = 0 /* synthesis syn_preserve=1 */;

always @(posedge clk ) begin
	if (vaild_line_sync) begin
		if (fifo_we) begin
			pix_cnt <= pix_cnt + 1;
		end		
	end
	else begin
		pix_cnt <= 0;
	end
end

/*----DEBUG----*/


// Ping-Pong FIFO

wire [95:0] fifo_din;
assign fifo_din = {channel_7_temp[11:0], channel_6_temp[11:0], channel_5_temp[11:0],
	channel_4_temp[11:0], channel_3_temp[11:0], channel_2_temp[11:0], channel_1_temp[11:0],channel_0_temp[11:0]};

wire fifo1_we,fifo2_we;
wire fifo1_rd,fifo2_rd;
wire fifo1_empty,fifo2_empty;
wire fifo1_full,fifo2_full;
wire [95:0] fifo2_dout;
wire [95:0] fifo1_dout;

// assign fifo input signal
assign fifo1_we = fifo_selector ? 0 : fifo_we;
assign fifo2_we = fifo_selector ? fifo_we : 0;

assign fifo1_rd = fifo_selector ? fifo_rd : 0;
assign fifo2_rd = fifo_selector ? 0 : fifo_rd;

// assign fifo output signal

// note the empty and dout is oppsite because
// the fifo_selector is indicating which fifo is WRITING but not reading
assign fifo_empty = fifo_selector ? fifo1_empty : fifo2_empty;
assign fifo_dout = fifo_selector ? fifo1_dout : fifo2_dout;

assign fifo_full = fifo_selector ? fifo2_full : fifo1_full;

line_buffer line_buffer_inst_1 (
	.Data(fifo_din), 
	.WrClock(clk), 
	.RdClock(fifo_rd_clk), 
	.WrEn(fifo1_we),
	.RdEn(fifo1_rd), 
    
	.Reset(~rst_n), 
	.RPReset(~rst_n), 

	.Q(fifo1_dout), 
	.Empty(fifo1_empty), 
	.Full(fifo1_full)
);

line_buffer line_buffer_inst_2 (
	.Data(fifo_din), 
	.WrClock(clk), 
	.RdClock(fifo_rd_clk), 
	.WrEn(fifo2_we), 
	.RdEn(fifo2_rd), 

    .Reset(~rst_n), 
	.RPReset(~rst_n), 
	
	.Q(fifo2_dout), 
	.Empty(fifo2_empty), 
	.Full(fifo2_full)
);

endmodule