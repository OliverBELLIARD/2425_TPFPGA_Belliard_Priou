library ieee;
  use ieee.std_logic_1164.all;

entity TP_VHDL is
  port (
    sw  : in  std_logic_vector(3 downto 0);
    led : out std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of TP_VHDL is
begin
  led <= sw;
end architecture;
