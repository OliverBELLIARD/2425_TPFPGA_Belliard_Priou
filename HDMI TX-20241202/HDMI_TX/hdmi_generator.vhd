library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_generator is
	generic (
		-- Resolution
		h_res 	: natural := 720;
		v_res 	: natural := 480;

		-- Timings magic values (480p)
		h_sync	: natural := 61;
		h_fp	: natural := 58;
		h_bp	: natural := 18;

		v_sync	: natural := 5;
		v_fp	: natural := 30;
		v_bp	: natural := 9
	);
	port (
		i_clk  		: in std_logic;
    	i_reset_n 	: in std_logic;
    	o_hdmi_hs   : out std_logic;
    	o_hdmi_vs   : out std_logic;
    	o_hdmi_de   : out std_logic;

		o_pixel_en : out std_logic;
		o_pixel_address : out natural range 0 to (h_res * v_res - 1);
		o_x_counter : out natural range 0 to (h_res - 1);
		o_y_counter : out natural range 0 to (v_res - 1);
		o_new_frame : out std_logic
  	);
end hdmi_generator;

architecture rtl of hdmi_generator is

begin

end architecture rtl;
