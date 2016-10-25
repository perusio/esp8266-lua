-- Application examples for the Node MCU (ESP8266) MCU.
-- @script app.lua
-- @author Klemen Lilija <klemen@relayr.de>,
--         António P. P. Almeida <appa@perusio.net>

--  Load the wifi and relayr-mqtt modules.
local wifi_setup = require 'wifi_launch'
local relayr = require 'relayr_mqtt'
local config = require 'config'

-- Local definitions.
local format = string.format
local alarm = tmr.alarm

--[[
  **************************************************
  ************ User defined functions. *************
  **************************************************
]]--

-- Number of the GPIO pin used as a digital output.
-- D4 for the WeMos, D0 for the NodeMCU onboard LED.
local output_pin = 4 -- WeMos assumed
-- Digital I/O pin to use for sending data from the DHT11/22 sensor.
local dht_pin = 3

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
      gpio.write(output_pin, gpio.HIGH)
    else
      gpio.write(output_pin, gpio.LOW)
    end
  end
  -- Process the messages with name 'Frequency'.
  if data.name == 'frequency' then
    -- Update the alarm interval for sending data to relayr cloud.
    tmr.interval(config.app.data_timer, data.value)
  end
end

--- Gets the readings from sensors.
--
-- @return tabĺe
--   The table with the meaning(s) and value(s).
local function acquire_data()
  -- Read the data from the DHT sensor.
  local status, temp, hum = dht.read(dht_pin)
  -- Read the ADC data.
  local adc_reading = adc.read(0)
  -- Retunr the values.
  return{
    {
      meaning = 'temperature',
      value = temp
    },
    {
      meaning = 'humidity',
      value = hum
    },
    {
      meaning = 'adc',
      value = adc_reading
    },
  }
end

--- Wrapper for sending data from sensor readings
--- to the relayr cloud.
--
-- @return nothing.
--   Side effects only.
local function send_data()
  relayr.send(acquire_data())
end

--- Setup whatever you need in order to send
--  data and connect to the relayr cloud to send
--  and receive data.
--
-- @param subs_topics table topics to subscribe to.
-- @param send_callback function callback for sending data.
--
-- @return nothing.
--  Side effects only.
local function setup(subs_topics, send_callback)
  -- Setup GPIO as an output.
  gpio.mode(output_pin, gpio.OUTPUT)
  -- Register the function (callback) in which you
  -- whish to process incoming data (commands).
  relayr.register_data_listener(received_data)
  -- Connect to relayr Cloud.
  relayr.connect(
    -- Pass the MQTT configuration.
    config.mqtt,
    -- Callback when the connection is established.
    -- Invoke this function every app_config.data_period ms.
    function()
      alarm(config.app.data_timer,
            config.app.data_period,
            tmr.ALARM_AUTO,
            send_callback)
    end,
    subs_topics
  )
end

--- Callback that checks the WiFi link
-- is established and prints the IP address
-- when done.
--
-- @return nothing.
--  Side effects only.
function wifi_wait_ip()
  if not wifi.sta.getip() then
    print('IP address unassigned: waiting for it.')
  else
    -- IP assigned, unregister the timer and print the IP address.
    tmr.unregister(config.app.wifi_setup_timer)
    local ip, mask, gw = wifi.sta.getip()
    print(format('ip: %s mask: %s gw: %s.', ip, mask, gw))
    -- Setup the subscription topics for MQTT.
    local subs_topics = {}
    -- Execute the 'setup' function. Right now we use the DS18B20 as
    -- the data source. Change to whatever data source you use
    -- DHT11/22, etc.
    setup(subs_topics, send_data)
  end
end

-- Setup WiFi and connect to it.
wifi_setup.start(config.wifi)

-- Run the event loop for establishing a WiFi connection.
alarm(config.app.wifi_setup_timer,
      config.wifi.timer_period,
      tmr.ALARM_AUTO,
      wifi_wait_ip)
