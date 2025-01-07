library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity TP_VHDL is
  port (
    i_clk   : in  std_logic;
    i_rst_n : in  std_logic;
    o_led   : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of TP_VHDL is
  signal r_led : std_logic_vector(7 downto 0) := (others => '0');
begin
  process (i_clk, i_rst_n)
    variable counter : natural range 0 to 5000000 := 0;
    variable crawler : natural range 1 to 128 := 1;
  begin
    if (i_rst_n = '0') then
      counter := 0;
      r_led <= (others => '0');
    elsif (rising_edge(i_clk)) then
      if (counter = 5000000) then
        counter := 0;
		  
        if (crawler = 128) then
          crawler := 1;
		 else
			 crawler := crawler * 2;
        end if;
		  
        r_led <= std_logic_vector(to_unsigned(crawler, r_led'length));
      else
        counter := counter + 1;
      end if;
    end if;
  end process;
  
  o_led <= r_led;
end architecture rtl;
