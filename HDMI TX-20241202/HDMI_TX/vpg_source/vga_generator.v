module vga_generator(                                    
  input						clk,                
  input						reset_n,                                                
  output	reg				vga_hs,             
  output	reg				vga_vs,           
  output	reg				vga_de,
  output	reg	[7:0]		vga_r,
  output	reg	[7:0]		vga_g,
  output	reg	[7:0]		vga_b                                                 
);

//=======================================================
//  Signal declarations
//=======================================================
reg	[11:0]	h_count;
reg	[11:0]	v_count;
reg				h_act; 
reg				h_act_d;
reg				v_act; 
reg				pre_vga_de;
wire				h_max, hs_end, hr_start, hr_end;
wire				v_max, vs_end, vr_start, vr_end;
wire				v_act_14, v_act_24, v_act_34;

//=======================================================
//  Magic values for 720p
//=======================================================
parameter h_total = 12'd857;
parameter h_sync = 12'd61;
parameter h_start = 12'd119;
parameter h_end = 12'd839;

parameter v_total = 12'd524;
parameter v_sync = 12'd5;
parameter v_start = 12'd35;
parameter v_end = 12'd515;

//=======================================================
//  Structural coding
//=======================================================
assign h_max = h_count == h_total;
assign hs_end = h_count >= h_sync;
assign hr_start = h_count == h_start; 
assign hr_end = h_count == h_end;
assign v_max = v_count == v_total;
assign vs_end = v_count >= v_sync;
assign vr_start = v_count == v_start; 
assign vr_end = v_count == v_end;

//horizontal control signals
always @ (posedge clk or negedge reset_n)
begin
	if (!reset_n)
	begin
		h_act_d	<=	1'b0;
		h_count	<=	12'b0;
		vga_hs	<=	1'b1;
		h_act		<=	1'b0;
	end
	else
	begin
		h_act_d	<=	h_act;

		if (h_max)
			h_count	<=	12'b0;
		else
			h_count	<=	h_count + 12'b1;

		if (hs_end && !h_max)
			vga_hs	<=	1'b1;
		else
			vga_hs	<=	1'b0;

		if (hr_start)
			h_act		<=	1'b1;
		else if (hr_end)
			h_act		<=	1'b0;
	end
end

//vertical control signals
always@(posedge clk or negedge reset_n)
begin
	if(!reset_n)
	begin
		v_count		<=	12'b0;
		vga_vs		<=	1'b1;
		v_act			<=	1'b0;
	end
	else 
	begin		
		if (h_max)
		begin		  
			if (v_max)
				v_count	<=	12'b0;
			else
				v_count	<=	v_count + 12'b1;

			if (vs_end && !v_max)
				vga_vs	<=	1'b1;
			else
				vga_vs	<=	1'b0;

			if (vr_start)
				v_act <=	1'b1;
			else if (vr_end)
				v_act <=	1'b0;
		end
	end
end
	
//display enable and dummy pixels
always @(posedge clk or negedge reset_n)
begin
	if (!reset_n)
	begin
		vga_de		<=	1'b0;
	end
	else
	begin
		vga_de		<=	v_act && h_act;
		
		// Dummy pixels
		vga_r <= h_count;
		vga_g <= v_count;
		vga_b <= 12'd0;
	end
end	

endmodule