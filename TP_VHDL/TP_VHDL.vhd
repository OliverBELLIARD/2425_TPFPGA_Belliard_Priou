library ieee;
  use ieee.std_logic_1164.all;

entity TP_VHDL is
  port (
    sw  : in  std_logic;
    led : out std_logic
  );
end entity;

architecture rtl of TP_VHDL is
begin
  led <= sw;
end architecture;
