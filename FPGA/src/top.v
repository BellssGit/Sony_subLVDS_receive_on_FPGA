module top (
	input imx_clkin,
	input ref_clkin,
	
	input [7:0] imx_din,
	input imx_hsync_in,
	input imx_vsync_in,
	
output wire [23:0]rgb_tft ,
output wire hsync ,
output wire vsync ,
output wire tft_clk , 
output wire tft_de , 
output wire tft_bl
);

wire [31:0] imx_dout;
wire sclk,interface_rdy;

wire sys_rstn,line_sync_out;

wire sys_clk = ref_clkin;

watch_dog this_is_a_dog(
    .clk(ref_clkin),
    .rst_cnt(line_sync_out),

    .rstn(sys_rstn)
);

imx_interface sensor_inst (
	.alignwd(1'b0), 
	.clkin(imx_clkin), 
	.ready(interface_rdy), 
	.sclk(sclk), 
	.start(1'b1), 
    .sync_clk(ref_clkin), 
	.sync_reset(~sys_rstn), 
	.datain(imx_din), 
	.q(imx_dout)
);

wire fifo_empty;
reg fifo_rd;

wire [95:0] fifo_dout /* synthesis syn_preserve=1 */;

imx_capture imx_capture_inst (
	.clk(sclk),
	.fifo_rd_clk(sys_clk),
	.rst_n(sys_rstn),
	
	.ddr_rdy(interface_rdy),

	.datain(imx_dout),

	.line_sync_out(line_sync_out),

	.fifo_rd(fifo_rd),
	.fifo_dout(fifo_dout),
	.fifo_empty(fifo_empty),
	.fifo_full()
);

always @(posedge sys_clk ) begin
	if (!fifo_empty) begin
		fifo_rd <= 1;
	end
	else begin
		fifo_rd <= 0;
	end
end

reg [95:0] d_buf = 0;
reg [3:0] pix_skip_cnt = 0;
reg [3:0] line_skip_cnt = 0;
reg get_line = 0;

always @(posedge sys_clk ) begin
	if (pix_skip_cnt == 7 && get_line) begin
		d_buf <= fifo_dout;
		pix_skip_cnt <= 0;
	end
	else if(get_line) begin
		pix_skip_cnt <= pix_skip_cnt + 1;
	end
end

// Display test, but not working :(

/*
wire disp_clock;
display_clock display_clock_inst (.CLKI(sys_clk), .CLKOP(disp_clock));


reg [23:0] disp_buffer;
reg [3:0] d_set = 0;


always @(posedge disp_clock ) begin
	if (line_skip_cnt >= 7) begin
		get_line <= 1;
		line_skip_cnt <= 0;
	end
	else begin
		line_skip_cnt <= line_skip_cnt + 1;
		get_line <= 0;
	end
end

always @(posedge disp_clock ) begin
	if (d_set == 0) begin
		disp_buffer <= {d_buf[95:88],d_buf[95:88],d_buf[95:88]};
		d_set <= d_set + 1;
	end
	else if (d_set == 1) begin
		disp_buffer <= {d_buf[83:76],d_buf[83:76],d_buf[83:76]};
		d_set <= d_set + 1;
	end
	else if (d_set == 2) begin
		disp_buffer <= {d_buf[71:64],d_buf[71:64],d_buf[71:64]};
		d_set <= d_set + 1;
	end
	else if (d_set == 3) begin
		disp_buffer <= {d_buf[59:52],d_buf[59:52],d_buf[59:52]};
		d_set <= d_set + 1;
	end
	else if (d_set == 4) begin
		disp_buffer <= {d_buf[47:40],d_buf[47:40],d_buf[47:40]};
		d_set <= d_set + 1;
	end
	else if (d_set == 5) begin
		disp_buffer <= {d_buf[35:28],d_buf[35:28],d_buf[35:28]};
		d_set <= d_set + 1;
	end
	else if (d_set == 6) begin
		disp_buffer <= {d_buf[23:16],d_buf[23:16],d_buf[23:16]};
		d_set <= d_set + 1;
	end
	else if (d_set == 7) begin
		disp_buffer <= {d_buf[11:4],d_buf[11:4],d_buf[11:4]};
		d_set <= 0;
	end
	
end


tft_ctrl tft_inst(
	.tft_clk_9m(disp_clock),
	.sys_rst_n(1'b1),
	.pix_data(disp_buffer),

	.rgb_tft(rgb_tft),
	.hsync(hsync),
	.vsync(vsync),
	.tft_clk(tft_clk),
	.tft_de(tft_de),
	.tft_bl(tft_bl)
);
*/

endmodule