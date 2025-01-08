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

		-- log2(720*480) = 18.4
		o_pixel_en : out std_logic;
		o_pixel_address : out natural range 0 to (h_res * v_res - 1);
		o_x_counter : out natural range 0 to (h_res - 1);
		o_y_counter : out natural range 0 to (v_res - 1);
		o_new_frame : out std_logic
  	);
end hdmi_generator;

architecture rtl of hdmi_generator is
	-- Signal declarations
	signal h_count   : unsigned(11 downto 0);
	signal v_count   : unsigned(11 downto 0);
	signal h_act     : std_logic;
	signal v_act     : std_logic;

	constant h_start: natural := h_sync+h_fp;	-- 119
	constant h_end  : natural := h_res+h_start;	-- 839
	constant h_total: natural := h_end+h_bp;	-- 857

	constant v_start: natural := v_sync+v_fp;	-- 35
	constant v_end  : natural := v_res+v_start;	-- 515
	constant v_total: natural := v_end+v_bp;	-- 524

	constant pixel_number : natural := h_res*v_res;

	signal r_pixel_counter : natural range 0 to ((h_res*v_res) - 1) := 0;
	signal r_x_counter : natural range 0 to (h_res - 1) := 0;
	signal r_y_counter : natural range 0 to (v_res - 1) := 0;
begin
	-- Horizontal control signals
	process(i_clk, i_reset_n)
	begin
		if (i_reset_n = '0') then
			h_count   <= (others => '0');
			o_hdmi_hs    <= '1';
			h_act     <= '0';
		elsif rising_edge(i_clk) then
			if (to_integer(h_count) = h_total) then
				h_count <= (others => '0');
			else
				h_count <= h_count + 1;
			end if;

			if ((h_count >= h_sync) and (h_count /= h_total)) then
				o_hdmi_hs <= '1';
			else
				o_hdmi_hs <= '0';
			end if;

			if (to_integer(h_count) = h_start) then
				h_act <= '1';
			elsif (to_integer(h_count) = h_end) then
				h_act <= '0';
			end if;
		end if;
	end process;

	-- Vertical control signals
	process(i_clk, i_reset_n)
	begin
		if (i_reset_n = '0') then
			v_count <= (others => '0');
			o_hdmi_vs  <= '1';
			v_act   <= '0';
		elsif rising_edge(i_clk) then
			if (to_integer(h_count) = h_total) then
				if (to_integer(v_count) = v_total) then
					v_count <= (others => '0');
				else
					v_count <= v_count + 1;
				end if;
	
				if ((v_count >= v_sync) and (v_count /= v_total)) then
					o_hdmi_vs <= '1';
				else
					o_hdmi_vs <= '0';
				end if;

				if (to_integer(v_count) = v_start) then
					v_act <= '1';
				elsif (to_integer(v_count) = v_end) then
					v_act <= '0';
				end if;
			end if;
		end if;
	end process;
	
	-- Display enable and dummy pixels
	process(i_clk, i_reset_n)
	begin
		if (i_reset_n = '0') then
			o_hdmi_de <= '0';
		elsif rising_edge(i_clk) then
			o_hdmi_de <= v_act and h_act;
		end if;
	end process;

	-- Generate address
	o_pixel_en <= '1' when (v_act = '1') and (h_act = '1') else '0';
	process(i_clk, i_reset_n)
	begin
		if (i_reset_n = '0') then
			r_pixel_counter <= 0;
		elsif (rising_edge(i_clk)) then
			if ((v_act = '1') and (h_act = '1')) then
				-- x/y counter
				if (r_x_counter = h_res - 1) then
					r_x_counter <= 0;
					
					if (r_y_counter = v_res -1) then
						r_y_counter <= 0;
					else
						r_y_counter <= r_y_counter + 1;
					end if;
				else
					r_x_counter <= r_x_counter + 1;
				end if;
			
				-- absolute pixel counter
				if (r_pixel_counter = pixel_number - 1) then
					r_pixel_counter <= 0;
				else
					r_pixel_counter <= r_pixel_counter + 1;
				end if;
			end if;
		end if;
	end process;
	o_pixel_address <= r_pixel_counter;
	
	o_x_counter <= r_x_counter;
	o_y_counter <= r_y_counter;
	
	o_new_frame <= '1' when (r_pixel_counter = pixel_number - 1) else '0';
end architecture rtl;
