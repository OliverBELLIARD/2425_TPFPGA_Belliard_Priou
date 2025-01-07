# TP_FPGA_Belliard_Priou
TP de réalisation d'un petit projet employant le HDMI pour l'affichage du logo de l'ENSEA

On utilise l'outil [GitHub Desktop](https://github.com/shiftkey/desktop?tab=readme-ov-file#installation-via-package-manager) permettant de gérer graphiquement notre repo facilement.

## 1.6 Faire clignoter une LED
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

RTL Viewer
![image](https://github.com/user-attachments/assets/f5b64e9c-50aa-4916-832e-c871bfd2ff7c)
