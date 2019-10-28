----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:02:20 04/12/2007 
-- Design Name: 
-- Module Name:    COUNTER - Behavioral 
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
library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;	
use ieee.std_logic_unsigned.all;

entity COUNTER IS
    generic(size: integer :=8); 
	port(	
		nRST     	: in  std_logic;  
		CLK     	: in  std_logic;
		EN        	: in  std_logic;
		START		: in  std_logic;
		STOP		: in  std_logic;	
		COUNT  		: out std_logic_vector (size-1 downto 0)
	);
end COUNTER;

architecture Behavioral OF COUNTER IS  

type  		CntStateType is (IDLE,COUNTING);
 
constant    FULL_SCALE		:   std_logic_vector(size-1 downto 0) := (others => '1');
constant 	RESET_ACTIVE 	: 	std_logic := '0';
constant 	LOW 			: 	std_logic := '0';
constant 	HIGH			: 	std_logic := '1';

signal 		Qtmp			: 	std_logic_vector(size-1 downto 0);
signal		next_state		:   CntStateType;
signal		current_state	:   CntStateType;	

begin
	
-- Processo che aggiorna gli stati del counter 
CNTSYNC_PROC: process (CLK, nRST)
begin
	if (nRST = RESET_ACTIVE) then
		current_state <= IDLE;	
	elsif(rising_edge(CLK)) then
			current_state <= next_state;
	end if;
end process;	

-- Processo transizione tra gli stati
SM_COUNTER:	process(CLK,nRST) 
begin	
	if(nRST = RESET_ACTIVE) then	
        Qtmp	   <= (others=>'0');	 
		next_state <= IDLE;
	elsif(CLK'event and CLK = '1') then 
			if(EN = HIGH)then		
				case current_state is
		
		 -- IDLE : contatore non attivo, in attesa impulso di START		
					when IDLE =>					
				
						Qtmp		<= (others=>'0');					
                        next_state <= IDLE; 
                    
                        if(STOP = '0') then                    
                            if(START = HIGH) then		-- 	segnale di START attivo	 			
                                next_state <= COUNTING; 	
                            end if;    
                        end if;	
	
		-- COUNT : conta fino a quando non vede attivo il segnale di STOP o arriva a fondo scala         
        			when COUNTING =>
                        if(STOP = HIGH)  then
							Qtmp		<= (others=>'0');
							next_state  <= IDLE; 	
                        elsif(Qtmp = FULL_SCALE) then
                                Qtmp		<= (others=>'0'); 		
                                next_state <= COUNTING;
                            else
                                Qtmp <= Qtmp + '1';
                                next_state <= COUNTING;
                            end if;                            					
				end case;
            end if;
	end if;		
end process;		

COUNT <= Qtmp;
  
end Behavioral;
