--- Tests the WiFi connection of the ESP8266.
-- @script application.lua
-- @author António P. P. Almeida <appa@perusio.net>
--

--  Load the wifi setup module.
local wifi_launch = require 'wifi_launch'
-- Load the WiFi configuration.
local wifi_config = require('config').wifi
-- Load the application configuration.
local app_config = require('config').app

-- Some local definitions.
local format = string.format
local alarm = tmr.alarm

-- Setup WiFi and connect to it.
wifi_launch.start(wifi_config)

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
    tmr.unregister(app_config.wifi_setup_timer)
    local ip, mask, gw = wifi.sta.getip()
    print(format('ip: %s mask: %s gw: %s.', ip, mask, gw))
  end
end

-- Run the event loop for establishing a WiFi connection.
alarm(app_config and app_config.wifi_setup_timer or wifi_setup._CONFIG._TIMER,
      wifi_config.timer_period or wifi_setup._CONFIG._PERIOD,
      tmr.ALARM_AUTO,
      wifi_wait_ip)
