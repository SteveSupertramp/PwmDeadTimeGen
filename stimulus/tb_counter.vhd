----------------------------------------------------------------------
-- Created by Microsemi SmartDesign Tue Oct 22 14:13:56 2019
-- Testbench Template
-- This is a basic testbench that instantiates your design with basic 
-- clock and reset pins connected.  If your design has special
-- clock/reset or testbench driver requirements then you should 
-- copy this file and modify it. 
----------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: tb_counter.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- <Description here>
--
-- Targeted device: <Family::IGLOO2> <Die::M2GL005> <Package::144 TQ>
-- Author: <Name>
--
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

entity tb_counter is
end tb_counter;

architecture behavioral of tb_counter is

    constant    CLK_PERIOD  	: time :=  33 ns;  	-- 30 MHz 	      
    constant    CNTWIDHT        : integer := 4;

    component COUNTER is
        generic (size: integer := 8);
        -- ports
        port( 
            -- Inputs
            nRST     	: in  std_logic;  
            CLK     	: in  std_logic;
            EN        	: in  std_logic;
            START		: in  std_logic;
            STOP		: in  std_logic;	
            -- Outputs
            COUNT  		: out std_logic_vector (size-1 downto 0)            
        );
    end component;

-- Stimulus signals - signals mapped to the input and inout ports of tested entity
    signal nRESET   :   STD_LOGIC;
    signal CLOCK    :   STD_LOGIC;
    signal ENABLE   :   STD_LOGIC;
    signal START    :   STD_LOGIC;
    signal STOP     :   STD_LOGIC;
    
-- Observed signals - signals mapped to the output ports of tested entity
    signal QCOUNT   :   STD_LOGIC_VECTOR(CNTWIDHT-1 downto 0);
    
begin

-- Unit Under Test port map
UUT : 	COUNTER
    generic map(CNTWIDHT)
    port map 
    (
        nRST    => nRESET,
        CLK     => CLOCK,
        EN      => ENABLE,
        START   => START,
        STOP    => STOP,
        COUNT   => QCOUNT       
    );

CREATE_CLK : process
begin
	CLOCK <= '0';
	wait for (CLK_PERIOD/2);
	CLOCK <= '1';
	wait for (CLK_PERIOD/2);
end process;

CREATE_RESET:	process
begin		
    nRESET  <= '0' ;
    wait for 1 us;
    nRESET  <= '1' ;
    wait for 40 us;
    nRESET  <= '0' ; 
    wait;
    end process;   

CREATE_ENABLE:  process
begin
    ENABLE  <=  '0';
    wait for 10 us;
    ENABLE  <= '1' ; 
    wait;  
end process;

CREATE_START: process
begin
    START   <= '0';
    wait for 20 us;
    START   <= '1' ; 
    wait ;  
end process;

CREATE_STOP: process
begin
    STOP   <= '0';
    wait for 50 us;
    STOP   <= '1' ; 
    wait;  
end process;

end behavioral;
