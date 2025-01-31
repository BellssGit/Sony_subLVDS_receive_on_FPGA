module watch_dog (
    input clk,
    input rst_cnt,

    output rstn
);

reg [15:0] cnt = 0; // for sims only

always @(posedge clk ) begin
    if (rst_cnt || cnt > 1050) begin
        cnt <= 0;
    end
    else begin
        cnt <= cnt + 1;
    end
end

assign rstn = (cnt > 1000) ? 0:1;

endmodule