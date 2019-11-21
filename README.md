# container-tools

It's expectd each tool will be located in its own directory with name cmd.sh. For example under directory cyclictest, the cmd.sh is the entrance for cyclictest. For testpmd there will be a directory testpmd with cmd.sh under that directory.

The run.sh under the repo root diretory is the entrance for the container image. Once it is started, it will git pull this repo to get the latest tools. It then executes the specified tool basen on the yaml specification, with the enviroment variables in the yaml file.

The whole purpose of this repo is to keep the same container image while the tools can be updated.
