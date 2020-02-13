

module cw_openhpsdr (
  input               clk               ,
  input               clk_slow          ,
  input        [ 5:0] cmd_addr          ,
  input        [31:0] cmd_data          ,
  input               cmd_rqst          ,
  input               millisec_pulse    ,
  input               dot_key           ,
  input               dash_key          ,
  input               cwx               ,
  input               dot_key_debounced ,
  input               dash_key_debounced,
  output logic        cw_power_on         = 1'b0,
  output              cw_keydown
);



logic [9:0] cw_hang_time ;
logic       keyer_reverse; // reverse CW keyes if set
logic [5:0] keyer_speed  ; // CW keyer speed 0-60 WPM
logic [1:0] keyer_mode   ; // 00 = straight/external/bug, 01 = Mode A, 10 = Mode B
logic [7:0] keyer_weight ; // keyer weight 33-66
logic       keyer_spacing; // 0 = off, 1 = on

logic       keydown;
logic       hang_timer_not_zero;
logic [9:0] hang_timer = 10'd0;

always @(posedge clk) begin
  if (cmd_rqst) begin
    if (cmd_addr == 6'h10) begin
      cw_hang_time <= {cmd_data[31:24], cmd_data[17:16]};
    end else if (cmd_addr == 6'h0b) begin
      keyer_reverse <= cmd_data[22];
      keyer_speed <= cmd_data[13:8];
      keyer_mode <= cmd_data[15:14];
      keyer_weight <= cmd_data[6:0];
      keyer_spacing <= cmd_data[7];
    end
  end
end


iambic #(48) iambic_i (
  .clock       (clk_slow     ),
  .cw_speed    (keyer_speed  ),
  .iambic_mode (keyer_mode   ),
  .weight      (keyer_weight ),
  .letter_space(keyer_spacing),
  .dot_key     (dot_key      ),
  .dash_key    (dash_key     ),
  .CWX         (cwx          ),
  .paddle_swap (keyer_reverse),
  .keyer_out   (keydown      )
);

assign hang_timer_not_zero = |hang_timer;

always @(posedge clk) begin
  if (keydown) begin
    hang_timer <= cw_hang_time;
  end else if (millisec_pulse & hang_timer_not_zero) begin
    hang_timer <= hang_timer - 10'd1;
  end
end

assign cw_power_on = keydown | hang_timer_not_zero;
assign cw_keydown = keydown;


endmodule