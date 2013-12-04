`include "screen_settings.vh"

module display_out(
		   input logic 	      clk_50MHz, clk_33MHz, rst,
		   input logic 	      enable,
		   input logic 	      vram_we,
		   input logic [9:0]  vram_x,
		   input logic [23:0] vram_out,
		   input logic [9:0]  y_tl, 
		   input logic [9:0]  dis_h,
		   output logic [8:0] vram_y, 
		   output logic       vram_re,
		   output logic       blk,
		   output logic [7:0] VGA_R, VGA_G, VGA_B,
		   output logic       VGA_HS, VGA_VS,
		   output logic       VGA_CLK, VGA_BLANK_N, VGA_SYNC_N);
   
   /* Interal Lines */
   logic [9:0] 			       x, y;
   
   logic 			       hs, vs;

   logic [31:0] 			       mult_y;
   logic [31:0] 			       mult_y_next;
   
   logic [9:0] 		       int_y;
   logic [9:0] 		       int_y_next;

   logic [9:0] 			       y_tl_hold, dis_h_hold;

   logic [23:0] 		       stored_color;
   
   logic 			       v_blk, h_blk;
   
   /* VGA module; from Prof Bill Nace */
   vga v(.HS(hs),
	 .VS(vs),
	 .CLOCK_50(clk_50MHz),
	 .reset(rst),
	 .v_blank(v_blk),
	 .h_blank(h_blk),
	 .row(y),
	 .col(x));
   
   assign blk = v_blk | h_blk;
   
   /* Row Store memory */
   row_hold rh(.rdclock(clk_50MHz),
	       .wrclock(clk_33MHz),
	       .rdaddress(x),
	       .wraddress(vram_x),
	       .q(stored_color),
	       .data(vram_out),
	       .wren(vram_we));
   
   /* Assign VGA lines */
   assign VGA_CLK = ~clk_50MHz;
   assign VGA_BLANK_N = ~blk;
   assign VGA_SYNC_N = 1'b0;
   
   assign VGA_HS = hs;
   assign VGA_VS = vs;
   
   assign VGA_R = ((enable) ? stored_color[7:0] : 8'd0);
   assign VGA_G = ((enable) ? stored_color[15:8] : 8'd0);
   assign VGA_B = ((enable) ? stored_color[23:16] : 8'd0);   

   /* GPU param hold registers */
   always_ff @(posedge clk_50MHz, posedge rst) begin
      if (rst) begin
	 dis_h_hold <= 10'd0;
	 y_tl_hold <= 10'd0;
      end
      else begin
	 dis_h_hold <= dis_h;
	 y_tl_hold <= y_tl;
      end // else: !if(rst)
   end // always_ff @
   
   /* Retrieving and Pixel buffer logic */
   always_comb begin
      /* Defaults */
      vram_re = 1'b0;
      
      /* Calculate and translate y and the next y */
      mult_y = (dis_h_hold * y);
      mult_y_next = (dis_h_hold * (y + 10'd1));
      
      int_y = ((mult_y / `SCREEN_H) + y_tl_hold);
      int_y_next = ((mult_y_next / `SCREEN_H) + y_tl_hold);

		/* Set the output y */
		vram_y = int_y[8:0];

      /* If were done with this row, assert a read to get the next one (if y changes) */
      if ((x == 10'd0) & ~v_blk & (int_y != int_y_next)) begin
	 vram_re = 1'b1;
      end
      
   end // always_comb
   
endmodule // display_out
