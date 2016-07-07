-- @module config.lua
-- @author António, P. P. Almeida <appa@perusio.net>.
--
-- @date   Jun 10 2016
--
-- @brief Configuration for running WiFi and the MQTT uplink
--        to the realyr cloud.

-- @table: module table.
local M = {
  _VERSION = '0.3',
  _NAME = 'config',
  _DESCRIPTION = 'ESP8266 configuration for the relayr cloud',
  _COPYRIGHT = [[
                  Copyright (c) 2016 Klemen Lilija <klemen@relayr.de>,
                  António P. P. Almeida <appa@perusio.net>,
                  relayr GmbH

                  Permission is hereby granted, free of charge, to any person
                  obtaining a copy of this software and associated documentation
                  files (the "Software"), to deal in the Software without
                  restriction, including without limitation the rights to use,
                  copy, modify, merge, publish, distribute, sublicense, and/or sell
                  copies of the Software, and to permit persons to whom the
                  Software is furnished to do so, subject to the following
                  conditions:

                  The above copyright notice and this permission notice shall be
                  included in all copies or substantial portions of the Software.
                  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
                  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
                  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
                  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
                  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
                  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
                  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
                  OTHER DEALINGS IN THE SOFTWARE. ]],
}

-- Avoid polluting the global environment.
-- If we are in Lua 5.1 this function exists.
if _G.setfenv then
  setfenv(1, {})
else -- Lua 5.2.
  _ENV = nil
end

--[[
  **************************************************
  * Configuration of the application starts here.  *
  **************************************************
]]--
--  @table: WiFi network SSID and password/psk.
M.wifi = {
  -- Replace with the desired network SSID.
  ssid = '<my SSID>',
  -- Replace with the desired network SSID.
  psk = '<psk here>',
  -- WiFi configuration timer period in ms.
  timer_period = 2500,
}

---  @table: MQTT credentials you get from the developer dashboard.
M.mqtt = {
  -- User ID for MQTT basic auth. This is the device ID for the
  -- relayr cloud.
  user = '<device ID>',
  -- User password for MQTT Basic Auth.
  password = '<password here>',
  -- This is just a convenience that allows you to identify the
  -- client on the MQTT bro ker. It can be anything you choose.
  client_id = '<client_id>',
}

--- @table: the application configuration.
M.app = {
  -- Number of the GPIO pin used as a digital output.
  -- D4 for the WeMos, D0 for the NodeMCU.
  output_pin = 4, -- WeMos assumed
  -- Timer (index) used for sending the data.
  data_timer = 2,
  -- Period of data publishing (every X ms).
  data_period = 2500,
  -- WiFi connection setup timer index.
  wifi_setup_timer = 1,
  -- CoAP server node timer index.
  coap_server_timer = 3,
}


--[[
  **************************************************
  ** Configuration of the application ends here.  **
  **************************************************
]]--

-- Return the module table.
return M
