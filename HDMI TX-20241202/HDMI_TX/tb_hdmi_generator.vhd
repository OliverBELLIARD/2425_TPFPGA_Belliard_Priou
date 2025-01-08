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
      i_clk <= '0';
      wait for 5 ns;
      i_clk <= '1';
      wait for 5 ns;
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
