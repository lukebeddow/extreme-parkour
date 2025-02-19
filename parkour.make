# ----- key user defined variables ----- #

# docker build variables
IMAGE_NAME = motion-predictor-parkour
CONTAINER_NAME = motion-predictor-parkour
DOCKERFILE = parkour.dockerfile

# define file structure for mounting into docker
WORKDIR = src
CONFDIR = configs
OUTDIR = outputs
WANDB = wandb_api_key

# runtime variables for docker
PORT = 8888
GPU_FLAG = --gpus device=1

# ----- information for available commands ------ #

# Default target
.PHONY: help
help:
	@echo "Usage:"
	@echo "  make build           - Build the Docker image"
	@echo "  make run             - Run the container with GPU support"
	@echo "  make shell           - Open an interactive shell inside the container"
	@echo "  make jupyter         - Run Jupyter Notebook with GPU support"
	@echo "  make stop            - Stop the running container"
	@echo "  make clean           - Remove the Docker image and clean up"

# ----- inferred variables ----- #

# define the files to mount in the docker container (and add permissions)
MOUNT = -v $(PWD)/$(WORKDIR):/workspace/$(WORKDIR)/ \
				-v $(PWD)/$(CONFDIR):/workspace/$(CONFDIR)/ \
				-v $(PWD)/$(OUTDIR):/workspace/$(OUTDIR)/:rw \
				--env-file $(WANDB)

# ----- command definitions ----- #

# Build the Docker image
.PHONY: build
build:
	docker build -t $(IMAGE_NAME) -f $(DOCKERFILE) .

# Run the container with GPU support
.PHONY: run
run:
	docker run --rm $(GPU_FLAG) $(MOUNT) $(IMAGE_NAME)

# Open an interactive shell in the container
.PHONY: shell
shell:
	docker run -it --rm $(GPU_FLAG) $(MOUNT) $(IMAGE_NAME) bash

# Run Jupyter Notebook with GPU support 
.PHONY: jupyter
jupyter:
	docker run --rm $(GPU_FLAG) -p $(PORT):8888 $(MOUNT) $(IMAGE_NAME) \
		jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token=''

# Stop the running container (if detached mode is used in future)
.PHONY: stop
stop:
	-docker stop $(CONTAINER_NAME)

# Clean up the Docker image
.PHONY: clean
clean:
	-docker rmi $(IMAGE_NAME)

# Run training script inside the container with custom arguments
.PHONY: train
train:
	docker run --rm $(GPU_FLAG) $(MOUNT) \
		$(IMAGE_NAME) python /workspace/train.py --headless --exptid exp-luke-parkour \
		--num_envs 2048 --proj_name trustline-mp-parkour \
		$(ARGS)