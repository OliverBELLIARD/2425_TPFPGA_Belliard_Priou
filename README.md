# TP_FPGA_Belliard_Priou
TP de réalisation d'un petit projet employant le HDMI pour l'affichage du logo de l'ENSEA

On utilise l'outil [GitHub Desktop](https://github.com/shiftkey/desktop?tab=readme-ov-file#installation-via-package-manager) permettant de gérer graphiquement notre repo facilement.

## Mapping des pins à utiliser : 

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

Chenillard
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
