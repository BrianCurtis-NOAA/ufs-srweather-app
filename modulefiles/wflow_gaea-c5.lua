help([[
This module loads python environement for running the UFS SRW App on
the NOAA RDHPC machine Gaea C5
]])

whatis([===[Loads libraries needed for running the UFS SRW App on gaea ]===])

unload("python")

load("conda")
prepend_path("MODULEPATH","/lustre/f2/dev/role.epic/contrib/C5/rocoto/modulefiles")
load("rocoto")

pushenv("MKLROOT", "/opt/intel/oneapi/mkl/2023.1.0/")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate srw_app
]===])
end
