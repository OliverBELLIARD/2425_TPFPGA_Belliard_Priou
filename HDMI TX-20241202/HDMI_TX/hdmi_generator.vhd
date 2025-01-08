library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity hdmi_generator is
  generic (
    -- Resolution
    h_res  : natural := 720;
    v_res  : natural := 480;

    -- Timings magic values (480p)
    h_sync : natural := 61;
    h_fp   : natural := 58;
    h_bp   : natural := 18;

    v_sync : natural := 5;
    v_fp   : natural := 30;
    v_bp   : natural := 9
  );
  port (
    i_clk           : in  std_logic;
    i_reset_n       : in  std_logic;
    o_hdmi_hs       : out std_logic;
    o_hdmi_vs       : out std_logic;
    o_hdmi_de       : out std_logic;

    o_pixel_en      : out std_logic;
    o_pixel_address : out natural range 0 to (h_res * v_res - 1);
    o_x_counter     : out natural range 0 to (h_res - 1);
    o_y_counter     : out natural range 0 to (v_res - 1);
    o_new_frame     : out std_logic
  );
end entity;

architecture rtl of hdmi_generator is
	signal h_count : natural range 0 to (h_res + h_sync + h_bp + h_fp - 1) := 0;
	signal h_active : std_logic := '0';
  
  begin
	-- Processus pour gérer le compteur horizontal et le signal de synchronisation
	process (i_clk, i_reset_n)
	begin
	  if i_reset_n = '0' then
		h_count <= 0;
		h_active <= '0';
	  elsif rising_edge(i_clk) then
		if h_count = h_res + h_sync + h_bp + h_fp - 1 then
		  h_count <= 0; -- Réinitialisation du compteur horizontal
		else
		  h_count <= h_count + 1;
		end if;
  
		-- Définir le signal actif horizontal (zone active)
		if h_count < h_res then
		  h_active <= '1';
		else
		  h_active <= '0';
		end if;
	  end if;
	end process;
  
	-- Génération du signal de synchronisation horizontale (HS)
	o_hdmi_hs <= '0' when (h_count >= h_res + h_bp and h_count < h_res + h_bp + h_sync) else '1';
  
	-- Attribution des signaux auxiliaires
	o_hdmi_de <= h_active;
	o_pixel_en <= h_active; -- Activer les pixels uniquement dans la zone active
	o_x_counter <= h_count when h_active = '1' else 0;
end architecture;
