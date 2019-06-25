# STICHING

#### From Land02:

Join files for each system:

	/u/land/current/unpacker/empty/empty actar_runNNN_*.lmd --output=actar_runNNN_all.lmd
	/u/land/current/unpacker/empty/empty main_runNNN_*.lmd --output=main_runNNN_all.lmd

Merge and time-stitch in one go:

	/u/land/current/unpacker/empty/empty --merge=titris,2 actar_runNNN_all.lmd main_runNNN_all.lmd --output=- | /u/land/current/unpacker/empty/empty --time-stitch=20 --file=- --output=actar_main_runNNN_all.lmd

Really difficult to join files without storing on disk without losing any events (one could setup a server for each and read from them, but meh...). 

	/u/htoernqv/toys/unpacker/empty/empty -> works on lxgs08

#### join: ===============================
(on any empty unpacker)

	/u/land/current/unpacker/empty/empty /SAT/hera/land/apr2014/actar/sub/lmd/run110_* --output=/SAT/hera/land/actar/s438/lmd/actar_run110_all.lmd

	/u/land/current/unpacker/empty/empty /SAT/hera/land/apr2014/lmd/run110_* --output=/SAT/hera/land/actar/s438/lmd/main_run110_all.lmd

#### merge: ===============================
(on land@lxfs162 or land@lxfs186)

	/u/land/current/unpacker/empty/empty --merge=titris,2 /SAT/hera/land/actar/s438/lmd/actar_run110_all.lmd /SAT/hera/land/actar/s438/lmd/main_run110_all.lmd --output=/SAT/hera/land/actar/s438/lmd/actar_main_run110_all_merged.lmd

(if you want to use your own machine recompile the empty unpacker with: make USE_MERGING=1 empty/empty)

#### stitch: ============================= 
(on land@lxfs162 or land@lxfs186)

	/u/land/current/unpacker/empty/empty --time-stitch=20 /SAT/hera/land/actar/merged/actar_run110_all_merged.lmd --output=/SAT/hera/land/actar/s438/lmd/actar_main_run110_all_stiched.lmd

#### merge and stitch in one go: =========

	/u/land/current/unpacker/empty/empty --merge=titris,2 /SAT/hera/land/actar/s438/lmd/actar_run110_all.lmd /SAT/hera/land/actar/s438/lmd/main_run110_all.lmd --output=- | /u/land/current/unpacker/empty/empty --time-stitch=20 --file=- --output=/SAT/hera/land/actar/s438/lmd/actar_main_run110_all_stitched.lmd

	/u/land/current/unpacker/empty/empty /SAT/hera/land/apr2014/lmd/run110_* --output=/SAT/hera/land/actar/s438/lmd/main_run110_all.lmd
