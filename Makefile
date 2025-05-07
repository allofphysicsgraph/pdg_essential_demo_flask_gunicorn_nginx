# Ben Payne
# Physics Derivation Graph
# https://allofphysics.com

# Get the machine architecture.
# On arm64 (Apple Silicon M1/M2/etc.), `uname -m` outputs "arm64".
# On amd64 (Intel), `uname -m` outputs "x86_64".
ARCH := $(shell uname -m)

ifeq ($(ARCH), arm64)
        this_arch=arm64
else ifeq ($(ARCH), x86_64)
        this_arch=amd64
else
        @echo "Unknown architecture: $(ARCH). Cannot determine if Mac is new or old."
endif


webserver_image=demo_flask_gunicorn_ngingx

container=docker
#container=podman

#
.PHONY: help docker

help:
	@echo "make help"
	@echo "      this message"
	@echo "==== Targets outside container ===="
	@echo ""
	@echo "make container"
	@echo "      build image and then enter container shell"
	@echo ""
	@echo "make container_build"
	@echo "      build image"
	@echo ""
	@echo "make container_live"
	@echo "      enter container shell"
	@echo ""
	@echo "make up"
	@echo "      build and run $(container)"
	@echo ""

# create and start the webserver. This will build the Docker image if that's needed
up:
	if (! $(container) stats --no-stream ); then  open /Applications/Docker.app; while (! $(container) stats --no-stream ); do    echo "Waiting for Docker to launch...";  sleep 1; done; fi;
	$(container) ps
	if [ `$(container) ps | wc -l` -gt 1 ]; then \
	       	$(container) kill $$($(container) ps -q); \
		fi
	$(container) ps
	$(container) run --rm \
                -w /code \
                -p 5000:5000 \
                $(webserver_image) gunicorn --chdir /code \
                                            --workers 4 \
                                            --bind 0.0.0.0:5000 \
                                            --log-level debug \
                                            --access-logfile - \
                                            --capture-output \
                                            wsgi:web_app

# --chdir /code      : change the working directory before the application is loaded.
# --access-logfile - : configure Gunicorn to log Flask application output to stdout
# --log-level debug  : for options see https://docs.gunicorn.org/en/stable/settings.html#loglevel
# --capture-output   : capture print statements and other standard output from the Flask application


container: container_build container_live

# https://docs.docker.com/build/building/multi-platform/
container_build:
	$(container) build -t $(webserver_image) .

container_live:
	$(container) run -it --rm \
                -v `pwd`:/scratch -w /scratch/ \
                --user $$(id -u):$$(id -g) \
                $(webserver_image) /bin/bash


#EOF
