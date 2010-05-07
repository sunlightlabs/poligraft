# Various startup tasks go here. Restart when modifying this file.

MongoMapper.database = "truthify-#{Rails.env}"
require 'digest/md5'
require 'open-uri'
KEYS = YAML.load_file("#{Rails.root}/config/keys.yml")