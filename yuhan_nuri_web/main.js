const port = 3000;

const express = require('express');
const app = express();

//const server = require('http').createServer(app);

const server = app.listen(port, () => {
    console.log('Listening on port ' + port + '\n');
});

app.use(express.static(__dirname + '/public'));

var database = require(__dirname + '/public/res/js/mariadb_config.js')();
var connection = database.init();

database.open(connection);

app.get('/test', function(req, res) {
	var sql = 'SELECT * FROM test';
	connection.query(sql, function (error, rows, fields) {
		if (!error) {
			res.send(rows);
			console.log(rows);
		}
		else {
			console.log('query error : ' + error);
		}
	});
});
