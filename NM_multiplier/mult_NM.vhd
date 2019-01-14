----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:02:43 10/18/2016 
-- Design Name: 
-- Module Name:    mult_NM - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mult_NM is
	 Generic(
				n: integer :=4; --FILAS
				m: integer :=3  --COLUMNAS
	 );

    Port ( a : in  STD_LOGIC_VECTOR (m-1 downto 0);
           b : in  STD_LOGIC_VECTOR (n-1 downto 0);
           p : out  STD_LOGIC_VECTOR (n+m-1 downto 0));
end mult_NM;

architecture Behavioral of mult_NM is
		COMPONENT mult_1bit
			PORT(
				a : IN std_logic:='0';
				b : IN std_logic:='0';
				pin : IN std_logic:='0';  
				cin : IN std_logic:='0';
				cout : OUT std_logic:='0';				
				pout : OUT std_logic	:='0'			
				);
			END COMPONENT;
		TYPE matriz_nm IS ARRAY (0 TO n, 0 TO m) OF STD_LOGIC;
	   SIGNAL x,y	:matriz_nm;
		SIGNAL pin,cin : STD_LOGIC_VECTOR (m-1 downto 0);	
			
begin
filas: FOR i IN 0 TO n-1 GENERATE
	columnas: FOR j IN 0 TO m-1 GENERATE
		esquina: IF (i=0) AND (j=0) GENERATE
			u1: mult_1bit PORT MAP (a(j), b(i), pin(j), cin(i), x(i,j+1), p(i));
		END GENERATE;
		ladodch: IF (i>0) AND (j=0) GENERATE
			u1: mult_1bit PORT MAP (a(j), b(i), y(i,j+1), cin(i), x(i,j+1), p(i));
		END GENERATE;
		ladosup: IF (i=0) AND (j>0) GENERATE
			u1: mult_1bit PORT MAP (a(j), b(i), pin (j), x(i,j), x(i,j+1), y(i+1,j));
		END GENERATE;
		resto: IF (i>0) AND (j>0) GENERATE
			u1: mult_1bit PORT MAP (a(j), b(i), y(i,j+1), x(i,j), x(i,j+1), y(i+1,j));
		END GENERATE;
	pin(j) <= '0';
	cin(j) <= '0';
	END GENERATE;	
END GENERATE;
ladoizd: FOR i IN 1 TO m-1 GENERATE
	y(i,m) <= x(i-1,m);
END GENERATE;
ladoinf: FOR i IN m TO n+m-1 GENERATE
	p(i) <= y(m,i-(m-1));
END GENERATE;
	
end Behavioral;

