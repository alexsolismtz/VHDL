
----------------------------------------------------------------------------------
-- Company:  Este iba bien... 15.03.16
--
-- Engineer: 
-- 
-- Create Date:    13:49:07 10/08/2013 
-- Design Name: 
-- Module Name:    Gestor_memory - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:     v2.2 Se pone en un process las trasnsciones y en otro las salidas
--                         Se comprueba en simulación que se necesita:
--                                - 1 clock para poner dirección y WE EN
--                                - 1 clock para que la memoria saque el valor
--                                - 1 clock para que el valor de la memoria vaya a nuestra señal
--                  v2.1 Se insertan waitstates para ver si mejora el problema con los
--						accesos a memoria
--					v2. Se cambia a una descripción más de máquina de estado y se añade 
--						que el límite de alabe sea variable con un 25% más del mínimo detectado
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Gestor_memory is
    Port (  clk : in  STD_LOGIC;
            reset : in  STD_LOGIC;
            dinTC : in  STD_LOGIC_VECTOR (15 downto 0);
            changeTT : in  STD_LOGIC; 
            dinTT : in  STD_LOGIC_VECTOR (15 downto 0);
            limitalabe:out STD_LOGIC_VECTOR(15 downto 0) := x"1999"; -- x"01F4";  --x"03A0";	--x"1D00" para 16bits -- cambiarlo en cteLimitalabe
            V2min:in STD_LOGIC_VECTOR(15 downto 0);
--            dir : out  STD_LOGIC_VECTOR (10 downto 0):= "00000000000";
            dir : out  STD_LOGIC_VECTOR (13 downto 0):= "00000000000000";
            douta : out STD_LOGIC_VECTOR (15 downto 0):= x"0000";
            dina : in STD_LOGIC_VECTOR (15 downto 0);	
            wea : out STD_LOGIC_VECTOR (0 downto 0) := "0";
            ena : out STD_LOGIC := '0';
            test : out STD_LOGIC_VECTOR (15 downto 0);
            --  modo : in STD_LOGIC;											--'0' automatico 146 alabes
            --numala : in STD_LOGIC_VECTOR (7 downto 0));			-- Número de álabes
            numala : in STD_LOGIC_VECTOR (10 downto 0));			-- Número de álabes
end Gestor_memory;

architecture Behavioral of Gestor_memory is  

  signal estado: STD_LOGIC_VECTOR (7 downto 0);
  signal AuxMax: STD_LOGIC_VECTOR (15 downto 0);
  signal dataux: STD_LOGIC_VECTOR (15 downto 0)  := (OTHERS => '0');		--LAs lecturas de memoria se almacenan aqu�
  signal datamx: STD_LOGIC_VECTOR (15 downto 0);		--Minimo TC alabe durante un alabe.
  --signal minCurrentTC: STD_LOGIC_VECTOR(15 downto 0);	--Minimo TC para darle un 25% más como limite de álabe
  signal control: STD_LOGIC_VECTOR (15 downto 0) := (OTHERS => '0');
  --signal numalves: STD_LOGIC_VECTOR (7 downto 0);
  signal numalves: STD_LOGIC_VECTOR (10 downto 0);
  --signal diraux: STD_LOGIC_VECTOR (7 downto 0);
  signal diraux: STD_LOGIC_VECTOR (10 downto 0);
  signal con_ini: STD_LOGIC_VECTOR (7 downto 0) := (OTHERS => '0');
  signal start: STD_LOGIC:='0';
  --aux
  signal TCMinAux, TTMinAux: STD_LOGIC_VECTOR(15 downto 0):= (OTHERS => '1');
  signal TCMaxAux, TTMaxAux: STD_LOGIC_VECTOR(15 downto 0):= (OTHERS => '0');
  CONSTANT	offsetControl: STD_LOGIC_VECTOR(2 downto 0) := "000";
  CONSTANT	offsetTCMin: 	STD_LOGIC_VECTOR(2 downto 0) := "001";
  CONSTANT	offsetTCCurr:	STD_LOGIC_VECTOR(2 downto 0) := "010";
  CONSTANT	offsetTCMax: 	STD_LOGIC_VECTOR(2 downto 0) := "011";
  CONSTANT	offsetTTMin: 	STD_LOGIC_VECTOR(2 downto 0) := "100";
  CONSTANT	offsetTTCurr: 	STD_LOGIC_VECTOR(2 downto 0) := "101";
  CONSTANT	offsetTTMax: 	STD_LOGIC_VECTOR(2 downto 0) := "110";
  CONSTANT	offsetLimitAl: STD_LOGIC_VECTOR(2 downto 0) := "111";
  CONSTANT	cteLimitalabe: STD_LOGIC_VECTOR(15 downto 0):= x"1333";	--x"1D00" (7424) para 16bits -- cambiarlo en reset por defecto de la ENTITY
  																							--x"03A0" (928) para 13bits
																							-- x"01F4" (500) para 13bits
																							-- "1333" (4915) para 13 bits aprox 0.6@1V
																							-- "1999" () para 13 bits aprox 0.8@1V
  CONSTANT 	cteDetecciones: STD_LOGIC_VECTOR(7 downto 0) := "10000000" ; --Numero de ToA_Detect antes de empezar el procesado
  SIGNAL 	iV2Min : STD_LOGIC_VECTOR(15 downto 0);	--Captura V2Min del alabe recién detectado.
  SIGNAL 	  dinTT_in : STD_LOGIC_VECTOR(15 downto 0);	--Captura dinTT del alabe recién detectado.
  -------- FSM
  SIGNAL    we_i: STD_LOGIC_VECTOR(0 downto 0);
  SIGNAL    en_i: STD_LOGIC;
  --SIGNAL    dir_i : STD_LOGIC_VECTOR (10 downto 0);
  SIGNAL    dir_i : STD_LOGIC_VECTOR (13 downto 0);
  SIGNAL    douta_i :STD_LOGIC_VECTOR (15 downto 0);
  -------- FSM
  TYPE stateMemCon_t IS (	stEsperaCambioAlabe,			--Espera hasta detección
									
									stEsperoActualizariV2min,	--iV2min un ready un ciclo despues ciclo
									
									stFijarDirLimit,
									
									stEscribirLimit,	--Recalcula nuevo limit y lo guarda para la siguiente vez

									--stActualizarRegLimitWaitSt1,
									--stActualizarRegLimit,
									stFijarDirControl,
									
									stPreLeerControl,			
									--stLeerControlWaitSt1,
									stLeerControl,
									stAlmacenarControl,
									
									stFijarDirTCMin,
									
									stPreLeerTCMin,
									--stLeerTCMinWaitSt1,
									stLeerTCMin,
									stAlmacenarTCMin,
									stProcesarTCMin,
									--stEscribirTCMinWaitSt1,
									stEscribirTCMin,
									
									stFijarDirTCCurr,
									stEscribirTCCurr,
									--stEscribirTCCurrWaitSt1,
									stFijarDirTCMax,
									stPreLeerTCMax,
									--stPreLeerTCMaxWaitSt1,
									stLeerTCMax,
									stAlmacenarTCMax,
									stProcesarTCMax,
									--stEscribirTCMaxWaitSt1,
									stEscribirTCMax,
									stFijarDirTTmin,
									stPreLeerTTMin,
									--stLeerTTMinWaitSt1 ,
									stLeerTTMin,
									stAlmacenarTTMin,
									stProcesarTTMin,
									stEscribirTTMin,
									--stEscribirTTCurrWaitSt1,
									stFijarDirTTCurr,
									
									stEscribirTTCurr,
									
									stFijarDirTTMax,
									stPreLeerTTMax,
									
									stLeerTTMax,
									--stLeerTTMaxWaitSt1,
									stAlmacenarTTMax,
									stProcesarTTMax,
									
									stEscribirTTMax,
									
									stFijarDirControl2,
									
									--stPreAcutalizarRegControl,
									--stAcutalizarRegControlWaitSt1,
									stAcutalizarRegControl,
									
									stPasarDeAlabe,
									stFijarDirLimit2,
									
									stPreLeerLimitAlabe,
									stLeerLimitAlabe,
									stAlmacenarLimitAlabe,
									
									stEsperaInicial);
	signal currMCSt: stateMemCon_t := stEsperaInicial;
	signal nextMCst: stateMemCon_t := stEsperaInicial;
begin

--numalves <= x"92" when modo = '0' else numala; -- Constante 92h = 146
numalves <= numala; -- Constante 92h = 146

-- Operaciones de almacenamiento de los datos en la memoria
SYNC_PROC: PROCESS (clk) --just clock
BEGIN
	IF(rising_edge(clk)) THEN
		IF(reset = '1') THEN
			currMCSt <= stEsperaInicial;
			dir <=  (OTHERS => '1');
			douta <= (OTHERS=>'0');
			wea <= "0";
			ena <= '0';
		ELSE	
			currMCSt <= nextMCst;
			dir <= dir_i;
			douta <= douta_i;
			wea <= we_i;
			ena <= en_i;
		END IF;
	END IF;
END PROCESS;

--OUTPUT_DECODE: process (currMCSt,diraux,iV2Min,start,dina,datamx,con_ini,control,dataux,TCMinAux,TCMaxAux,dinTT_in,TTMinAux,TTMaxAux)
OUTPUT_DECODE: process (currMCSt,diraux,iV2Min,start,dina,datamx,con_ini,control,dataux,TCMinAux,TCMaxAux,dinTT_in,TTMinAux,TTMaxAux)
BEGIN
	CASE currMCSt IS
			WHEN  stEsperaCambioAlabe =>
					dir_i <= (OTHERS => '1');  --"11111111111";
					en_i <= '0';
					we_i <= "0";
			WHEN stEsperoActualizariV2min =>					
					en_i <= '0';
					we_i <= "0";
WHEN stFijarDirLimit =>
					dir_i <= diraux & offsetLimitAl;		--Off + 7	--y preparo el limit
					
					en_i <= '0';
					we_i <= "0";
			WHEN stEscribirLimit =>
					en_i <= '1';
					we_i <= "1";
					dir_i <= diraux & offsetLimitAl;		--Off + 7	--y preparo el limit
					--douta_i <= x"1333"; --Valor fijo
					--douta_i <= iV2Min  + iV2Min (15 downto 2);	--limit = minimo + 25%
					--douta_i <= iV2Min;	-- guardo el mínimo de V2 y empleo un limit fijo. (cambiar Calculo_TT para que lo haga y en este fichero dos veces)					
					--douta_i <= iV2Min  + iV2Min (15 downto 2);	--limit = minimo + 25%
                    --douta_i <= x"AAAA";
					--douta_i <= iV2Min  + iV2Min (15 downto 1);	--limit = minimo + 50%
					douta_i <= iV2Min  + iV2Min (15 downto 3);	--limit = minimo + 12.5%        
WHEN stFijarDirControl =>
dir_i <= diraux & offsetControl;	--Off + 0
en_i<= '0';
we_i <= "0";
			WHEN	stPreLeerControl =>
--			        dir_i <= diraux & offsetControl;	--Off + 0					
					en_i<= '1';
					we_i <= "0";	
			WHEN	stLeerControl =>
--			        dir_i <= diraux & offsetControl;	--Off + 0
					en_i<= '1';
					we_i <= "0";	
			WHEN	stAlmacenarControl =>
					if start = '1' then
						control <= dina;												-- Lectura dato y almacen_i en control si ha pasado una vuetla
					end if;
WHEN stFijarDirTCMin =>
					dir_i <= diraux & offsetTCMin; --Off + 1
en_i <= '0';
we_i <= "0";							
			WHEN stPreLeerTCMin =>
			        dir_i <= diraux & offsetTCMin; --Off + 1
					en_i <= '1';
					we_i <= "0";	
			WHEN 	stLeerTCMin =>
			        dir_i <= diraux & offsetTCMin; --Off + 1
					en_i <= '1';
					we_i <= "0";	
			WHEN stAlmacenarTCMin =>
                    en_i <= '1';
                    we_i <= "0";
                    dir_i <= diraux & offsetTCMin; --Off + 1
                    dataux <= dina;
			WHEN stProcesarTCMin =>
			en_i <= '0';					
--					if control (15) = '0' then
--						TCMinAux <= x"A5A5"; --(OTHERS => '1'); --"1111111111111111";							-- datamx;											-- Nuevo mínimo				
--					elsif datamx < dataux then
--						TCMinAux <= datamx;											-- Comparación y nuevo mínimo
--					else
--						TCMinAux <= dataux;											-- Continua el mismo valor que ya estaba almacen_ido
--					end if;
					
					--minCurrentTC <= datamx;
			WHEN stEscribirTCMin =>	--Y preparo par escibir current TC
					dir_i <= diraux & offsetTCMin;
					--douta_i <= x"1111";
					douta_i <= TCMinAux;
					we_i <= "1";
					en_i <= '1';
WHEN stFijarDirTCCurr =>
dir_i <= diraux & offsetTCCurr;	--Off + 2
en_i <= '0';					
we_i <= "0";
			WHEN  stEscribirTCCurr =>
dir_i <= diraux & offsetTCCurr;	--Off + 2					
					douta_i <= datamx;
					--douta_i <= x"2222";
					we_i <= "1";
					en_i <= '1';
WHEN stFijarDirTCMax =>
					dir_i <= diraux & offsetTCMax; --Off + 3
en_i <= '0';										
					we_i <= "0";
			WHEN stPreLeerTCMax =>
			        dir_i <= diraux & offsetTCMax; --Off + 3
					en_i <= '1';		
					we_i <= "0";		
			WHEN stLeerTCMax =>
			        dir_i <= diraux & offsetTCMax; --Off + 3
			        en_i <= '1';	
					we_i <= "0";					
			WHEN stAlmacenarTCMax =>
			        dir_i <= diraux & offsetTCMax; --Off + 3
			        we_i <= "0";
			        en_i <= '1';			
					dataux <= dina;
  
			WHEN stProcesarTCMax =>
en_i <= '0';
--					if control (15) = '0' then
--						TCMaxAux <= datamx;											-- Nuevo máximo					
--					elsif dataux < datamx then
--						TCMaxAux <= datamx;											-- Comparación y nuevo máximo
--					else
--						TCMaxAux <= dataux;											-- Continua el mismo valor
--					end if;
					
			WHEN stEscribirTCMax =>
					en_i <= '1';
					we_i <= "1";
					dir_i <= diraux & offsetTCMax; --Off + 3
					--douta_i <= x"3333";
					douta_i <= TCMaxAux;
WHEN stFijarDirTTMin =>
dir_i <= diraux & offsetTTMin;		--Off + 4
en_i <= '0';					
--we_i <= "0";
			WHEN stPreLeerTTMin =>
                    dir_i <= diraux & offsetTTMin;					
					we_i <= "0";
					en_i <= '1';
			WHEN  stLeerTTMin =>
                    dir_i <= diraux & offsetTTMin;		--Off + 4
                    we_i <= "0";
					en_i <= '1';
			WHEN stAlmacenarTTMin =>
			dir_i <= diraux & offsetTTMin;
						we_i <= "0";
                                en_i <= '1';
					dataux <= dina;												-- Lectura dato mínimo y almacen_i
                    

                    
			WHEN	stProcesarTTMin =>
en_i <= '0';			
--					if control (15) = '0' then
--						TTMinAux <= (OTHERS => '1'); --"1111111111111111";							-- dinTT;											-- Nuevo mínimo				
--					elsif dinTT < dataux then
--						TTMinAux <= dinTT;											-- Comparación y nuevo mínimo
--					else
--						TTMinAux <= dataux;											-- Continua el mismo valor
--					end if;
                    
			WHEN stEscribirTTMin =>	--Preparo para escribir siguiente TTCurr
			        dir_i <= diraux & offsetTTMin;       --Off + 4
			        --douta_i <= x"4444";
			        douta_i <= TTMinAux;
					we_i <= "1";
					en_i <= '1';
WHEN stFijarDirTTCurr =>
dir_i <= diraux & offsetTTCurr; -- Offs + 5
en_i <= '0';					
--we_i <= "0";
			WHEN stEscribirTTCurr =>
					--douta_i <= dinTT;
dir_i <= diraux & offsetTTCurr; -- Offs + 5
					--douta_i <= x"5555";
					douta_i <= dinTT_in;
					we_i <= "1";
					en_i <= '1';
WHEN stFijarDirTTMax =>
dir_i <= diraux & offsetTTMax;	--Offs + 6
en_i <= '0';					
--we_i <= "0";
			WHEN stPreLeerTTMax =>
dir_i <= diraux & offsetTTMax;	--Offs + 6			
					we_i <= "0";
					en_i <= '1';
			WHEN stLeerTTMax =>
			        dir_i <= diraux & offsetTTMax;	--Offs + 6
			        we_i <= "0";
					en_i <= '1';
			WHEN stAlmacenarTTMax =>
						      dir_i <= diraux & offsetTTMax;	--Offs + 6
						      we_i <= "0";
                              en_i <= '1';
					dataux <= dina;												-- Lectura dato y almacen_i en dataux

                      
			WHEN stProcesarTTMax =>
en_i <= '0';						
--					if control (15) = '0' then
--						TTMaxAux <= dinTT;											-- Nuevo máximo					
--					elsif dataux < dinTT then
--						TTMaxAux <= dinTT;											-- Comparación y nuevo máximo
--					else
--						TTMaxAux <= dataux;											-- Continua el mismo valor
--					end if;                    
			WHEN stEscribirTTMax =>

			        dir_i <= diraux & offsetTTMax;	--Offs + 6
			        --douta_i <= x"6666";
			        douta_i <= TTMaxAux;
					we_i <= "1";
					en_i <= '1';
			
WHEN stFijarDirControl2 =>
    dir_i <= diraux & offsetControl; --Off + 0
en_i <= '0';                      
--	 we_i <= "0";
			WHEN stAcutalizarRegControl =>

	dir_i <= diraux & offsetControl; --Off + 0
					en_i <= '1';
					we_i <= "1";
					--douta_i <= '1' & "0000000" & diraux (7 downto 0);			-- '1' start
					douta_i <= '1' & "0000" & diraux (10 downto 0);			-- '1' start
                    --douta_i <= x"8888";																							-- "0000000" no usado
																							-- dir_iaux número de álave comenzando en 0				
			WHEN stPasarDeAlabe =>		--arpovecho este estado para incrementar la dir_iaux
					en_i <= '0';
					we_i <= "0";
WHEN stFijarDirLimit2 =>
dir_i <= diraux & offsetLimitAl;	-- Off+7
en_i <= '0';					
--we_i <= "0";
			WHEN	stPreLeerLimitAlabe =>
dir_i <= diraux & offsetLimitAl;	-- Off+7					
					en_i <= '1';
					we_i <= "0";
			WHEN stLeerLimitAlabe =>
				    dir_i <= diraux & offsetLimitAl;	-- Off+7
					we_i <= "0";
					en_i <= '1';
			WHEN  stAlmacenarLimitAlabe => --Cargo el valor limite para el nuevo alabe
					if start = '1' then										-- 
						limitalabe <= dina;						
					else
						limitalabe <= cteLimitalabe;						-- No hemos dado una vuelta asi que usamos el de por defecto.
					end if;	
			WHEN  stEsperaInicial =>
					en_i <= '0';
					we_i <= "0";
		END CASE;
END PROCESS;
--NEXT_STATE_DECODE: PROCESS(clk, dinTC, dinTT, changeTT, reset, numala,V2min,
--									currMCSt,diraux,iV2min,start,dina,control, datamx,dataux,con_ini)
--NEXT_STATE_DECODE: PROCESS(clk, dinTC, dinTT, changeTT, reset, numala,V2min)	--Original

NEXT_STATE_DECODE: PROCESS(currMCSt,changeTT,con_ini)
BEGIN
	nextMCst <= currMCSt;	
	CASE currMCSt IS
		WHEN  stEsperaCambioAlabe =>
			if changeTT = '0' then
				nextMCst <= stEsperaCambioAlabe;
			else
				--nextMCst <= stEsperoActualizariV2min; 
				nextMCst <= stFijarDirControl; 
			end if;
		WHEN stEsperoActualizariV2min =>	--
			nextMCst <= stFijarDirLimit;
		WHEN stFijarDirLimit =>				--
			nextMCst <= stEscribirLimit;
		WHEN stEscribirLimit =>				--
			nextMCst <= stFijarDirControl;
		WHEN stFijarDirControl =>
			nextMCst <= stPreLeerControl;
		WHEN	stPreLeerControl =>
			nextMCst <= stLeerControl;
		WHEN 	stLeerControl =>
			nextMCst <= stAlmacenarControl;
		WHEN	stAlmacenarControl =>
			--nextMCst <= stFijarDirTCMin;
			nextMCst <= stFijarDirTCCurr;
		WHEN stFijarDirTCMin =>				--
			nextMCst <= stPreLeerTCMin;
		WHEN stPreLeerTCMin =>				--
			nextMCst <= stLeerTCMin;
		WHEN stLeerTCMin =>					--
			nextMCst <= stAlmacenarTCMin;	
		WHEN stAlmacenarTCMin =>			--
			nextMCst <= stProcesarTCMin;	
		WHEN stProcesarTCMin =>				--
			nextMCst <= stEscribirTCMin;
		WHEN stEscribirTCMin =>				--Y preparo par escibir current TC
			nextMCst <= stFijarDirTCCurr;
		WHEN stFijarDirTCCurr =>			
			nextMCst <= stEscribirTCCurr;				
		WHEN  stEscribirTCCurr =>
			--nextMCst <= stFijarDirTCMax;
			nextMCst <= stFijarDirTTCurr;
		WHEN stFijarDirTCMax =>				--
			nextMCst <= stPreLeerTCMax;
		WHEN stPreLeerTCMax =>				--
			nextMCst <= stLeerTCMax;
		WHEN stLeerTCMax =>					--
			nextMCst <= stAlmacenarTCMax;
		WHEN stAlmacenarTCMax =>			--
			nextMCst <= stProcesarTCMax;
		WHEN stProcesarTCMax =>				--
			nextMCst <= stEscribirTCMax;
		WHEN stEscribirTCMax =>				--
			nextMCst <= stFijarDirTTMin;
		WHEN  stFijarDirTTMin =>			--
			nextMCst <= stPreLeerTTMin;
		WHEN stPreLeerTTMin =>				--
			nextMCst <= stLeerTTMin;
		WHEN stLeerTTMin =>					--
			nextMCst <= stAlmacenarTTMin;
		WHEN stAlmacenarTTMin =>			--
			nextMCst <= stProcesarTTMin;
		WHEN	stProcesarTTMin =>			--
			nextMCst <= stEscribirTTMin;	
		WHEN stEscribirTTMin =>				--Preparo para escribir siguiente TTCurr
			nextMCst <= stFijarDirTTCurr;
		WHEN stFijarDirTTCurr =>
			nextMCst <= stEscribirTTCurr;
		WHEN stEscribirTTCurr =>
			--nextMCst <= stFijarDirTTMax; 
			nextMCst <= stFijarDirControl2;
		WHEN stFijarDirTTMax =>				--	
			nextMCst <= stPreLeerTTMax;				
		WHEN stPreLeerTTMax =>				--
			nextMCst <= stLeerTTMax;
		WHEN stLeerTTMax =>					--
			nextMCst <= stAlmacenarTTMax;
		WHEN stAlmacenarTTMax =>			--
			nextMCst <= stProcesarTTMax;
		WHEN stProcesarTTMax =>				--		
			nextMCst <= stEscribirTTMax;
		WHEN stEscribirTTMax =>				--
			nextMCst <= stFijarDirControl2;				
		WHEN stFijarDirControl2 =>
			nextMCst <= stAcutalizarRegControl;							
		WHEN stAcutalizarRegControl =>
			nextMCst <= stPasarDeAlabe;	
		WHEN stPasarDeAlabe =>					--arpovecho este estado para incrementar la diraux
			--nextMCst <= stFijarDirLimit2;
			nextMCst <= stEsperaCambioAlabe;
		WHEN stFijarDirLimit2 =>			--
			nextMCst <= stPreLeerLimitAlabe;			--Buscar valor limit para nuevo alabe
		WHEN	stPreLeerLimitAlabe =>		--
			nextMCst <= stLeerLimitAlabe;
		WHEN stLeerLimitAlabe =>			--
			nextMCst <= stAlmacenarLimitAlabe;
		WHEN  stAlmacenarLimitAlabe =>	--
			nextMCst <= stEsperaCambioAlabe;						--Cargo el valor limite para el nuevo alabe
		WHEN  stEsperaInicial =>
		--				if changeTT = '1' then											-- Cuenta el número de detecciones
		--					con_ini <= con_ini + '1';
		--				else
		--					con_ini <= con_ini;
		--				end if;					
			if con_ini > cteDetecciones then									-- Si el número de detecciones supera un valor comienza el almacenamiento
				nextMCst <= stEsperaCambioAlabe;
			else
				nextMCst <= stEsperaInicial;
			end if;
	END CASE;
END PROCESS;


--------------------------------------------

ProcesadoTCMin: PROCESS(clk)
BEGIN
    IF(rising_edge(clk)) THEN
        IF(reset = '1') then
            TCMinAux <= (OTHERS => '1'); 
        ELSIF currMCSt = stProcesarTCMin THEN
--            if control (15) = '0' then
            if start = '0' then
                TCMinAux <= (OTHERS => '1'); --"1111111111111111";							-- dinTT;											-- Nuevo mínimo				
            elsif datamx < dataux then
                TCMinAux <= datamx;											-- Comparación y nuevo mínimo
            else
                TCMinAux <= dataux;											-- Continua el mismo valor
            end if; 
        END IF;
    END IF;        
END PROCESS;


ProcesadoTCMax: PROCESS(clk)
BEGIN
    IF(rising_edge(clk)) THEN
        IF(reset = '1') then
            TCMaxAux <= (OTHERS => '0'); 
        ELSIF currMCSt = stProcesarTCMax THEN
            --if control (15) = '0' then
            if start = '0' then
                TCMaxAux <= (OTHERS => '0'); --"1111111111111111";							-- dinTT;											-- Nuevo mínimo				
            elsif datamx > dataux then
                TCMaxAux <= datamx;											-- Comparación y nuevo mínimo
            else
                TCMaxAux <= dataux;											-- Continua el mismo valor
            end if; 
        END IF;
    END IF;        
END PROCESS;

ProcesadoTTMin: PROCESS(clk)
BEGIN
    IF(rising_edge(clk)) THEN
        IF(reset = '1') then
            TTMinAux <= (OTHERS => '1'); 
        ELSIF currMCSt = stProcesarTTMin THEN
--            if control (15) = '0' then
            if start = '0' then
                TTMinAux <= (OTHERS => '1'); --"1111111111111111";							-- dinTT;											-- Nuevo mínimo				
            elsif dinTT_in < dataux then
                TTMinAux <= dinTT_in;											-- Comparación y nuevo mínimo
            else
                TTMinAux <= dataux;											-- Continua el mismo valor
            end if; 
        END IF;
    END IF;        
END PROCESS;

ProcesadoTTMax: PROCESS(clk)
BEGIN
    IF(rising_edge(clk)) THEN
        IF(reset = '1') then
            TTMaxAux <= (OTHERS => '0'); 
        ELSIF currMCSt = stProcesarTTMax THEN						
--            if control (15) = '0' then
              if start = '0' then
                TTMaxAux <= (OTHERS => '0');											-- Nuevo máximo					
            elsif dataux < dinTT_in then
                TTMaxAux <= dinTT_in;											-- Comparación y nuevo máximo
            else
                TTMaxAux <= dataux;											-- Continua el mismo valor
            end if;  
        END IF;
    END IF;        
END PROCESS;


-------------------------------------
--RegsitroDataux: PROCESS(clk) --que es dina en la lectura de la DPM
--BEGIN
--    IF(rising_edge(clk)) THEN
--        IF(reset = '1') then
--            dataux <= (OTHERS => '0'); 
--        ELSIF currMCSt = stAlmacenarTCMin OR currMCSt = stAlmacenarTCMax OR currMCSt = stAlmacenarTTMin OR currMCSt = stAlmacenarTTMax THEN						
--            dataux <= dina;						--dataux tiene lo leido de memoruia											-- Continua el mismo valor
--        ELSE 
--            dataux <= dataux; 
--        END IF;
--    END IF;        
--END PROCESS;

EvitarIniciales: PROCESS(clk)
BEGIN
    IF (rising_edge(clk)) THEN
        IF(reset = '1') THEN
            con_ini <= (OTHERS => '0');
        ELSIF currMCSt = stEsperaInicial THEN
            IF (changeTT = '1') THEN
                con_ini <= con_ini + '1';
            ELSE
                con_ini <= con_ini;
            END IF;
        END IF;
    END IF;
END PROCESS;
suma_diraux: PROCESS(clk)
BEGIN
	IF(rising_edge(clk)) THEN
		IF (reset = '1') THEN
			diraux <= (OTHERS => '0'); 
			start <= '0';
		ELSE
			IF currMCSt = stPasarDeAlabe THEN
				IF diraux + '1' = numalves then 
						diraux <= (OTHERS => '0') ; --"00000000";
						start <= '1';		--ya hemos dado una vuelta
					ELSE
						diraux <= diraux + '1';
					END IF;
			END IF;
		END IF;
	END IF;
END PROCESS;
--maxalabe:process(clk, dinTC, dinTT_in, changeTT, reset, numala)
maxalabe:process(clk)
begin
-- Selección del Tip Clearences MENOR XXXmayorXXX del álabe, o entre dos cambios de álabe (changeTT).
--if clk'event and clk = '1' then 
if rising_edge(clk) then 
	if reset = '1' then			--reset sincrono
		--estado <= "11111111";
		--diraux <= "00000000";
		--control <= "0000000000000000";
		-- TC MENOR
		AuxMax <= (OTHERS => '1');	--"1111111111111111"; --"0000000000000000";
		--con_ini <= "00000000";
		--start <= '0';
	else
		--	test (15 downto 0) <= control (15) & "0000000" & estado (7 downto 0);				-- Señal para pruebas
		test (15 downto 0) <= datamx (15 downto 0);
		--	test (15 downto 0) <= estado (7 downto 0) & con_ini (7 downto 0);
		if(start = '1') then --hemos dado la primera vuelta, empezamos a mirar
           if changeTT = '0' then
                --if dinTC > AuxMax then
                if dinTC < AuxMax then
                    AuxMax <= dinTC;
                else
                    AuxMax <= AuxMax;
                end if;
            else
                datamx <= AuxMax;				--datamx contiene el menor de los TC encontrados en el alabe
                AuxMax <= (OTHERS => '1');	 --"1111111111111111"; --"0000000000000000";
            end if;
          end if;
	end if;	
end if;
end process;

RegstrarV2Min:PROCESS(clk)
begin
if rising_edge(clk) then 
	if reset = '1' then			--reset sincrono
		iV2Min <= (OTHERS => '1');	
	else
		if changeTT = '1' then
			iV2Min <= V2Min;		--sumar 1 y ver 	
		end if;
	end if;	
end if;
end process;

RegstrarDinTT:PROCESS(clk)
begin
if rising_edge(clk) then 
	if reset = '1' then			--reset sincrono
		dinTT_in <= (OTHERS => '0');	
	else
		if changeTT = '1' then
			dinTT_in <= dinTT;		--sumar 1 y ver 	
		end if;
	end if;	
end if;
end process;

end Behavioral;

