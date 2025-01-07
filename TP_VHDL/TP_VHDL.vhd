library ieee;
use ieee.std_logic_1164.all;

entity TP_VHDL is
	port (
		i_clk : in std_logic;
		i_rst_n : in std_logic;
		o_led : out std_logic_vector (7 downto 0)
	);
end entity TP_VHDL;

architecture rtl of TP_VHDL is
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