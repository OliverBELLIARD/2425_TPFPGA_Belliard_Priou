# TP_FPGA_Belliard_Priou

TP de réalisation d'un petit projet employant le HDMI pour l'affichage du logo de l'ENSEA

On utilise l'outil [GitHub Desktop](https://github.com/shiftkey/desktop?tab=readme-ov-file#installation-via-package-manager) permettant de gérer graphiquement notre repo facilement.

# 1 - Tutoriel Quartus

## 1.3 - Fichier de contrainte

Ici nous cherchons à assigner l'entité que l'on vient de créer aux sorites disponibles sur notre carte. Dans ce cas nous allons avoir besoin d'une led et d'un switch.  
On peut alors trouver le détail des pins qu'on peut utiliser ou non dans le Pin Mapper disponible sur Quartus.  
Pour savoir quels pins sont reliés à nos leds nous allons avoir besoin de la datasheet 
## Mapping des pins à utiliser

![Pins_LEDs](https://github.com/user-attachments/assets/2a620267-1293-4109-8eb4-644c1c29cd8f)

![Clocks](https://github.com/user-attachments/assets/47d07cc7-b699-41c0-b6c7-50c553ca662e)

## 1.6 Faire clignoter une LED

RTL Viewer
![image](https://github.com/user-attachments/assets/f5b64e9c-50aa-4916-832e-c871bfd2ff7c)

Clignottement de la LED à 50 MHz :

```vhdl
library ieee;
  use ieee.std_logic_1164.all;

entity TP_VHDL is
  port (
    i_clk   : in  std_logic;
    i_rst_n : in  std_logic;
    o_led   : out std_logic
  );
end entity;

architecture rtl of TP_VHDL is
  signal r_led : std_logic := '0';
begin
  process (i_clk, i_rst_n)
  begin
    if (i_rst_n = '0') then
      r_led <= '0';
    elsif (rising_edge(i_clk)) then
      r_led <= not r_led;
    end if;
  end process;
  o_led <= r_led;
end architecture;
```

Description matérielle pour faire clignoter la LED à 10 Hz :

```vhdl
library ieee;
  use ieee.std_logic_1164.all;

entity TP_VHDL is
  port (
    i_clk   : in  std_logic;
    i_rst_n : in  std_logic;
    o_led   : out std_logic
  );
end entity;

architecture rtl of TP_VHDL is
  signal r_led : std_logic := '0';
begin
  process (i_clk, i_rst_n)
    variable counter : natural range 0 to 5000000 := 0;
  begin
    if (i_rst_n = '0') then
      counter := 0;
      r_led <= '0';
    elsif (rising_edge(i_clk)) then
      if (counter = 5000000) then
        counter := 0;
        r_led <= not r_led; -- Inverse l'état de la LED
      else
        counter := counter + 1;
      end if;
    end if;
  end process;
  
  o_led <= r_led;
end architecture rtl;
```

## 1.7 Chenillard

Notre chenillard :

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity TP_FPGA is
 port (
  i_clk : in std_logic;
  i_rst_n : in std_logic;
  o_led : out std_logic_vector (7 downto 0)
 );
end entity TP_FPGA;

architecture rtl of TP_FPGA is
 signal r_led : std_logic_vector (7 downto 0) := (others => '0'); -- Initialise tout notre vecteur à 0
begin
 process(i_clk, i_rst_n)
  variable counter : natural range 0 to 5000000 := 0;
  variable i : natural range 0 to 7 := 0; -- Initialisation de l'index
 begin 
  if (i_rst_n = '0') then -- Réinitialise tout
   counter := 0;
   r_led <= (others => '0');
   i := 0;
  elsif (rising_edge(i_clk)) then
   if (counter = 5000000) then
    counter := 0;
    if i = 7 then
     r_led <= (others => '0');
     r_led(0) <= '1';
    else
     r_led <= r_led(6 downto 0) & '0'; -- Décale les LEDs vers la gauche
    end if;
    i := (i + 1) mod 8; -- Passe à la led suivante
   else
    counter := counter + 1;
   end if;
  end if;
 end process;
 
 o_led <= r_led;
end architecture rtl;
```
# 2 Petit projet : Bouncing ENSEA Logo
## 2.1 Contrôleur HDMI
Le composant `hdmi_generator.vhd` est complété de la façon suivante :
```vhdl
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
```
Nous avons codé un Testbench qui gère le signal d'orloge et le signal de reset pour observer les signaux en sortie :
```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_hdmi_generator is
-- Pas de ports dans un testbench
end entity;

architecture behavior of tb_hdmi_generator is
  -- Composant à tester
  component hdmi_generator is
    generic (
      h_res  : natural := 720;
      v_res  : natural := 480;
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
      o_pixel_address : out natural;
      o_x_counter     : out natural;
      o_y_counter     : out natural;
      o_new_frame     : out std_logic
    );
  end component;

  -- Constantes du test
  constant CLK_PERIOD : time := 20 ns; -- 50 MHz horloge

  -- Signaux internes
  signal i_clk           : std_logic := '0';
  signal i_reset_n       : std_logic := '1';
  signal o_hdmi_hs       : std_logic;
  signal o_hdmi_vs       : std_logic;
  signal o_hdmi_de       : std_logic;
  signal o_pixel_en      : std_logic;
  signal o_pixel_address : natural;
  signal o_x_counter     : natural;
  signal o_y_counter     : natural;
  signal o_new_frame     : std_logic;

begin
  -- Instance du composant à tester
  uut: hdmi_generator
    generic map (
      h_res  => 720,
      v_res  => 480,
      h_sync => 61,
      h_fp   => 58,
      h_bp   => 18,
      v_sync => 5,
      v_fp   => 30,
      v_bp   => 9
    )
    port map (
      i_clk           => i_clk,
      i_reset_n       => i_reset_n,
      o_hdmi_hs       => o_hdmi_hs,
      o_hdmi_vs       => o_hdmi_vs,
      o_hdmi_de       => o_hdmi_de,
      o_pixel_en      => o_pixel_en,
      o_pixel_address => o_pixel_address,
      o_x_counter     => o_x_counter,
      o_y_counter     => o_y_counter,
      o_new_frame     => o_new_frame
    );

  -- Génération d'horloge
  clock_process: process
  begin
    while True loop
      i_clk <= '0'; wait for 5 ns;
      i_clk <= '1'; wait for 5 ns;
    end loop;
  end process;

  -- Processus de test
  stimulus_process: process
  begin
    -- Initialisation
    i_reset_n <= '0';
    wait for 100 ns; -- Temps pour initier le reset
    i_reset_n <= '1';

    -- Simulation pour quelques cycles
    wait for 10 ms; -- Temps pour tester les lignes et synchronisations

    -- Fin du test
    wait;
  end process;

end architecture;
```
Nous avons simulé notre `hdmi_generator.vhd` avec notre testbench `tb_hdmi_generator` sur [ModelSim](https://www.intel.com/content/www/us/en/software-kit/750368/modelsim-intel-fpgas-standard-edition-software-version-18-1.html) :  
  
![image](https://github.com/user-attachments/assets/ce3d4ace-85ba-4610-a705-59721d3552cf)

Sur cette première figure on vérifie que `o_y_counter` s'incrémente correctement jusqu'à `v_res` qui vaut 480.

  ![image](https://github.com/user-attachments/assets/26169508-c66d-4ab7-ae52-ccabab887317)


