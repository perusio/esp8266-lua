--- Application examples for the Node MCU (ESP8266) MCU.
-- @script app.lua
-- @author Klemen Lilija <klemen@relayr.de>,
--         António P. P. Almeida <appa@perusio.net>

--  Load the wifi and relayr-mqtt modules.
local wifi_setup = require 'wifi_launch'
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
local output_state = true
-- Digital I/O pin to use for sending data from the DHT11/22 sensor.
local dht_pin = 3

--- Gets the readings from sensors.
--
-- @return tabĺe
--   The table with the meaning(s) and value(s).
local function acquire_data()
  -- Read the data from the DHT sensor.
  status, temp, hum = dht.read(dht_pin)
  -- Read the ADC data.
  adc_reading = adc.read(0)
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

--- Gets the readings from sensors.
--
-- @return string
--   A CoAP string response.
function foo(payload)

  -- Switch the LED.
  if output_state then
    gpio.write(output_pin, gpio.HIGH)
    output_state = false
  else
    gpio.write(output_pin, gpio.LOW)
    output_state = true
  end

  local respond = "Foo switched a LED."
  return respond
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
local function setup()

  -- Setup the GPIO as an output.
  gpio.mode(output_pin, gpio.OUTPUT)

  -- Create a server instance on 5683 port.
  cs = coap.Server()
  cs:listen(5683)

  -- Variables.
  cs:var("adc_reading") -- get coap://192.168.18.103:5683/v1/v/myvar will return the value of 'adc_reading'
  cs:var("temp")
  cs:var("hum")
  -- Get all at once.
  someContent ='[1,2,3]'
  cs:var("someContent", coap.JSON) -- sets content type to json

  -- function should tack one string, return one string.
  cs:func("foo") -- Post coap://192.168.18.103:5683/v1/f/foo will call foo fucion.

  alarm(config.app.coap_server_timer,
    config.app.data_period,
    tmr.ALARM_AUTO,
    acquire_data)

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
    -- Setup the CoAP server.
    setup()
  end
end

-- Setup WiFi and connect to it.
wifi_setup.start(config.wifi)

-- Run the event loop for establishing a WiFi connection.
alarm(config.app.wifi_setup_timer,
      config.wifi.timer_period,
      tmr.ALARM_AUTO,
      wifi_wait_ip)
