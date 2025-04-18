#!/usr/bin/env bash

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# This is in case there's any special installs or overrides that needs to occur when starting the machine before starting ComfyUI
if [ -f "/workspace/additional_params.sh" ]; then
    chmod +x /workspace/additional_params.sh
    echo "Executing additional_params.sh..."
    /workspace/additional_params.sh
else
    echo "additional_params.sh not found in /workspace. Skipping..."
fi

# Set the network volume path
NETWORK_VOLUME="/workspace"

# Check if NETWORK_VOLUME exists; if not, use root directory instead
if [ ! -d "$NETWORK_VOLUME" ]; then
    echo "NETWORK_VOLUME directory '$NETWORK_VOLUME' does not exist. You are NOT using a network volume. Setting NETWORK_VOLUME to '/' (root directory)."
    NETWORK_VOLUME="/"
    echo "NETWORK_VOLUME directory doesn't exist. Starting JupyterLab on root directory..."
    jupyter-lab --ip=0.0.0.0 --allow-root --no-browser --NotebookApp.token='' --NotebookApp.password='' --ServerApp.allow_origin='*' --ServerApp.allow_credentials=True --notebook-dir=/ &
else
    echo "NETWORK_VOLUME directory exists. Starting JupyterLab..."
    jupyter-lab --ip=0.0.0.0 --allow-root --no-browser --NotebookApp.token='' --NotebookApp.password='' --ServerApp.allow_origin='*' --ServerApp.allow_credentials=True --notebook-dir=/workspace &
fi

git clone https://github.com/Hearmeman24/runpod-diffusion_pipe.git
mv runpod-diffusion_pipe/src/start.sh /
mv runpod-diffusion_pipe/joy_caption_runner.sh /
mv runpod-diffusion_pipe/video_captioner.sh /

chmod +x runpod-webui/send_lora.sh
mv runpod-webui/send_lora.sh /usr/local/bin

git clone --recursive https://github.com/bmaltais/kohya_ss.git

mkdir -p $NETWORK_VOLUME/image_dataset_here

if [ "$download_base_sdxl" == "true" ]; then
  echo "Downloading Base SDXL"
  mkdir -p $NETWORK_VOLUME/models
  huggingface-cli download timoshishi/sdXL_v10VAEFix sdXL_v10VAEFix.safetensors --local-dir $NETWORK_VOLUME/kohya_ss/models 2>&1 | tee download_log.txt
  echo "Finished downloading base SDXL"
fi


if [ "$download_flux" == "true" ]; then
  if [ -z "$HUGGING_FACE_TOKEN" ] || [ "$HUGGING_FACE_TOKEN" == "token_here" ]; then
    echo "Error: HUGGING_FACE_TOKEN is set to the default value 'token_here' or doesn't exist. Please update it in RunPod's environment variables or set it on your own."
    exit 1
  fi

  echo "HUGGING_FACE_TOKEN is set."
  echo "Downloading Flux"
  mkdir -p $NETWORK_VOLUME/models/flux
  huggingface-cli download black-forest-labs/FLUX.1-dev --local-dir /models/flux --repo-type model --token "$HUGGING_FACE_TOKEN" 2>&1 | tee download_log.txt
  echo "Finished downloading Flux"
fi

cd kohya_ss
./setup-runpod.sh
./gui.sh --listen=0.0.0.0 --headless

sleep infinity
