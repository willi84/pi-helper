# How to setup Raspberry Pi OS
1. Download and install the [Raspberry Pi Imager](https://www.raspberrypi.com/software/) on your computer.
2. Insert your SD card into your computer and open the Raspberry Pi Imager.
3. Select the Raspberry Pi OS (64-bit) as the operating system and choose your SD card as the storage device.
4. Click on the "Advanced options" (the gear icon)
    - Storage: use your SD card
    - hostname: e.g. "my-pi"
    - Enable SSH
    - Set a username and password
    - Connect to Wi-Fi (if needed)
5. Click "Write" to flash the SD card with the Raspberry Pi OS.
6. Once the flashing process is complete, eject the SD card and insert it into your Raspberry Pi.
7. Power on your Raspberry Pi and connect to it via SSH using the username and password you set during the setup process. You can find the IP address of your Raspberry Pi using your router's admin interface or by using a network scanning tool.

## get the ip address of your Raspberry Pi

### Windows
1. Open CMD or PowerShell and run the following command to get the IP address of your Raspberry Pi (e.g. if you set the hostname to "my-pi"):
```powershell
ping -4 my-pi
```

in the result:
```
Ping my-pi [192.168.1.100] with 32 bytes of data:
```
the IP address of your Raspberry Pi is `192.168.1.100` in this example.