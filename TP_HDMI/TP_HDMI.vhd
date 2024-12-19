library ieee;
use ieee.std_logic_1164.all;
entity tuto_fpga is
port (
sw : in std_logic;
led : out std_logic
);
end entity tuto_fpga;
architecture rtl of tuto_fpga is
begin
led <= sw;
end architecture rtl;