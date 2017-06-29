$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'tao'
require 'minitest/autorun'

ActiveRecord::Base.establish_connection({
  adapter: "mysql2",
  username: "root",
  database: "tao_test",
})
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS `tao_objects`")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS `tao_associations`")
ActiveRecord::Base.connection.execute(<<-SQL)
  CREATE TABLE `tao_objects` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT,
    `type` varchar(255) NOT NULL,
    `value` blob NOT NULL,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8
SQL
ActiveRecord::Base.connection.execute(<<-SQL)
  CREATE TABLE `tao_associations` (
    `id1` bigint(20) NOT NULL,
    `type` varchar(255) NOT NULL,
    `id2` bigint(20) NOT NULL,
    `created_at` DATETIME NOT NULL,
    `value` blob NOT NULL,
    PRIMARY KEY (`id1`, `type`, `id2`),
    KEY `index_tao_associations_on_time` (`id1`, `type`, `created_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8
SQL
