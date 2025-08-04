help([[
This module loads the RStudio Server environment which utilizes a Singularity
image for portability.
]])

whatis([[Description: RStudio Server environment using Singularity]])

local root = "/uufs/chpc.utah.edu/sys/installdir/rstudio-singularity/4.1.2"
-- local bin = pathJoin(root, "/bin")
local img = pathJoin(root, "ood-rstudio-geo-rocker_4.1.2.sif")
local library = pathJoin(root, "/library-ood-4.1")

local user_library = os.getenv("HOME") .. "/R/library-ood-rocker-4.1"

depends_on("singularity")
-- prepend_path("PATH", bin)
prepend_path("RSTUDIO_SINGULARITY_BINDPATH", library .. ":/library", ",")
setenv("RSTUDIO_SINGULARITY_IMAGE", img)
setenv("RSTUDIO_SINGULARITY_CONTAIN", "1")
setenv("RSTUDIO_SINGULARITY_HOME", os.getenv("HOME") .. ":/home/" .. os.getenv("USER"))
setenv("R_LIBS_USER", user_library)
setenv("R_ENVIRON_USER",pathJoin(os.getenv("HOME"),".Renviron.OOD")) 

-- Note: Singularity on CentOS 6 fails to bind a directory to `/tmp` for some
-- reason. This is necessary for RStudio Server to work in a multi-user
-- environment. So to get around this we use a combination of:
--
--   - SINGULARITY_CONTAIN=1 (containerize /home, /tmp, and /var/tmp)
--   - SINGULARITY_HOME=$HOME (set back the home directory)
--   - SINGUARLITY_WORKDIR=$(mktemp -d) (bind a temp directory for /tmp and /var/tmp)
--
-- The last one is called from within the executable scripts found under `bin/`
-- as it makes the temp directory at runtime.
--
-- If your system does successfully bind a directory over `/tmp`, then you can
-- probably get away with just:
--
--   - SINGULARITY_BINDPATH=$(mktemp -d):/tmp,$SINGULARITY_BINDPATH

-- wrappers to execute the container in a non-OOD environment
set_shell_function("Rshell",'singularity shell -s /bin/bash ' .. img,"singularity shell -s /bin/bash " .. img)
set_shell_function("R",'singularity exec ' .. img .. ' R $@',"singularity exec " .. img .. " R $*")
set_shell_function("Rscript",'singularity exec ' .. img .. ' Rscript $@',"singularity exec " .. img .. " Rscript $*")
-- to export the shell function to a subshell
if (myShellName() == "bash") then
 execute{cmd="export -f Rshell",modeA={"load"}}
 execute{cmd="export -f R",modeA={"load"}}
 execute{cmd="export -f Rscript",modeA={"load"}}
else -- tcsh needs to unalias, this does not seem to happen with the set_shell_function
 execute{cmd="unalias Rshell",modeA={"unload"}}
 execute{cmd="unalias R",modeA={"unload"}}
 execute{cmd="unalias Rscript",modeA={"unload"}}
end

