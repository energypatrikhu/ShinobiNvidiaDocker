# Shinobi CCTV on NVIDIA Docker

Nvidia Enabled Docker Image for Shinobi CCTV. Based on https://gitlab.com/Shinobi-Systems/Shinobi

Original repo: https://gitlab.com/Shinobi-Systems/ShinobiNvidiaDocker

### (!!!) Versions:
- docker image: nvidia/cuda:11.3.1-cudnn8-runtime-ubuntu20.04
- nvidia driver version: 470
- cuda version: 11
- cudnn version: 8
- ffmpeg version: 4.2.7
- nodejs version: 21

### How to Dock Shinobi

>  `docker` with `compose` plugin should already be installed.

1. Setup NVIDIA Container Toolkit
    - https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

2. Clone the Repo and enter the `ShinobiNvidiaDocker` directory.
    ```
    git clone https://github.com/energypatrikhu/Shinobi.git ShinobiNvidiaDocker && cd ShinobiNvidiaDocker
    ```

3. Spark one up.
    ```
    sh start-image.sh
    ```

4. Open your computer's IP address in your web browser on port `8080`. Open the superuser panel to create an account.
    ```
    Web Address : http://xxx.xxx.xxx.xxx:8080/super
    Username : admin@shinobi.video
    Password : admin
    ```

5. After account creation head on over to the main `Web Address` and start using Shinobi!
    ```
    http://xxx.xxx.xxx.xxx:8080/
    ```

6. Enjoy!
