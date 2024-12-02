library ieee;
use ieee.std_logic_1164.all;

library pll;
use pll.all;

entity DE10_Nano_HDMI_TX is
    port (
        -- ADC
        ADC_CONVST         : out STD_LOGIC;
        ADC_SCK            : out STD_LOGIC;
        ADC_SDI            : out STD_LOGIC;
        ADC_SDO            : in STD_LOGIC;

        -- ARDUINO
        ARDUINO_IO         : inout STD_LOGIC_VECTOR(15 downto 0);
        ARDUINO_RESET_N    : inout STD_LOGIC;

        -- FPGA
        FPGA_CLK1_50       : in STD_LOGIC;
        FPGA_CLK2_50       : in STD_LOGIC;
        FPGA_CLK3_50       : in STD_LOGIC;

        -- GPIO
        GPIO_0             : inout STD_LOGIC_VECTOR(35 downto 0);
        GPIO_1             : inout STD_LOGIC_VECTOR(35 downto 0);

        -- HDMI
        HDMI_I2C_SCL       : inout STD_LOGIC;
        HDMI_I2C_SDA       : inout STD_LOGIC;
        HDMI_I2S           : inout STD_LOGIC;
        HDMI_LRCLK         : inout STD_LOGIC;
        HDMI_MCLK          : inout STD_LOGIC;
        HDMI_SCLK          : inout STD_LOGIC;
        HDMI_TX_CLK        : out STD_LOGIC;
        HDMI_TX_D          : out STD_LOGIC_VECTOR(23 downto 0);
        HDMI_TX_DE         : out STD_LOGIC;
        HDMI_TX_HS         : out STD_LOGIC;
        HDMI_TX_INT        : in STD_LOGIC;
        HDMI_TX_VS         : out STD_LOGIC;

        -- KEY
        KEY                : in STD_LOGIC_VECTOR(1 downto 0);

        -- LED
        LED                : out STD_LOGIC_VECTOR(7 downto 0);

        -- SW
        SW                 : in STD_LOGIC_VECTOR(3 downto 0)
    );
end entity DE10_Nano_HDMI_TX;

architecture rtl of DE10_Nano_HDMI_TX is
	component I2C_HDMI_Config 
		port (
			iCLK : in std_logic;
			iRST_N : in std_logic;
			I2C_SCLK : out std_logic;
			I2C_SDAT : inout std_logic;
			HDMI_TX_INT  : in std_logic
		);
	 end component;
	 
	component pll 
		port (
			refclk : in std_logic;
			rst : in std_logic;
			outclk_0 : out std_logic;
			locked : out std_logic
		);
	end component;

	signal vpg_pclk : std_logic;		-- 27MHz
	signal reset_n : std_logic;
	
begin
	HDMI_TX_CLK <= vpg_pclk;
	
	-- Generates the clock required for HDMI
	pll0 : component pll 
		port map (
			refclk => FPGA_CLK2_50,
			rst => not(KEY(0)),
			outclk_0 => vpg_pclk,
			locked => reset_n
		);
	
	-- Generates the signals for HDMI IC
	-- Gives an address for the frame buffer
	-- Or x/y coordinates for the sprite generator
	hdmi_generator0 : entity work.hdmi_generator 
		port map (                                    
			i_clk => vpg_pclk,
			i_reset_n => reset_n,
			o_hdmi_hs => HDMI_TX_HS,
			o_hdmi_vs => HDMI_TX_VS,
			o_hdmi_de => HDMI_TX_DE,
			o_pixel_en => 
			o_pixel_address => 
			o_x_counter => 
			o_y_counter => 
			o_new_frame => 
		);

	HDMI_TX_D(23 downto 16) <= 
	HDMI_TX_D(15 downto 8)  <= 
	HDMI_TX_D(7 downto 0)   <= 
	
	-- Configures the HDMI IC through I2C. It's verilog, thanks Terasic (but you don't want to see the code...)
	I2C_HDMI_Config0 : component I2C_HDMI_Config 
		port map (
			iCLK => FPGA_CLK1_50,
			iRST_N => reset_n,
			I2C_SCLK => HDMI_I2C_SCL,
			I2C_SDAT => HDMI_I2C_SDA,
			HDMI_TX_INT => HDMI_TX_INT
	 );
end architecture rtl;
