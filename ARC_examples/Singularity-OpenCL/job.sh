#!/bin/sh

# Custom container image (--nv switch exposes required libraries to be able to access NVidia GPUs from within the container)
singularity exec --nv my_singularity_env.simg sh program.sh
# Or, image from online source
# singularity exec --nv docker://nvidia/opencl:latest

# End of program
exitcode=$?
echo Program ended with code $exitcode.

exit $exitcode
