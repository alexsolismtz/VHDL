--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:49:53 06/05/2014
-- Design Name:   
-- Module Name:   C:/VHDL/T3C_DevlpCore/T3C_DevlCore/tb_Procesador_T3C.vhd
-- Project Name:  T3C_DevlCore
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Procesador_T3C
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
-- Los integer se ven como binario y no se puede camboar el radix.... para solucionarlo
-- wave add -radix unsigned path/to/sigal
--El path to sinal se puede pillar entero picando sobre la señal y dicendo 'copy' y luego 'paste' 
--en la entrada para comandos del Isim.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;

USE std.textio.ALL;
 
ENTITY tb_Procesador_T3C IS
END tb_Procesador_T3C;
 
ARCHITECTURE behavior OF tb_Procesador_T3C IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
COMPONENT Procesador_T3C is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           Canal_A : in  STD_LOGIC_VECTOR (15 downto 0);
           Canal_B : in  STD_LOGIC_VECTOR (15 downto 0);
           Coef_A : in  STD_LOGIC_VECTOR (31 downto 0);
           Coef_B : in  STD_LOGIC_VECTOR (31 downto 0);
           --numAlabes : in  STD_LOGIC_VECTOR (7 downto 0);
           numAlabes : in  STD_LOGIC_VECTOR (10 downto 0);
			  limitem : in STD_LOGIC_VECTOR(12 downto 0);
			  limitTimeOut: in STD_LOGIC_VECTOR(15 downto 0); --TimeOut para no buscar limite
			  modoRecta: in STD_LOGIC; --0 dirct prop, 1 inv proporiconal
		   rst_DPM: in STD_LOGIC;
           --dirAXI_i : in  STD_LOGIC_VECTOR (10 downto 0);
           dirAXI_i : in  STD_LOGIC_VECTOR (13 downto 0);
           datAXI_i : in  STD_LOGIC_VECTOR (31 downto 0);
			datAXI_o : out  STD_LOGIC_VECTOR (31 downto 0);
           webAXI_i : in  STD_LOGIC_VECTOR (0 downto 0);
			enAXI_i : in  STD_LOGIC;
           clkAXI_i : in  STD_LOGIC;
--	PARA COMPROBACIONES --
			  TT : OUT STD_LOGIC_VECTOR(15 downto 0);
			  ChangeTT: OUT std_LOGIC_VECTOR(2 downto 0));
--	FIN PARA COMPROBACIONES --			  
end COMPONENT;

    
constant A_cte: std_logic_vector (15 downto 0) := x"07A1"; -- 4 -> 32768
constant B_cte: std_logic_vector (31 downto 0) := x"01FD2270"; --"1001000000000000"; -- 9 -> 36864
   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal Canal_A : std_logic_vector(15 downto 0) := (others => '0');
   signal Canal_B : std_logic_vector(15 downto 0) := (others => '0');
   --signal Coef_A : std_logic_vector(15 downto 0) := x"8000"; --32768 --A_cte;
   --signal Coef_B : std_logic_vector(31 downto 0) := x"00009000";--B_cte;--x"00009000"; --36864
	signal Coef_A : std_logic_vector(31 downto 0) := x"00005949";
   signal Coef_B : std_logic_vector(31 downto 0) := x"14F69249";
   signal numAlabes : std_logic_vector(10 downto 0) := "000" & x"92"; -- 
   signal limitem : std_logic_vector(12 downto 0) :=  '0' & x"1F4"; --0.061V@1V=> 500 LSBs...sacado de la Excel
	signal limitTimeOut: std_logic_vector(15 downto 0) :=  x"AAAA"; -- No se usa
   signal dirAXI_i : std_logic_vector(13 downto 0) := (others => '0');
   signal datAXI_i : std_logic_vector(31 downto 0) := (others => '0');
   signal webAXI_i : std_logic_vector(0 downto 0) := (others => '0');
   signal enAXI_i : std_logic := '0';
   signal clkAXI_i : std_logic := '0';
	SIGNAL dirAXI_kk : std_logic_vector(15 downto 0) := (others => '0');
	SIGNAL Zero: std_logic  := '0';
 	--Outputs
   signal datAXI_o : std_logic_vector(31 downto 0);
	
	signal TT: Std_logic_Vector(15 downto 0);
	signal ChangeTT : std_LOGIC_VECTOR(2 downto 0);
	
   -- Clock period definitions
   constant clk_period : time := 40 ns;
   constant clkAXI_i_period : time := 10 ns;
	
		-- file declaration
	-- type "TEXT" is already declared in textio library
	FILE f_V1 : TEXT OPEN READ_MODE is "v1.txt";
	FILE f_V2 : TEXT OPEN READ_MODE is "v2.txt";
	FILE f_PROC : TEXT OPEN WRITE_MODE is "vT3C_processed.txt";
	FILE f_TT: TEXT OPEN WRITE_MODE is "vTT.txt";
 
	signal EOProcesado : STD_LOGIC := '0';
	signal addM : integer:=0;
	signal ctrRST: integer := 0;
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Procesador_T3C PORT MAP (
          clk => clk,
          rst => rst,
          Canal_A => Canal_A,
          Canal_B => Canal_B,
          Coef_A => Coef_A,
          Coef_B => Coef_B,
          numAlabes => numAlabes,
          limitem => limitem,
			 limitTimeOut => limitTimeOut,
			 modoRecta => '1',	-- Curva en la dase 2
			 --modoCoefs => Zero, --0 automatico, 1 manual
			 rst_DPM => Zero,
          dirAXI_i => dirAXI_i,
          datAXI_i => datAXI_i,
          datAXI_o => datAXI_o,
          webAXI_i => webAXI_i,
          enAXI_i => enAXI_i,
          clkAXI_i => clkAXI_i,
-- PARA PRUEBAS ---
			 TT => TT,
			 ChangeTT => ChangeTT
-- FIN PRUEBAS ---			 
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   clkAXI_i_process :process
   begin
		clkAXI_i <= '0';
		wait for clkAXI_i_period/2;
		clkAXI_i <= '1';
		wait for clkAXI_i_period/2;
   end process;
 
	rst_proces: process(clk)
	begin
		if(rising_edge(clk)) then
			if(ctrRST <= 10) then
				ctrRST <= ctrRST + 1;
			end if;
		end if;
	end process;
	rst <= '1' when ctrRST < 2 else '0';
	
read_prc: process (clk) 
	-- file variables
    VARIABLE vDatainline1,vDatainline2 : line;	 
	 variable n1,n2: natural range 0 to (2**16)-1;
begin
	if(rising_edge(clk)) then
		if(EOProcesado = '0') then
			if(not endfile(f_V1)) then
				readline (f_V1, vDatainline1);            -- read a line from input file
				readline (f_V2, vDatainline2);            -- read a line from input file
				read (vDatainline1,n1);                   -- read the natural number in that line
				read (vDatainline2,n2);                   -- read the natural number in that line
				Canal_A <= std_logic_vector(to_unsigned(n1,16));
				Canal_B <= std_logic_vector(to_unsigned(n2,16));
			else
				EOProcesado <= '1';
				report "Fin de procesado...activando lectura de memoria";
			end if;
		end if;
	end if;
end process;

TestTT_prc: process (clk) 
	-- file variables
    VARIABLE vDataTT: line;	 
	 variable nTT: natural range 0 to (2**16)-1;
	 variable ctrTT: natural := 0;
begin
	if(rising_edge(clk)) then
		if(EOProcesado = '0') then
			if(ChangeTT="001") then		--Por timeOut
				nTT := 2; --to_integer(unsigned(TT));				
				write(vDataTT,nTT);
--				write(vDataTT,";");
--				ctrTT := ctrTT + 1;
--				write(vDataTT,ctrTT);
				writeline(f_TT,vDataTT);
			elsif(ChangeTT="010") then	--Por limiteV
				nTT := 3; --to_integer(unsigned(TT));				
				write(vDataTT,nTT);
--				write(vDataTT,";");
--				ctrTT := ctrTT + 1;
--				write(vDataTT,ctrTT);
				writeline(f_TT,vDataTT);
			elsif(ChangeTT="100") then	--Comienzo de detección
				nTT := 1; --to_integer(unsigned(TT));				
				write(vDataTT,nTT);
--				write(vDataTT,";");
--				ctrTT := ctrTT + 1;
--				write(vDataTT,ctrTT);
				writeline(f_TT,vDataTT);				
			else
				nTT := 0;
				write(vDataTT,nTT);
--				write(vDataTT,";");		--Si lo comento no guardo el número de muesta...ya está en excel
--				ctrTT := ctrTT + 1;
--				write(vDataTT,ctrTT);
				writeline(f_TT,vDataTT);
			end if;
		end if;
	end if;
end process;
--adaptación de la memoria de nx4bytes a la mamoria 1024x32
dirAXI_kk <= std_logic_vector(to_unsigned(addM,16)) when EOPRocesado = '1' else std_logic_vector(to_unsigned(0,16));
dirAXI_i <= dirAXI_kk(15 downto 2);
write_prc: process (clkAXI_i) 
	-- file variables
	VARIABLE vDataoutline : line;	 
	variable n3 : natural range 0 to (2**16)-1;	
begin
	if(rising_edge(clkAXI_i)) then
		if(EOProcesado = '1') then
			if(addM < 16384*4) then
					enAXI_i <= '1';
					webAXI_i <= "0"; --lectura memoria
					n3 := to_integer(unsigned (datAXI_o));
					write (vDataoutline, n3);
					writeline (f_PROC, vDataoutline);            -- write a line from input file
					addM <= addM + 4;										-- posiciones de 32bits
			else 
				file_close(f_V1);
				file_close(f_V2);
				file_close(f_PROC);
				file_close(f_TT);
				report "Fin de lectura de memoria";
 				report "BP set";
			end if;
		end if;		
	end if;
end process;


END;
