----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    09:49:42 04/04/2007
-- Design Name:
-- Module Name:    REdgeDetect - Behavioral
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity RedgeDetect is
    Port (	CLK    	: in    STD_LOGIC;
			EN		: in    STD_LOGIC;
         	nRST    : in    STD_LOGIC;
			CH_IN  	: in    STD_LOGIC;
			CH_OUT 	: out   STD_LOGIC
		);
end RedgeDetect;

architecture Behavioral of RedgeDetect is

CONSTANT RESET_ACTIVE 	: std_logic := '0';

SIGNAL CH_OLD: std_logic_vector(1 downto 0);

BEGIN

PROCESS(CLK,nRST,EN)
BEGIN
	IF (nRST=RESET_ACTIVE) THEN
		CH_OUT <= '0';
		CH_OLD <= "00";	
	ELSIF   (EN'event AND EN = '1') THEN
                IF (CH_IN = '1') THEN
                    CH_OLD <= "11";
                END IF;
    ELSIF   (CLK'event AND CLK = '1') THEN	
                IF(EN = '1') THEN
                    CH_OLD(1) 	<= CH_OLD(0);				
                    CH_OLD(0) 	<= CH_IN;
                    CH_OUT 		<= CH_OLD(0) and (not CH_OLD(1));
                END IF;	
	END IF ;
END PROCESS;

end Behavioral;

