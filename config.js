// Generated by CoffeeScript 1.9.3
(function() {
  var config, exports, ip;

  ip = require('ip');

  config = {};

  config.serverIp = ip.address();

  config.port = 8383;

  config.database = "mysql://hhc:ketiabcs@ketiabcs.iptime.org/kau_kjw_embeded";

  exports = module.exports = config;

}).call(this);

//# sourceMappingURL=config.js.map
