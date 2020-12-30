var mysql = require('mysql2');
const dotenv = require('dotenv');
dotenv.config();

module.exports = function () {
	return {
		init: function () {
			return mysql.createPool({
				host: process.env.DB_HOST,
				port: process.env.DB_PORT,
				user: process.env.DB_USER,
				password: process.env.DB_PASSWORD,
				database: process.env.DB_NAME,
				dateStrings: 'date'
			});
		},
		open: function (conn, target) {
			conn.getConnection(function (err) {
				if (err) console.error(`(${target}) MariaDB Connection ${err}`);
			});
		}
	}
}