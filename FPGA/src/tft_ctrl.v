module tft_ctrl
(
input wire tft_clk_9m , //����ʱ��,Ƶ��9MHz
input wire sys_rst_n , //ϵͳ��λ,�͵�ƽ��Ч
input wire [23:0] pix_data , //����ʾ����

output wire [23:0] rgb_tft , //TFT��ʾ����
output wire hsync , //TFT��ͬ���ź�
output wire vsync , //TFT��ͬ���ź�
output wire tft_clk , //TFT����ʱ��
output wire tft_de , //TFT����ʹ��
output wire tft_bl //TFT�����ź�

);

////
//\* Parameter and Internal Signal \//
////

//parameter define
parameter H_SYNC = 10'd41 , //��ͬ��
H_BACK = 10'd2 , //��ʱ�����
H_VALID = 10'd480 , //����Ч����
H_FRONT = 10'd2 , //��ʱ��ǰ��
H_TOTAL = 10'd525 ; //��ɨ������
parameter V_SYNC = 10'd10 , //��ͬ��
V_BACK = 10'd2 , //��ʱ�����
V_VALID = 10'd272 , //����Ч����
V_FRONT = 10'd2 , //��ʱ��ǰ��
V_TOTAL = 10'd286 ; //��ɨ������

//wire define
wire rgb_valid ; //VGA��Ч��ʾ����
wire pix_data_req ; //���ص�ɫ����Ϣ�����ź�

//reg define
reg [9:0] cnt_h ; //��ɨ�������
reg [9:0] cnt_v ; //��ɨ�������

////
//\* Main Code \//
////

//tft_clk,tft_de,tft_bl��TFT����ʱ�ӡ�����ʹ�ܡ������ź�
assign tft_clk = tft_clk_9m ;
assign tft_de = rgb_valid ;
assign tft_bl = sys_rst_n ;

//cnt_h:��ͬ���źż�����
always@(posedge tft_clk_9m or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		cnt_h <= 10'd0 ;
	else if(cnt_h == H_TOTAL - 1'd1)
		cnt_h <= 10'd0 ;
	else
		cnt_h <= cnt_h + 1'd1 ;

//hsync:��ͬ���ź�
assign hsync = (cnt_h <= H_SYNC - 1'd1) ? 1'b1 : 1'b0 ;

//cnt_v:��ͬ���źż�����
always@(posedge tft_clk_9m or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		cnt_v <= 10'd0 ;
	else if((cnt_v == V_TOTAL - 1'd1) && (cnt_h == H_TOTAL-1'd1))
		cnt_v <= 10'd0 ;
	else if(cnt_h == H_TOTAL - 1'd1)
		cnt_v <= cnt_v + 1'd1 ;
	else
		cnt_v <= cnt_v ;

//vsync:��ͬ���ź�
assign vsync = (cnt_v <= V_SYNC - 1'd1) ? 1'b1 : 1'b0 ;

//rgb_valid:VGA��Ч��ʾ����
assign rgb_valid = (((cnt_h >= H_SYNC + H_BACK)
&& (cnt_h < H_SYNC + H_BACK + H_VALID))
&&((cnt_v >= V_SYNC + V_BACK)
&& (cnt_v < V_SYNC + V_BACK + V_VALID)))
? 1'b1 : 1'b0;

//pix_data_req:���ص�ɫ����Ϣ�����ź�,��ǰrgb_valid�ź�һ��ʱ������
assign pix_data_req = (((cnt_h >= H_SYNC + H_BACK - 1'b1)
&& (cnt_h < H_SYNC + H_BACK + H_VALID - 1'b1))
&&((cnt_v >= V_SYNC + V_BACK)
&& (cnt_v < V_SYNC + V_BACK + V_VALID)))
? 1'b1 : 1'b0;

//rgb_tft:������ص�ɫ����Ϣ
assign rgb_tft = (rgb_valid == 1'b1) ? pix_data : 24'b0 ;

endmodule