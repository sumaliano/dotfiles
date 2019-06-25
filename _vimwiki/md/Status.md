# Status

Mathias:
an unpacker capable of unpacking data from 5 ADCs in 
/u/land/lynx.landexp/sis3316_test/feb2014_sis3316/ucesb/exps/sis3316_test
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Stefanos:
 file teststruck0014.lmd in the same directory
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Oleg:
 The code with clock synchronization is in:
/land/usr/land/landexp/sis3316_test/feb2014_sis3316/vme/crate3_multimod 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 -- Currently the vme crate is on and the same tail pulse is split and sent to the two first channels of the first SIS3316 module.
 
 -- The RIO is R4-49

The MBS code is, currently set to read two enabled channels from the first digitizer:-- /u/land/lynx.landexp/spaschal/feb2014_sis3316/vme/crate3

-- The unpacker code is:/u/land/nup_sp/unpackexps/tagtest_sis3316
When you find bugs, solve problems etc. please let us all know.

PLEASE MAKE YOUR COPY BEFORE MODIFYING

-- An example file with the split pulse is in the same directory:teststruck0007.lmdteststr7.root

Modules' addresses installed in the VME crate:0x03000000 .... 0x08000000and0x90000000

A screen session was running on lxlandcons2, but I see I cannot connect from outside. You can start a new one andlet us know, there was nothing running on the previous one.

-- I am sending two example plots. The second shows the correlation of the charge calculation donefor the two channels. Looks very nice to me.
We resume the meeting on Tuesday and see how to proceed. 


