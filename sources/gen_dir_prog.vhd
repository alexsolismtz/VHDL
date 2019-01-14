----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:32:56 01/30/2015 
-- Design Name: 
-- Module Name:    gen_dir_prog - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity gen_dir_prog is
	Generic(
			NumBitsDireccion	:integer := 14; --14 para 16K
			AddInicial 			:integer := 0; --Esta direccion incluida
			AddFinal 			:integer := 16330; --Esta direccion incluida
			NumVeces				:natural := 4
	);
    Port ( en_i 							: in  STD_LOGIC;
           clk_i 							: in  STD_LOGIC;
           rst_i 							: in  STD_LOGIC;
           add_o 							: out  STD_LOGIC_VECTOR (NumBitsDireccion - 1 downto 0);
           EndOfAddressGeneration 	: out  STD_LOGIC);
end gen_dir_prog;

architecture Behavioral of gen_dir_prog is
	signal iEOAG:STD_LOGIC:='0';
	signal cuenta: integer := 0;
	signal vecesSacarMemoria :integer := 0;
	constant fincuenta: integer := AddFinal;
begin
Contador: process (rst_i, clk_i)
begin
	if rst_i = '1' then
		cuenta <= AddInicial; --(others => '0');
		add_o <= std_logic_vector(to_unsigned(AddInicial, add_o'length)); --(others => '0');
	elsif rising_edge(clk_i) then
		if en_i = '1' then
			if cuenta = fincuenta then
				if(vecesSacarMemoria =  NumVeces - 1) then
					cuenta <= cuenta; -- one-shot
				else
					vecesSacarMemoria <= vecesSacarMemoria + 1;
					cuenta <= AddInicial;
				end if;
			else
				cuenta <= cuenta + 1;
			end if;
			add_o <= std_logic_vector(to_unsigned(cuenta,add_o'length));
		end if;
  end if;
end process;

EndOfAddress: process (rst_i, clk_i)
begin
	if rst_i = '1' then
		iEOAG <= '0';
	elsif rising_edge(clk_i) then
		if en_i = '1' then
			if (cuenta = fincuenta) AND (vecesSacarMemoria =  NumVeces - 1) then
				iEOAG <= '1'; -- one-shot
			else
				iEOAG <= '0';
			end if;
		else
			iEOAG <= '0';
		end if;
  end if;
end process;
EndOfAddressGeneration <= iEOAG;

end Behavioral;

