# TP_FPGA_Belliard_Priou

TP de réalisation d'un petit projet employant le HDMI pour l'affichage du logo de l'ENSEA

On utilise l'outil [GitHub Desktop](https://github.com/shiftkey/desktop?tab=readme-ov-file#installation-via-package-manager) permettant de gérer graphiquement notre repo facilement.

# 1 - Tutoriel Quartus

## 1.3 - Fichier de contrainte

Ici nous cherchons à assigner l'entité que l'on vient de créer aux sorties disponibles sur notre carte. Dans ce cas nous allons avoir besoin d'une led et d'un switch.  

On peut alors trouver le détail des pins qu'on peut utiliser ou non dans le Pin Mapper disponible sur Quartus.  
Pour savoir quels pins sont reliés à nos leds nous allons avoir besoin de la datasheet

## Mapping des pins à utiliser

![Pins_LEDs](https://github.com/user-attachments/assets/2a620267-1293-4109-8eb4-644c1c29cd8f)

![image](https://github.com/user-attachments/assets/082a54a5-2f0d-42a4-9ec6-3a10d13f2b68)

Depuis ces deux captures nous avons maintenant les pins nécessaires pour continuer.

## 1.5 - Modification du VHDL

Maintenant que nous cherchons à assigner plusieurs leds à nos différents switchs, nous avons besoin des autres pins que nous avions pas utilisé plus haut, toujours en se referrant à la datasheet, pour avoir par exemple sw(3) = PIN_W20 et ainsi de suite.

## 1.6 Faire clignoter une LED

Nous cherchons maintenant à faire clignoter une LED. Pour cela nous nous servons de la datasheet de la carte DE10-Nano [(DE10-Nano_User_manual.pdf)](https://github.com/OliverBELLIARD/2425_TPFPGA_Belliard_Priou/blob/main/Datasheets/DE10-Nano_User_manual.pdf).

Nous allons utiliser l'horloge FPGA_CLK1_50, à 50 MHz, pour passer en séquentiel (on a donc besoin d'une horloge pour se synchroniser).  
On trouve le pin lié à celle-ci dans la datasheet :

![image](https://github.com/user-attachments/assets/9c7899e2-77c8-4083-be35-f498a9e88f3c)

Pour le clignottement de la LED à 50 MHz nous avons commencé avec le code de base suivant :

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
Le fonctionnement logique voulu d'un tel code doit être le suivant si il s'agit simplement faire clignoter une LED : 

![image](https://github.com/user-attachments/assets/ed2697b0-b3b4-4f0c-855d-da7b2f818ba7)

Sous Analysis & Synthesis on peut trouver "RTL viewer" qui nous permet d'avoir un aperçu des principaux éléments de notre code :  
  
![image](https://github.com/user-attachments/assets/ccba088f-449e-4190-b2ca-5fd5882eb7ee)
  
On peut alors conclure que la vue RTL du code précédent est très similaire au schéma qu'on a dessiné juste avant :  
  
![image](https://github.com/user-attachments/assets/f5b64e9c-50aa-4916-832e-c871bfd2ff7c) 



Pour régler la fréquence du clignotement, trop rapide pour que nous puissions la distinguer à l'oeil nu pour l'instant, il suffit d'implémenter un compteur s'incrémentant jusqu'à 5 000 000 pour diminuer la fréquence de notre oscillation à 10 Hz par exemple. Cette approche se traduit par le schéma suivant :  
  
![image](https://github.com/user-attachments/assets/9a71e6cc-7d53-479c-acd7-28914ac2bd7e)

En effet, cette fois le signal de la led s'alternera seulement après que le compteur se soit incrémenté 5 000 000 de fois.

Nous l'avons codé de la façon suivante :  

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

Par ailleurs, on trouve sur la datasheet le pin auquel le bouton poussoir KEY0 est relié, il s'agit de AH17 :

![image](https://github.com/user-attachments/assets/a756d150-ee9c-456d-acbb-d8906035b5fa)

le "_n" dans `i_rst_n` signifie "not", ça ser à indiquer que le signal de reset (rst) en input (i) est actif à l'état bas.

On obtient alors la vue RTL suivante : 

![image](https://github.com/user-attachments/assets/9a339164-fe71-48d3-a0a5-802f3ad4aba2)

On reconnait effectivement la fonction voulue : que l'état de notre led alterne si la valeur de notre compteur (synchronisée avec la clock sélectionnée précédemment à 50MHz) est égale à une valeur hexadécimale équivalente à 5 000 000, créant ainsi une oscillation de 10Hz.

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
Notre chenillard reprend le même principe qu'en 1.6 pour faire clignoter notre led mais lorsqu'un cycle est fini, nous effectuons un décalage d'1 bit à gauche, tout en s'assurant que sinous arrivons au bout de notre index, celui-ci se réinitialise pour pas que le chenillard s'arrête.

# 2 Petit projet : Bouncing ENSEA Logo

## 2.1 Contrôleur HDMI

### **1. Analyse de l'entity :**

#### Quel est le rôle des différents paramètres définis en generic ?  

- **`h_res`** : Représente la résolution horizontale (nombre de pixels par ligne) de l'image.  
- **`v_res`** : Représente la résolution verticale (nombre de lignes par image).  
- **`h_sync`, `h_fp`, `h_bp`** : Ces paramètres définissent les timings horizontaux :
  - **`h_sync`** : Durée de l'impulsion de synchronisation horizontale.
  - **`h_fp`** (Front Porch) : Intervalle entre la fin de la ligne active et le début de l'impulsion de synchronisation.
  - **`h_bp`** (Back Porch) : Intervalle entre la fin de l'impulsion de synchronisation et le début de la ligne active.  
- **`v_sync`, `v_fp`, `v_bp`** : Ces paramètres définissent les timings verticaux :
  - **`v_sync`** : Durée de l'impulsion de synchronisation verticale.
  - **`v_fp`** (Front Porch) : Intervalle entre la fin de la zone active et le début de l'impulsion de synchronisation verticale.
  - **`v_bp`** (Back Porch) : Intervalle entre la fin de l'impulsion de synchronisation verticale et le début de la zone active.  

#### Quelle est leur unité ?  

L'unité des paramètres **timings** (e.g., `h_sync`, `h_fp`) est exprimée en **cycles d'horloge**.

---

### **2. Rôle de certains signaux :**

- **`o_new_frame`** : Passe à l'état haut pendant **1 cycle d'horloge** lorsqu'une image complète a été transmise.  
- **`o_pixel_address`** : Adresse du pixel dans l'image active. Calculée par :  
  \[
  \text{o_pixel_address} = o_x_counter + (h_res \times o_y_counter)
  \]
- **`o_x_counter`** et **`o_y_counter`** : Indiquent respectivement la position du pixel en coordonnées X (horizontale) et Y (verticale) dans la zone active.

---

### **3. Rôle des autres signaux :**

#### Entrées  

1. **`i_clk`** : Signal d'horloge servant de référence pour tous les compteurs et processus séquentiels.  
2. **`i_reset_n`** : Signal actif bas pour réinitialiser tous les registres et compteurs internes.

#### Sorties  

1. **`o_hdmi_hs` (Horizontal Sync)** : Génère l'impulsion de synchronisation horizontale (active pendant `h_sync` cycles d'horloge).  
2. **`o_hdmi_vs` (Vertical Sync)** : Génère l'impulsion de synchronisation verticale (active pendant `v_sync` cycles).  
3. **`o_hdmi_de` (Data Enable)** : Signal indiquant si le générateur est dans une **zone active** où les pixels sont visibles. Il est actif lorsque `h_act` et `v_act` sont hauts.  
4. **`o_pixel_en` :** Permet d'activer l'écriture ou la lecture des pixels lorsque le générateur est dans la zone active.

---

### **Récapitulatif des étapes de la conception :**

#### Étape 1 : Compteur horizontal (`h_count`)

- Compte de 0 à `h_total` et génère le signal de synchronisation horizontale **`o_hdmi_hs`**.

#### Étape 2 : Compteur vertical (`v_count`)

- Compte de 0 à `v_total` et génère le signal de synchronisation verticale **`o_hdmi_vs`**.

#### Étape 3 : Détection de la zone active

- Basée sur les plages de **`h_count`** et **`v_count`**, des signaux internes **`h_act`** et **`v_act`** sont définis.

#### Étape 4 : Génération de l'adresse du pixel actif

- Un compteur de pixels actifs génère l'adresse du pixel actif via **`o_pixel_address`**.

#### Étape 5 : Comptage X/Y

- Les compteurs X et Y (respectivement **`o_x_counter`** et **`o_y_counter`**) indiquent la position d'un pixel actif.

---

### **Simulation et Test :**

Pour valider le fonctionnement :

1. Créez un testbench pour simuler les compteurs et signaux **`o_hdmi_hs`**, **`o_hdmi_vs`**, **`o_hdmi_de`**.
2. Testez avec des résolutions réduites (par exemple, `h_res=10`, `v_res=10`) pour réduire les temps de simulation.

---
  
Nous avons codé un Testbench qui gère tout simplement le signal d'orloge et le signal de reset pour observer les signaux en sortie de l'Entity de la **Figure 1** :

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

### 2.1.1 Écriture du composant

Nous avons simulé notre `hdmi_generator.vhd` avec notre testbench créé plus haut, `tb_hdmi_generator` sur [ModelSim](https://www.intel.com/content/www/us/en/software-kit/750666/modelsim-intel-fpgas-standard-edition-software-version-20-1-1.html) :  
  
![image](https://github.com/user-attachments/assets/ce3d4ace-85ba-4610-a705-59721d3552cf)

Sur cette première figure on vérifie que `o_y_counter` s'incrémente correctement jusqu'à `v_res` qui vaut 480.

  ![image](https://github.com/user-attachments/assets/26169508-c66d-4ab7-ae52-ccabab887317)

### 2.1.2 Implémentation sur le FPGA

Après l'envoi de simples gradients de couleur, nous reçevons l'image suivante sur notre récepteur HDMI (VLC : Media > Open Capture Device > Capture Mode : Video Camera, Video device name : premier appareil) :
  
![image](https://github.com/user-attachments/assets/a6944efd-b10d-44bd-aec9-370a5542a3bd)
  
## 2.2 Bouncing ENSEA Logo

### 2.2.1 Déplacer le logo

Le composant `hdmi_generator.vhd` est complété de la façon suivante :

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_generator is
 generic (
  -- Resolution
  h_res  : natural := 720;
  v_res  : natural := 480;

  -- Timings magic values (480p)
  h_sync : natural := 61;
  h_fp : natural := 58;
  h_bp : natural := 18;

  v_sync : natural := 5;
  v_fp : natural := 30;
  v_bp : natural := 9
 );
 port (
  i_clk    : in std_logic;
     i_reset_n  : in std_logic;
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

 constant h_start: natural := h_sync+h_fp; -- 119
 constant h_end  : natural := h_res+h_start; -- 839
 constant h_total: natural := h_end+h_bp; -- 857

 constant v_start: natural := v_sync+v_fp; -- 35
 constant v_end  : natural := v_res+v_start; -- 515
 constant v_total: natural := v_end+v_bp; -- 524

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

Et `DE10_Nano_HDMI_TX.vhd` a été rempli comme suit :

```vhdl
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

    signal vpg_pclk : std_logic;        -- 27MHz
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
            o_pixel_en => '1',
            o_pixel_address => (others => '0'),
            o_x_counter => (others => '0'),
            o_y_counter => (others => '0'),
            o_new_frame => '0'
        );

    HDMI_TX_D(23 downto 16) <= (others => '0');
    HDMI_TX_D(15 downto 8)  <= (others => '0');
    HDMI_TX_D(7 downto 0)   <= (others => '0');
    
    -- Configures the HDMI IC through I2C
    I2C_HDMI_Config0 : component I2C_HDMI_Config 
        port map (
            iCLK => FPGA_CLK1_50,
            iRST_N => reset_n,
            I2C_SCLK => HDMI_I2C_SCL,
            I2C_SDAT => HDMI_I2C_SDA,
            HDMI_TX_INT => HDMI_TX_INT
        );
end architecture rtl;
```

Nous obtenons bien le logo de l'ENSEA qui se déplace en rebondissant sur l'écran :
  
![2025-01-08 17-31-14](https://github.com/user-attachments/assets/3b1db675-3d72-4fd0-bb22-44800ff0bbe1)
