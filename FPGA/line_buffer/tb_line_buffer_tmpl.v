//Verilog testbench template generated by SCUBA Diamond (64-bit) 3.13.0.56.2
`timescale 1 ns / 1 ps
module tb;
    reg [95:0] Data = 96'b0;
    reg WrClock = 0;
    reg RdClock = 0;
    reg WrEn = 0;
    reg RdEn = 0;
    reg Reset = 0;
    reg RPReset = 0;
    wire [95:0] Q;
    wire Empty;
    wire Full;

    integer i0 = 0, i1 = 0, i2 = 0, i3 = 0, i4 = 0, i5 = 0, i6 = 0, i7 = 0, i8 = 0, i9 = 0;

    GSR GSR_INST (.GSR(1'b1));
    PUR PUR_INST (.PUR(1'b1));

    line_buffer u1 (.Data(Data), .WrClock(WrClock), .RdClock(RdClock), .WrEn(WrEn), 
        .RdEn(RdEn), .Reset(Reset), .RPReset(RPReset), .Q(Q), .Empty(Empty), 
        .Full(Full)
    );

    initial
    begin
       Data <= 0;
      #100;
      @(Reset == 1'b0);
      for (i1 = 0; i1 < 515; i1 = i1 + 1) begin
        @(posedge WrClock);
        #1  Data <= Data + 1'b1;
      end
    end
    always
    #5.00 WrClock <= ~ WrClock;

    always
    #5.00 RdClock <= ~ RdClock;

    initial
    begin
       WrEn <= 1'b0;
      #100;
      @(Reset == 1'b0);
      for (i4 = 0; i4 < 515; i4 = i4 + 1) begin
        @(posedge WrClock);
        #1  WrEn <= 1'b1;
      end
       WrEn <= 1'b0;
    end
    initial
    begin
       RdEn <= 1'b0;
      @(Reset == 1'b0);
      @(WrEn == 1'b1);
      @(WrEn == 1'b0);
      for (i5 = 0; i5 < 515; i5 = i5 + 1) begin
        @(posedge RdClock);
        #1  RdEn <= 1'b1;
      end
       RdEn <= 1'b0;
    end
    initial
    begin
       Reset <= 1'b1;
      #100;
       Reset <= 1'b0;
    end
    initial
    begin
       RPReset <= 1'b1;
      #100;
       RPReset <= 1'b0;
    end
endmodule