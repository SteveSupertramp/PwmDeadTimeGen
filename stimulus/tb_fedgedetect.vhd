----------------------------------------------------------------------
-- Created by Microsemi SmartDesign Mon Oct 21 17:50:42 2019
-- Testbench Template
-- This is a basic testbench that instantiates your design with basic 
-- clock and reset pins connected.  If your design has special
-- clock/reset or testbench driver requirements then you should 
-- copy this file and modify it. 
----------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: tb_fedgedetect.vhd
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

entity tb_fedgedetect is
end tb_fedgedetect;

architecture behavioral of tb_fedgedetect is

-- Stimulus signals - signals mapped to the input and inout ports of tested entity
    signal nRESET   :   STD_LOGIC;
    signal CLOCK    :   STD_LOGIC;
    signal ENABLE   :   STD_LOGIC;
    signal DIN      :   STD_LOGIC;
 
-- Observed signals - signals mapped to the output ports of tested entity
    signal DOUT     :   STD_LOGIC;

    CONSTANT CLK_PERIOD  	: time :=  33 ns;  	-- 30 MHz 	   

    component fedgedetect
        -- ports
        port( 
            -- Inputs
            CLK     : in std_logic;
            EN      : in std_logic;
            nRST    : in std_logic;
            CH_IN   : in std_logic;

            -- Outputs
            CH_OUT  : out std_logic

            -- Inouts
        );
    end component;

begin

-- Unit Under Test port map
UUT : 	fedgedetect
    port map 
    (
        nRST    => nRESET,
        CLK     => CLOCK,
        EN      => ENABLE,
        CH_IN   => DIN,
        CH_OUT  => DOUT
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
    wait for 10 us;
    nRESET  <= '1' ;
    wait;
end process;   

CREATE_ENABLE:  process
begin
    ENABLE  <=  '0';
    wait for 15 us;
    ENABLE  <= '1' ; 
    wait;  
end process;

CREATE_DIN: process
begin
    DIN <= '0';
    wait for 2 us;
    DIN <= '1';
    wait for 2 us;
    DIN <= '0';
    wait for 20 us;
    DIN <= '1';
    wait for 22 us;
    DIN <= '0';
end process;
        
end behavioral;

