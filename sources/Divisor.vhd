library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
-- use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
----------------------------------------------------------------------------------
-- DESCRIPCI?N

-- Divisi?n de dos n?meros de 16 bits en modo pipeline
-- Duraci?n un pulso
-- Latencia 2x(ANCHURA+16) pulsos = 50 pulsos

--
----------------------------------------------------------------------------------

entity divisor is
    Port ( clk : in STD_LOGIC;
				rst : in STD_LOGIC;
           D : in  STD_LOGIC_VECTOR (15 downto 0);
           N : in  STD_LOGIC_VECTOR (15 downto 0);
           C : out  STD_LOGIC_VECTOR (15 downto 0));
end Divisor;

architecture Behavioral of divisor is
    -- Component Declaration for the Unit Under Test (UUT)
 COMPONENT dividerNxN is
  generic ( SIZE_C : integer := 32 ) ;            -- SIZE_C: Number of bits
  port 
  (
       rst   : in  STD_LOGIC;
       clk   : in  STD_LOGIC;
       a     : in  STD_LOGIC_VECTOR(SIZE_C-1 downto 0) ;     -- Numerador
       d     : in  STD_LOGIC_VECTOR(SIZE_C-1 downto 0) ;     -- Denominador
       
       q     : out STD_LOGIC_VECTOR(SIZE_C-1 downto 0) ;     
       r     : out STD_LOGIC_VECTOR(SIZE_C-1 downto 0)
  ); END COMPONENT; 
  --constant ANCHURA: NATURAL := 9;	-- Variación del cociente más pequeña 1/(2^9)
												-- Cociente 7.9
constant ANCHURA: NATURAL := 13;	-- Variación del cociente más pequeña 1/(2^13)
    												-- Cociente 2.13 												 
  signal NumExtendido: STD_LOGIC_VECTOR(ANCHURA + 16 - 1 downto 0);
  signal DenExtendido: STD_LOGIC_VECTOR(ANCHURA + 16 - 1 downto 0);
  signal CocExtendido: STD_LOGIC_VECTOR(ANCHURA + 16 - 1 downto 0);
  signal ResExtendido: STD_LOGIC_VECTOR(ANCHURA + 16 - 1 downto 0);
  constant ZeroVector: STD_LOGIC_VECTOR(ANCHURA - 1 downto 0) := (OTHERS => '0');
  --
  signal ctr: integer := 0;
begin
process(clk)
begin
if rising_edge(clk) then
	ctr <= ctr + 1;
end if;
end process;
	NumExtendido <= N & ZeroVector;
	DenExtendido <= ZeroVector & D;
   uut: dividerNXN 
		GENERIC MAP (
		SIZE_C => ANCHURA + 16)	-- LATENCIA = 2x(ANCHURA+16)
		PORT MAP (
		rst => rst,
		clk => clk,
		a => NumExtendido,
		d => DenExtendido,
		q => CocExtendido,
		r => ResExtendido);
		C<= CocExtendido(15 downto 0);
		
end Behavioral;
