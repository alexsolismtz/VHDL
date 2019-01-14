----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:01:53 05/26/2014 
-- Design Name: 
-- Module Name:    Procesador_T3C - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:  AÃ±ado un limite para el timeOut horizontal que sea conocido a ver si es mÃ¡s estable
--                  Es la segunda versiÃ³n en la que impelemento:
--						* El divisor en formato 7.9
--						* El cÃ¡lculo del TC con CoefA (16 bits) y Coef_B(32 bits)
--						* limitem variable en cada Ã¡labe y no fijo como hasta ahora.
--						* El modo de los coeficientes se usa en el nivel superior
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

entity Procesador_T3C is
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
			  ChangeTT: OUT STD_LOGIC_VECTOR(2 downto 0));	-- 2 | 1 | 0
																			--				Detección por tiempo
																			--		Detección por tensión alta
																			-- Comienzo de detección
			  
--	FIN PARA COMPROBACIONES --			  
end Procesador_T3C;

architecture Behavioral of Procesador_T3C is
COMPONENT  divisor is
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        D : in  STD_LOGIC_VECTOR (15 downto 0);
        N : in  STD_LOGIC_VECTOR (15 downto 0);
        C : out  STD_LOGIC_VECTOR (15 downto 0));
end COMPONENT;

COMPONENT CalculoTC is
    Port (  
        clk : in  STD_LOGIC;
        rst : IN std_LOGIC;
        modoRecta : in  STD_LOGIC;										-- Si modo = 0 dirct proporcional, si modo = 1 inversamente proporcional	
        din : in  STD_LOGIC_VECTOR (15 downto 0);				-- Valor de V2/V1 expresado con 16 bits
        A_IN: in std_logic_vector (31 downto 0);				-- Pendiente = -A/2^17
        B_IN: in std_logic_vector (31 downto 0);				-- Desplazamiento
        dout : out  STD_LOGIC_VECTOR (15 downto 0));			-- Resultado real dout/2^12
END COMPONENT; 

COMPONENT Gestor_memory is
    Port ( 
        clk : in  STD_LOGIC;
        reset : in  STD_LOGIC;
        dinTC : in  STD_LOGIC_VECTOR (15 downto 0);
        changeTT : in  STD_LOGIC; 
        dinTT : in  STD_LOGIC_VECTOR (15 downto 0);
        limitalabe:out STD_LOGIC_VECTOR(15 downto 0) ;
        V2min: in STD_LOGIC_VECTOR(15 downto 0);			  
        --dir : out  STD_LOGIC_VECTOR (10 downto 0);
        dir : out  STD_LOGIC_VECTOR (13 downto 0);
        douta : out STD_LOGIC_VECTOR (15 downto 0);
        dina : in STD_LOGIC_VECTOR (15 downto 0);	
        wea : out STD_LOGIC_VECTOR (0 downto 0);
        ena : out STD_LOGIC;
        test : out STD_LOGIC_VECTOR (15 downto 0);
         -- modo : in STD_LOGIC;
        --numala : in STD_LOGIC_VECTOR (7 downto 0));			-- NÃºmero de Ã¡laves
        numala : in STD_LOGIC_VECTOR (10 downto 0));			-- NÃºmero de Ã¡laves
end COMPONENT;
COMPONENT CalculoTT is
    Port (
        v2 : 		in  STD_LOGIC_VECTOR (15 downto 0);				-- SeÃ±al mayor del sensor Ã³ptico
        clk : 		in  STD_LOGIC;											-- Reloj del sistema
        reset : 	in  STD_LOGIC;			  								-- Reset general
        limitem : in  STD_LOGIC_VECTOR (15 downto 0);				-- Mayor diferencia entre V2 y minimo acumulado para aceptar, modo entrada externa
        limitTime : in STD_LOGIC_VECTOR (15 downto 0);              --Tiempo sin buscar alabe
        --  modo : 	in  STD_LOGIC;											-- Modo = 1 => modo manual, Modo = 0 => modo automÃ¡tico 
        tt : 		out  STD_LOGIC_VECTOR (15 downto 0);			-- Pulsos entre mÃ­nimos
        min : 		out  STD_LOGIC_VECTOR (15 downto 0);			-- Valor del mÃ­nimo detectado
		  change_tt_V: out	STD_LOGIC;			--Detección por cambio por tensión muy por encima del último minimo
		  change_tt_T: out STD_LOGIC;	
		  start_of_Detection: OUT STD_LOGIC;	--Detección de cuando se empieza..
        changett : out  STD_LOGIC);
end COMPONENT;
COMPONENT dpram16kx16 is
    Port ( clka : in  STD_LOGIC;
           ena : in  STD_LOGIC;
           wea : in  STD_LOGIC_VECTOR (0 downto 0);
           addra : in  STD_LOGIC_VECTOR (13 downto 0);
           dina : in  STD_LOGIC_VECTOR (15 downto 0);
           douta : out  STD_LOGIC_VECTOR (15 downto 0);
           clkb : in  STD_LOGIC;
           enb : in  STD_LOGIC;
           web : in  STD_LOGIC_VECTOR (0 downto 0);
           addrb : in  STD_LOGIC_VECTOR (13 downto 0);
           dinb : in  STD_LOGIC_VECTOR (15 downto 0);
           doutb : out  STD_LOGIC_VECTOR (15 downto 0));
END COMPONENT;

COMPONENT fifo_n is
	generic (
		N:Integer); --Etpas de la FIFO...serían 60, pero por los lathes hay que quitar dos
    Port ( d_i : in  STD_LOGIC_VECTOR (15 downto 0);
           d_o : out  STD_LOGIC_VECTOR (15 downto 0);
           clk : in  STD_LOGIC);
end COMPONENT;
--COMPONENT dpram2kx16 is
--    Port ( clka : in  STD_LOGIC;
--           ena : in  STD_LOGIC;
--           wea : in  STD_LOGIC_VECTOR (0 downto 0);
--           addra : in  STD_LOGIC_VECTOR (10 downto 0);
--           dina : in  STD_LOGIC_VECTOR (15 downto 0);
--           douta : out  STD_LOGIC_VECTOR (15 downto 0);
--           clkb : in  STD_LOGIC;
--           enb : in  STD_LOGIC;
--           web : in  STD_LOGIC_VECTOR (0 downto 0);
--           addrb : in  STD_LOGIC_VECTOR (10 downto 0);
--           dinb : in  STD_LOGIC_VECTOR (15 downto 0);
--           doutb : out  STD_LOGIC_VECTOR (15 downto 0));
--END COMPONENT;
--COMPONENT dpm2k IS
--    PORT (
--        clka : IN STD_LOGIC;
--        ena : IN STD_LOGIC;
--        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--        addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
--        dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
--        douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
--        clkb : IN STD_LOGIC;
--        rstb: IN STD_LOGIC;
--        enb : IN STD_LOGIC;
--        web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--        addrb : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
--        dinb : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
--        doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
--);
--END COMPONENT;
	signal div_out : std_logic_vector(15 downto 0);
	signal Pout : std_logic_vector(15 downto 0);
	signal i_tt: std_logic_vector(15 downto 0);
	signal V2min: std_logic_vector(15 downto 0);
	signal i_changett: STD_LOGIC_VECTOR(2 downto 0);
	signal i_changett2: STD_LOGIC;
	--signal dir:std_logic_vector(10 downto 0);
	signal dir:std_logic_vector(13 downto 0);
	signal douta:std_logic_vector(15 downto 0);
	signal wea: std_logic_vector(0 downto 0);
	signal dina: std_logic_vector(15 downto 0);
	signal aux32dina: std_logic_vector(31 downto 0):=x"00000000";
	--signal modoCoefs: std_logic := '0'; --'0' por defecto, '1' external coefs
	signal en_i: std_logic;
	signal alabeCtr: integer := 0;
	signal i_alabeCtr:std_logic_vector (15 downto 0):=x"0000";
	signal i_limital : STD_LOGIC_VECTOR (15 downto 0);--:=x"1D00";
	signal Canal_B_Retrasado: STD_LOGIC_VECTOR(15 downto 0) := x"0000";
	------ test memoria
--	signal dir_ctr :integer := 0;
--	signal borrar0: STD_LOGIC_VECTOR(0 downto 0);
	-------
	
	
begin

Div16x16:	Divisor PORT MAP(
		clk => clk,
		rst => rst,
		D => Canal_A,
		N => Canal_B,
		C =>	div_out);
TC_Cal:CalculoTC PORT MAP(
		clk => clk,
		rst => rst,
		modoRecta => modoRecta,	
		A_IN => Coef_A,
		B_IN => Coef_B,
		din => div_out,
		dout =>Pout);
Retrasador: fifo_n GENERIC MAP (N => 57)
	PORT MAP(
		clk => clk,
		d_i => Canal_B,
		d_o => Canal_B_Retrasado);
TT_Cal: CalculoTT PORT MAP(
--		v2 => Canal_B,
		v2 => Canal_B_Retrasado,
		clk => clk,
		reset => rst,
		limitem => i_limital,
		limitTime => limitTimeOut,
		--modo => modoCoefs,	
		tt => i_tt,
		min => V2min,
		changett => i_changett2,
		start_of_Detection => i_changeTT(2),
		--change_tt_V => i_changeTT(1),
		change_tt_V => open,
		
		change_tt_T => i_changeTT(0));
-- PARA COMPROBAR --
-- Para sacar el ToA calculad
TT <= i_tt;
i_changeTT(1) <=  i_changett2;
ChangeTT <= i_changeTT;

-- PAra sacar el numero de alabes procesados
--i_alabeCtr <= std_logic_vector(to_unsigned(alabeCtr, i_alabeCtr'length));
--TT <= i_alabeCtr;

--ctrAlabes: process 	(clk)begin
--	if(rising_edge (clk)) then
--		--if(rst = '1') then  --Sin RST para que no se borre la cuenta cuando se resetea el core.
--		--	alabeCtr <= 0;
--		if (i_changett = '1') then		
--			alabeCtr <= alabeCtr + 1;
--		end if;
--	end if;
--end process;

-- FIN PARA COMPROBAR --
i_limital <= "000" & limitem; --Para limite fijo.
MemoryCtrler: Gestor_memory PORT MAP(
		clk => clk,
		reset => rst,
		dinTC => Pout,
		changeTT => i_changeTT2,
		limitalabe=>open,
--		limitalabe=>i_limital,
		V2min => V2min,
		dinTT => i_tt,
		dir => dir,
		douta => dina,
		dina => douta,
		wea => wea,
		ena => en_i,
		test => open,
		--modo => modoCoefs,
		numala => numAlabes);

datAXI_o <= aux32dina;

--PROCESS(clk)
--BEGIN
--	if(rising_edge(clk)) then
--		if(rst = '1') then
--			dir_ctr <= 0;
--		elsif dir_ctr = 1168 then	--146*8=
--			dir_ctr <= dir_ctr;
--		else
--			dir_ctr <= dir_ctr + 1;
--		end if;
--	end if;
--END PROCESS;
Memoria: dpram16kx16 PORT MAP(
    clka => clk,
	 ena => en_i,
    wea => wea,
    addra => dir,
    dina =>  dina,
    douta => douta,
    clkb => clkAXI_i,
    enb => enAXI_i,
    web => webAXI_i,
    addrb => dirAXI_i,
    dinb => datAXI_i(15 downto 0),
    doutb => aux32dina(15 downto 0) 
);

--Memoria: dpram2kx16 PORT MAP(
--    clka => clk,
--	 ena => en_i,
--    wea => wea,
--    addra => dir,
--    dina =>  dina,
--    douta => douta,
--    clkb => clkAXI_i,
--    enb => enAXI_i,
--    web => webAXI_i,
--    addrb => dirAXI_i,
--    dinb => datAXI_i(15 downto 0),
--    doutb => aux32dina(15 downto 0) 
--);
--Memoria: dpm2k   PORT MAP(
--    clka => clk,
--	ena => en_i,
--    wea => wea,
--    addra => dir,
--    dina =>  dina,
--    douta => douta,
-- -- Interfaz con el micro
--    clkb => clkAXI_i,
--    rstb => rst_DPM,
--    enb => enAXI_i,
--    web => webAXI_i,
--    addrb => dirAXI_i,
--    dinb => datAXI_i(15 downto 0),
--    doutb => aux32dina(15 downto 0) 
--  );				

		
end Behavioral;

