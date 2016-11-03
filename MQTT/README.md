# Connecting ESP8266 using Lua to the relayr cloud

## Introduction

This folder contains code for connecting to the relayr cloud
and publishing and/or subscribing to
[MQTT](https://en.wikipedia.org/wiki/MQTT) topics as defined by the
relayr dashboard.

You need an account in the
[relayr dashboard](https://developer.relayr.io) to make use of this
code. It could be repurposed for other MQTT brokers if you modify 
the appropriate parts of the code.

The code is organized in flowing structure:

 + `modules`: contains the modules that launch the WiFi connection,
    MQTT client support and configuration.
 + base directory contains the `app.lua` file where all the
   **specific** application logic is defined.
   
`app.lua` contains an example of sending *temperature*, *humidity* and *ADC* readings to the cloud, while being able to receive a command which triggers the onboard LED.

## Getting the base firmware 

This is the process to follow for using the DHT sensor as input to
publish to the relayr cloud:

 1. Go to [Node MCU Build](http://nodemcu-build.com/index.php) and
    select the **dev** branch and the following modules:
    
    + [CJSON](http://nodemcu.readthedocs.io/en/master/en/modules/cjson/)
    + [DHT](http://nodemcu.readthedocs.io/en/master/en/modules/dht/)
    + [MQTT](http://nodemcu.readthedocs.io/en/master/en/modules/mqtt/)
    + [CoAP](http://nodemcu.readthedocs.io/en/master/en/modules/coap/)

    the other needed modules should be **pre-selected**
    
    + [file](http://nodemcu.readthedocs.io/en/master/en/modules/file/)
    + [GPIO](http://nodemcu.readthedocs.io/en/master/en/modules/gpio/)
    + [net](http://nodemcu.readthedocs.io/en/master/en/modules/net/)
    + [node](http://nodemcu.readthedocs.io/en/master/en/modules/node/)
    + [timer](http://nodemcu.readthedocs.io/en/master/en/modules/tmr/)
    + [UART](http://nodemcu.readthedocs.io/en/master/en/modules/uart/)
    + [WiFi](http://nodemcu.readthedocs.io/en/master/en/modules/wifi/)
 
 2. You'll receive an email when the build starts and another one when
    the build finished. There are **two** versions one using
    **floating** point numbers the other with **integers**. You choose
    any of them for this case. For other application it might be
    important to use one or the other.
    
 3. Download the `bin` file(s) from the link(s) in the mail sent by
    the build bot once the build has finished.
    
The alternative is to just use the firmware in the `firmware` folder of this git repository.
    
## Flashing the firmware onto the device

### Communicating with the device via serial port - USB

There are a profusion of devices out there. What interest us is the
chip used for the USB to UART interface. For the WeMos D1 mini boards and others based on the CH340 find a [driver here](http://www.wemos.cc/downloads/), and if you are using the latest version of macOS (Sierra) then download [this driver](http://blog.sengotta.net/wp-content/uploads/2015/11/CH34x_Install_V1.3.zip).
 
### Flashing the firmware
 
 +  If using Linux or OSX install the
    [esptool](https://github.com/themadinventor/esptool).
 + If using Windows get the
   [NodeMCU flasher for Win 32](https://github.com/nodemcu/nodemcu-flasher/raw/master/Win32/Release/ESP8266Flasher.exe)
   or the
   [NodeMCU flahser for Win 64](https://github.com/nodemcu/nodemcu-flasher/raw/master/Win64/Release/ESP8266Flasher.exe).
   
#### Flashing on Linux and OSX 

Plug your board into your computer USB port and go to the `esptool`
directory. Issue the command:


```shell
 esptool.py --port /dev/ttyUSB0 write_flash -fm dio -fs 32m -ff 40m 0x00000 /path/to/firmware.bin
```

where: 

 + `/dev/ttyUSB0` is the **Linux** serial device associated with the WeMos board. It might vary depending on your specific setup.
   
 + Do `ls /dev/cu*` to see the name of the device in your OSX machine (Mac).

 + `firmware.bin` is one of the bin files you downloaded from the
   firmware build site above. 
   
For example, in Linux:

```shell
 esptool.py --port /dev/ttyUSB0 write_flash -fm dio -fs 32m -ff 40m 0x00000 nodemcu-master-10-modules-2016-03-17-10-58-23-float.bin
```

You should see the blue led on the board blinking as the counter
progresses up to 100% when the flashing completes.

#### Flashing on Windows

Follow the instructions on the
[README](https://github.com/nodemcu/nodemcu-flasher/) for the github
project.

## Communicating with the device and uploading code

There are two options for this. One uses the command line, the other
uses an IDE.

### IDE for the ESP8266

[ESPlorer](http://esp8266.ru/esplorer/) is a Java based IDE for
working with the ESP8266. It requires the Oracle 
[Java Runtime Environment](http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html)
or
[Java Development Kit](http//www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html).

### Command line tool: luatool

[luatool](https://github.com/4refr0nt/luatool) is a Python script that
communicates with the ESP8266 using the serial port and sends the
file(s) line by line to the device.

### Format the device

The ESP8266 official SDK uses Lua and relies on a Flash based
filesystem to run code in files.

If on the ESPlorer press the `format` button. 

If on the command line:

 1. Open a serial communications program like
    [picocom](https://github.com/npat-efault/picocom) in LInux and OSX
    or [Putty](http://www.putty.org/) in Windows.
    
    
        picocom -b 115200 /dev/ttyUSB0
        
    adapt the the name of the serial device the ESP8266 shows up as.
    
 2. Issue the command: 

        file.format()
    
It takes a while to format the file system. Once we're done we can now
upload files to the device.

### Uploading files to the device

With the ESPlorer is very simple. Just use the buttons on the UI.

On the command line:

 1. Go to the `luatool` directory.
 2. Issue the command:
 
        ./luatool/luatool.py -p /dev/ttyUSB0 -b 115200 -f /path/to/code_file.lua
        
    where `/path/to/code_file.lua` is the path to the Lua file you
    want to upload.
    
 3. Done.
 
## Running the code for the relayr cloud

 1. Clone the repository:
 
        git clone git@github.com:relayr/ESP8266_Lua.git
        
 2. Edit the `config.lua` file and add your WiFi credentials and the
    credentials you get from the relayr
    [dashboard](https://developer.relayr.io). Upload it.
    
        /luatool/luatool.py -p /dev/ttyUSB0 -b 115200 -f /path/to/ESP8266_Lua/modules/config.lua
        
 3. Upload the other files one by one. If using the ESPlorer select and
    upload. If on the command line with `luatool`

    
        /luatool/luatool.py -p /dev/ttyUSB0 -b 115200 -f /path/to/ESP8266_Lua/modules/wifi_launch.lua 
        /luatool/luatool.py -p /dev/ttyUSB0 -b 115200 -f /path/to/ESP8266_Lua/modules/relayr_mqtt.lua
        /luatool/luatool.py -p /dev/ttyUSB0 -b 115200 -f /path/to/ESP8266_Lua/app.lua
                        
 4. Now we can run the code. 
 
    + On the ESPlorer just do `dofile('app.lua')`.
    + On the command line open a terminal program like picocom or
      Putty and do: `dofile('app.lua')`.
      
 5. You should start seeing the data being visualized on the
    dashboard.    


## Writing your own application

The `app.lua` file contains two types of callbacks:

 + `send_data`: that **publishes** data to a particular topic in the
   MQTT broker.
 + `received_data`: that **subscribes** to a particular topic in the
   MQTT broker.
   
To understand those functions you need first to understand the
[device model](http://docs.relayr.io/getting-started/device-models-guide/).

Briefly a device model is a schema describing what type of data
streams a device can consume and/or receive. The data streams are
usually serialized as JSON. Note that we use here _loosely_ the term
stream. Is not a stream in the sense of a **continuous** flow of
values, but rather as a source/sink of data to/from the MQTT broker.

It is beyond the scope of this document to delve deeply into device
models and how the relayr MQTT broker topics are organized. Instead we
provide examples of sensors (data in the relayr parlance) and
actuators (commands in the relayr parlance) in the `app.lua` file.
    
## Debugging and troubleshooting

The `wifi_launch` and `relayr_mqtt` can print debugging messages in
the terminal for that in the `app.lua` file do:

```lua
relayr._DEBUG = true -- for the relayr_mqtt debugging messages
wifi_setup._DEBUG = true -- for the wifi_launch debugging messages
```

## Sending commands and affecting the configuration

MQTT allows for sending **commands**, i.e., making the device function
as a subscription client of the broker. In the example given in
`app.lua` we use the **onboard** blue LED available on the GPIO pin
**4** (D4) of the WeMos and on GPIO pin **0** (D0) on the NodeMCU. For
By default the configuration assumes we use a WeMos. In `config.lua`
make sure that the `M.app.output_pin` table entry (configuration) is
set to 4 for the WeMos and 0 for the NodeMCU.
 
Here's the code snippet from `app.lua`:


```lua
 
--- Callback triggered by received data from 'cmd' and 'config'
--  topics. By default just turns on and off the onboard LED in pin D4.
--
-- @param data table data received via MQTT on both topics.
-- @return nothing
--   Side effects only.
local function received_data(data)
  -- Print the name and value in received JSON message.
  print(format('Received: (name: %s, value: %s).',
               data.name,
               tostring(data.value)))
  -- Process the messages with 'Output' name.
  if data.name == 'output' then
    if data.value then
      gpio.write(config.app.output_pin, gpio.HIGH)
    else
      gpio.write(config.app.output_pin, gpio.LOW)
    end
  end
  -- Process the messages with name 'Frequency'.
  if data.name == 'Frequency' then
    -- Update the alarm interval for sending data to relayr cloud.
    tmr.interval(config.app.data_timer, data.value)
  end
end
```

**Customize** it to your liking. The `Frequency` is not the frequency
but rather the **period** between the each LED blink.

## Going further

relayr provides hands-on workshops every second Thursday of every
month. [Come](https://www.eventbrite.com/e/understanding-iot-protocols-using-the-esp-8266-mqtt-coap-http-and-websockets-tickets-21205029815)
join us to see all this code in action.

## TODO

 + Add test for the MQTT connection/publishing/subscribing.

## License

 Copyright (C) 2016 relayr GmbH, Klemen Lilija <klemen@relayr.de>, 
 António P. P. Almeida <appa@perusio.net> 

 Permission is hereby granted, free of charge, to any person obtaining a 
 copy of this software and associated documentation files (the "Software"), 
 to deal in the Software without restriction, including without limitation 
 the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 and/or sell copies of the Software, and to permit persons to whom the 
 Software is furnished to do so, subject to the following conditions: 

 The above copyright notice and this permission notice shall be included in 
 all copies or substantial portions of the Software. 

 Except as contained in this notice, the name(s) of the above copyright 
 holders shall not be used in advertising or otherwise to promote the sale, 
 use or other dealings in this Software without prior written authorization. 

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL 
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
 DEALINGS IN THE SOFTWARE. 
 
 
