# LAND02

	/u/land/s438b/land02/s438
	/u/land/jsilva/land02/s438

You need to have your lmd-Files in a directory structure like

	/whatever/s438/lmd/whatever.lmd 

	In lxg0897/8/9: ~/jsilva/land02/s438

#### ACTAR:
	
	./paw_ntuple /SAT/hera/land/actar/stitched/actar_main_run110_all_stitched.lmd --paw-ntuple=RAW:AT,/SAT/hera/land/actar/root/actar_run110_all_stitched.root
XB:
	./paw_ntuple /SAT/hera/land/actar/stitched/actar_main_run110_all_stitched.lmd --paw-ntuple=SYNC:XB,/SAT/hera/land/actar/root/xb_run110_all_stitched.root
ACTAR and XB: 
	
	./paw_ntuple /SAT/hera/land/actar/stitched/actar_main_run110_all_stitched.lmd --paw-ntuple=RTS,SYNC:XB,RAW:AT,/SAT/hera/land/actar/root/xb_actar_run110_all_stitched.root
