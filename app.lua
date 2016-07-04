--- Application examples for the Node MCU (ESP8266) MCU.
-- @script app.lua
-- @author Klemen Lilija <klemen@relayr.de>,
--         António P. P. Almeida <appa@perusio.net>

--  Load the wifi and relayr-mqtt modules.
local wifi_setup = require 'wifi_launch'
local relayr = require 'relayr_mqtt'
local config = require 'config'
-- Load the DS18B20 module.
local ds = require 'ds18b20'


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
-- @param data table data received via MQTT on both topics.
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

-- Digital I/O pin to use for sending data from the DHT11/22 sensor.
local dht_pin = 5

--- Wrapper for sending data from the DHT11/22 sensors
--- to the relayr cloud.
--
-- @return nothing.
--   Side effects only.
local function send_dht_data()
  relayr.send(dht_data_source(dht_pin))
end

--- Gets the readings from a DS18B20 sensor.
--
-- @param pin integer GPIO (input) pin number.
-- @return tabĺe
--   The table with meaning and value.
local function ds18b20_data_source(pin)
  -- Setup the sensor.
  ds.setup(ds18b20_pin)
  -- Get the temperature in Celsius.
  return {
    meaning = 'temperature',
    value = ds.read()
  }
end

-- Digital I/O pin to use for sending data from the DS18B20 sensor.
local ds18b20_pin = 5

--- Wrapper for sending data from the DS18B20 sensor
--- to the relayr cloud.
--
-- @return nothing.
--   Side effects only.
local function send_ds18b20_data()
  relayr.send(ds18b20_data_source(ds18b20_pin))
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
            send_callback)
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
    -- Setup the subscription topics for MQTT.
    local subs_topics = {}
    -- Execute the 'setup' function. Right now we use the DS18B20 as
    -- the data source. Change to whatever data source you use
    -- DHT11/22, etc.
    setup(subs_topics, send_ds18b20_data)
  end
end

-- Run the event loop for establishing a WiFi connection.
alarm(config.app.wifi_setup_timer,
      config.wifi.timer_period,
      tmr.ALARM_AUTO,
      wifi_wait_ip)
