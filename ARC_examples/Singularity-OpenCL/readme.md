# Singularity - OpenCL example

This example shows a Singularity recipe for a container which can be used to compile and execute OpenCL programs
## To build
```
sudo singularity build my_singularity_env.simg OpenCL-dev.recipe
```
## To use
```
singularity exec --nv my_singularity_env.simg sh program.sh
```

# Singularity - custom environment

This example shows how to use Singularity containers as portable environment containers.
Take a look under the following link for more details on how to create an image of a container.
https://singularity.lbl.gov/docs-build-container
For development purposes a sandbox approach is recommended.

## Sandbox mode for building an Singularity image
For final containers it is recommended to write a **Singularity recipe**, to encapsulate the actual steps required to create a needed image. This improves reproducibility and transparency of a container.

It is advised to start from an image which covers certain dependencies which are needed for your development. Example for OpenCL: docker://nvidia/opencl:latest

- Start from a desired image
```
sudo singularity build --sandbox sandbox/ docker://nvidia/opencl:latest
```  
- Then, use the interactive mode to install and test all the needed dependencies (Using apt install, ...)
```
sudo singularity shell --writable sandbox/
```
*--writable* option allows for changes to be saved after exiting from the shell mode

- After the container was modified to fit the needs of development and/or execution of programs, create an image of it
```
singularity build --sandbox sandbox/ my_singularity_env.simg
``` 

## Usage
After the image was created, copy it to  **Singularity/my_singularity_env.simg** and modify the **program.sh** script which will be executed inside the environment of the image.
