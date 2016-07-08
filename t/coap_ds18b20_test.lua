-- Load the application configuration.
local app_config = require('config').app
-- Load the CoAP DS18B20 module.
local coap_ds18b20 = require 'coap_ds18b20'
-- Enable the debugging.
coap_ds18b20._DEBUG = true
-- Run the code for the simple service CoAP service.
-- Counter index and updating period.
coap_ds18b20(app.config.coap_server_timer or 3, coap_period or 1000)
