##################################### Fci ######################################
s /MTGI/FCI/IpcL0/L0FciApe
s /MTGI/FCI/IpcL0/L0FciAfd
s /MTGI/Common/IpcL0/L0PlatApe
sa /MTGI/Common/IpcL0/L0HktmApe packetLogAccInterval=60;MMEpacketLogAccInterval=90
s /MTGI/Common/IpcL0/L0DumpRptApe
sa /MTGI/FCI/IpcL1/L1bFciApe repeatCycle=1
sa /MTGI/FCI/IpcL1/L1cFciApe repeatCycle=1
sa /MTGI/FCI/IpcL1/L1FciQL repeatCycle=1
s /MTGI/FCI/rules/FciChainRules

###################################### Li ######################################
s /MTGI/LI/IpcL0/L0LiApe
s /MTGI/LI/IpcL0/L0LiAfd
sa /MTGI/LI/IpcL1/L1LiBkgApe repeatCycle=1;processingTimeout=630
sa /MTGI/LI/IpcL1/L1LiEventsApe repeatCycle=1;processingTimeout=630
sa /MTGI/LI/IpcL1/L1LiLmkApe repeatCycle=1
sa /MTGI/LI/IpcL1/L1LiInrApe repeatCycle=1
sa /MTGI/LI/IpcL1/L1LiGeocalibApe repeatCycle=1
s /MTGI/LI/IpcL1/L1BkgLiAfd4L2Pf
sa /MTGI/LI/IpcL1/L1EvtsLiAfd4L2Pf mode=L1_1B_EVT_L2PF

#################################### Other #####################################
session-details

s /pi/coreServices/coreServices
s /pi/coreServices/ftpRecover

s /links/mc/NOMINAL2RECONF
s /links/mc/RECONF2NOMINAL

sa /links/mc/setLink paramPath=/links/mc/mda/FciInstData/fci/linkCommand;value=CONNECT_LINK
sa /links/mc/setLink paramPath=/links/mc/mda/FciInstData/fci/linkCommand;value=DISCONNECT_LINK

sa /Test/performanceStub lockTest=true;lockDatasetDuration=60;lockTestReader=false;
sa /Test/performanceStub lockTest=true;lockDatasetDuration=60;lockTestReader=false;lockTimeout=5

sa /Test/performanceStub lockTest=true;lockDatasetDuration=10;lockTestDatasetId=A;lockTestReader=false
sa /Test/performanceStub lockTest=true;lockDatasetDuration=10;lockTestDatasetId=B;lockTestReader=false
sa /Test/performanceStub lockTest=true;lockDatasetDuration=10;lockTestDatasetId=A;lockTestReader=true
