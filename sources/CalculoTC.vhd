----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:34:31 10/31/2013 
-- Design Name: 
-- Module Name:    CalculoTC - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
--              V2.1 Se reescribe para ser más template-alike
--				v2. Se elimina la posibilidad de un modo... se hará fuera del core.
--      
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


-- Conversi?n de V1/V2 (din) en TIP CLEARENCE (TC)
-- TC = - A * din + B si modo = 1
-- TC = A*Din+B si modo = 0
-- LATENCIA: 2 ciclos

entity CalculoTC is
    Port (  clk : in  STD_LOGIC;
				modoRecta : in  STD_LOGIC;										-- Si modo = 0 directament proporiconal +, si modo = 1 inversamente propo (-)	
				rst : IN std_LOGIC;
				din : in  STD_LOGIC_VECTOR (15 downto 0);				-- Valor de V2/V1 expresado con 16 bits con distribución 7.9
				A_IN: in std_logic_vector (31 downto 0);				-- Pendiente = m*2^15
				B_IN: in std_logic_vector (31 downto 0);				-- Desplazamiento que tiene en cuenta el offset [b+Off]_mm*2^9*2^15
				                                                        -- En el bloque superior habrá que dividir por 24(9+15)-bitsSignificativos
	         dout : out  STD_LOGIC_VECTOR (15 downto 0) := (others => '0'));			-- Resultado real dout/2^12
end CalculoTC;

architecture Behavioral of CalculoTC is
		--contantes obtenidas en excel		'comprabacio.xls' del 05.11.15..
    --constant A_cte: std_logic_vector (15 downto 0) := x"07A1"; -- 4 -> 32768
    --constant B_cte: std_logic_vector (31 downto 0) := x"01FD2270"; --"1001000000000000"; -- 9 -> 36864
	 signal producto : STD_LOGIC_VECTOR (47 downto 0);
    signal dout_aux : STD_LOGIC_VECTOR (47 downto 0):= (OTHERS => '1');
    constant bitsSignificativos : natural := 12; --Nos quedamos con los bits a partir de 2^bitsSignificativos
begin

CalculoTC: process(clk,din,A_IN,B_IN,producto)

begin

--	if modo = '0' then     
--		producto <= A_cte * din;								-- Toma los valores constantes
--		dout_aux <=  B_cte + producto;
--	else 		

--	end if; 		

	if rising_edge(clk) then 	
		if rst = '1' then 
			dout_aux <= (OTHERS => '1');
			producto <= (OTHERS => '0');
		else
		  if (modoRecta = '0') then
			producto <= A_IN * din;									-- Toma los valores manuales o introducidos
            dout_aux <= B_IN + producto;
          elsif(modoRecta = '1') then			
            producto <= A_IN * din;									-- Toma los valores manuales o introducidos
            dout_aux <= B_IN - producto;
          end if;
		end if;
	end if;	
end process;		
    dout <= dout_aux(bitsSignificativos-1 + 16 downto bitsSignificativos); -- De momento nos quedamos con 16 bits.
end Behavioral;



