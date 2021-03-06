-- @module wifi_launch.lua
-- @author Klemen Lilija <klemen@relayr.de>, António, P. P. Almeida <appa@perusio.net>.
-- @date   Jun 9 2016
--
-- @brief WiFi setup module for the ESP 8266 (Node MCU).
--

-- @table: module table.
local M = {
  _VERSION = '0.3',
  _NAME = 'WiFi launch',
  _DESCRIPTION = 'Setup a WiFi connection for the ESP8266',
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

  _CONFIG = {} -- configuration
}

-- Some local useful definitions.
local w = wifi
local format = string.format
local print = print
local pairs = pairs

-- Avoid polluting the global environment.
-- If we are in Lua 5.1 this function exists.
if _G.setfenv then
  setfenv(1, {})
else -- Lua 5.2.
  _ENV = nil
end

--- Callback that iterates through available access points,
-- and connects to user defined one.
--
-- @param t table SSID, authmode, RSSI, BSSID and channel.
-- @return nothing
--   Side effects only.
local function wifi_setup(t)
  -- Check if table with available networks is not empty.
  if t then
    -- Loop over all networks.
    for key, value in pairs(t) do
      -- Connect if the network defined on the configuration file.
      if M._CONFIG.ssid == key then
        w.setmode(w.STATION);
        w.sta.config(key, M._CONFIG.psk)
        w.sta.connect()
        -- Set the WiFi physical mode.
        local mode = w.getphymode()
        if M._CONFIG.phymode and M._CONFIG.phymode ~= mode then
          -- Mapping the configured physical modes to simpler keys.
          local modes = {
            -- Low power here means 56mA RX, 120mA TX.
            -- http://nodemcu.readthedocs.io/en/dev/en/modules/wifi/#wifisetphymode
            b = w.PHYMODE_B, -- long range, low rate, high power
            g = w.PHYMODE_G, -- medium range, medium rate, medium power
            n = w.PHYMODE_N, -- low range, high rate, low power
          }
          w.setphymode(modes[M._CONFIG.phymode])
        end
        -- Set the IP address: use a fixed one instead of relying on DHCP.
        if M._CONFIG.ip then
          w.sta.setip(
            {
              ip = M._CONFIG.ip, -- IP address
              netmask = M._CONFIG.mask, -- netmask
              gateway = M._CONFIG.gw, -- gateway
            }
          )
        end
        print(format('Connecting to %s...', key))
      end
    end
  else
    print('No scanning of available networks possible.')
  end
end

--- Sets up an WiFi connection for a given (SSID, PSK) pair.
-- @param config table WiFi configuration.
-- @return nothing
--   Side effects only.
function M.start(config)
  -- (Re)set the WiFi mode in the chip just to be on the safe side.
  w.setmode(w.NULLMODE)
  w.setmode(w.STATION)
  -- Copy the configuration to the module table.
  M._CONFIG = config
  -- Scan the to list the available networks for WiFi connection.
  w.sta.getap(wifi_setup)
end

-- WiFi configuration timer period in ms.
M._CONFIG._PERIOD = 2500
-- WiFi connection setup timer index.
M._CONFIG._TIMER = 1

-- Return the module table.
return M
