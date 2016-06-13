--- Application examples for the Node MCU (ESP8266) MCU.
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

--- Callback triggered by received data from 'cmd' and 'config'
--  topics. See below for setup function.
-- @param table data
--   Data received via MQTT on both topics.
-- @return nothing
--   Side effects only.
local function received_data(data)
  -- Print the name and value in received JSON message.
  print(format('Received: (name: %s, value: %s).',
               data.name,
               tostring(data.value)))
  -- Process the messages with 'Output' name.
  if data.name == 'Output' then
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

--- Gets a reading from the ADC and returns is as a table.
--
-- @return table
--   The table with the meaning(s) and value(s).
local function adc_data_source()
  -- Read the ADC input.
  local reading = adc.read(0)
  -- Return the values.
  return { meaning = 'ADC input', value = reading }
end

--- Gets the readings from a DHT11 or DHT22 sensor.
--
-- @param integer pin
--   The GPIO (input) pin number.
-- @return tabĺe
--   The table with the meaning(s) and value(s).
local function dht_data_source(pin)
  -- Read the data from the DHT sensor.
  local status, temp, hum = dht.read(pin)
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
  }
end

--- Wrapper for sending data to the relayr cloud.
--
-- @return nothing.
--   Side effects only.
local function send_data()
  relayr.send(dht_data_source(5))
end

--- Setup whatever you need in order to send
--  data and connect to the relayr cloud to
--
-- @return nothing.
--  Side effects only.
local function setup(subs_topics)
  -- Setup GPIO as an output.
  -- gpio.mode(output_pin, gpio.OUTPUT)
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
            send_data)
    end,
    subs_topics
  )
end

-- Setup WiFi and connect to it.
wifi_setup.start(config.wifi)

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
    -- Execute the 'setup' function.
    setup()
  end
end

-- Run the event loop for establishing a WiFi connection.
alarm(config.app.wifi_setup_timer,
      config.wifi.timer_period,
      tmr.ALARM_AUTO,
      wifi_wait_ip)
