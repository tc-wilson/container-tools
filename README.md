# container-tools

The whole purpose of this repo is to keep the same container image without rebuild while the tools can be updated.

It's expectd each tool will be located in its own directory with name cmd.sh. For example under directory cyclictest, the cmd.sh is the entrance for cyclictest. For testpmd there will be a directory testpmd with cmd.sh under that directory. The tool script should expect its arguments/options via enviroment variables.

The run.sh under the repo root diretory is the entrance for the container image. Once it is started, it will git pull this repo to get the latest tools. It then executes the specified tool based on the yaml specification, with the enviroment variables in the yaml file. The yaml examples for k8s can be found under the sample-yamls/ directory

