# Shinobi CCTV on NVIDIA Docker

Nvidia Enabled Docker Image for Shinobi CCTV. Based on https://gitlab.com/Shinobi-Systems/Shinobi

### (!!!) Versions:
- nvidia driver version: 470
- cuda driver version: 470
- cuda version: 11.4
- cudnn version: 9
- nv-headers version: 11.1.5.3
- ffmpeg version: 6.1.1
- nodejs version: 21

### Building
Build time depends on system, but it can be between 30 minutes to even 1 hour.

### How to Dock Shinobi

>  `docker` with `compose` plugin should already be installed.

1. Clone the Repo and enter the `docker-shinobi` directory.
    ```
    git clone https://github.com/energypatrikhu/Shinobi.git ShinobiNvidiaDocker && cd ShinobiNvidiaDocker
    ```

2. Spark one up.
    ```
    sh start-image.sh
    ```

3. Open your computer's IP address in your web browser on port `8080`. Open the superuser panel to create an account.
    ```
    Web Address : http://xxx.xxx.xxx.xxx:8080/super
    Username : admin@shinobi.video
    Password : admin
    ```

3. After account creation head on over to the main `Web Address` and start using Shinobi!
    ```
    http://xxx.xxx.xxx.xxx:8080/
    ```
4. Enjoy!