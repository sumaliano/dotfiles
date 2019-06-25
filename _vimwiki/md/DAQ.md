# DAQ

## RIO:

	connect: rsh -lland r4-11
	pasword: n3utr0n2004


## DAQ files:

	/u/land/lynx.landexp/bloeher/oct2012sis3216/vme/create3  → editing
	/land/user/land/landexp/bloeher/oct2012sis3216/vme/create3	→ starting


## MBS:

	$ mbs → start
	$ exit → exit
	$ resl → reset

	*.scom → are script files for mbs

#### Inside mbs(when running):

	$ @start_standalone
	$ (sta acq)
	$ (connect rfio lxir016 -diskserver) (other RFIO servers -> lxir016; lxg0898)
	$ open file -rfio -auto		 OR		open file /path/to/file.lmd -rfio
	$ show acq(uisition)
	$ close file
	$ (sto acq)

	$ less mbslog.l → tells you everything
	$ less filenumber.set → define the file number

## Streaming:

		/path/to/unpacker stream://r4-11 --ntuple=/path/to/rootfile.root

## Trigger:

	R4-49:/land/usr/land/landexp/apr2014/r4-49 74$ tridictrl --print-config

	../trloii/trloctrl/fw_880c30c5_tridi/tridi_ctrl_RIO4 --addr=2 --help

	../trloii/trloctrl/fw_880c30c5_tridi/tridi_ctrl_RIO4 --addr=2 --show=src

## Scalers (udp_reader):

	$ ssh land@lxi049
	$ cd /path/to/daq/udp_reader
	$ ./udpreader

## Trigger hist:

	tridictrl --tracer > path/to/tracer_00?.out  (from the RIO)


