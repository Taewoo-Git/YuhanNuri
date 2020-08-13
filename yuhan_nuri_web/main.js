const port = 3000;

const express = require('express');
const app = express();

const cheerio = require('cheerio-httpcli');

const server = app.listen(port, () => {
    console.log('Listening on port ' + port + '\n');
});

app.use(express.static(__dirname + '/public'));

const bodyParser = require('body-parser');
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended : false}));

var database = require(__dirname + '/public/res/js/mariadb_config.js')();
var connection = database.init();

database.open(connection);

app.get('/', function(req, res) {
	res.sendFile(__dirname + '/public/login.html');
});

app.post('/', function(req, res) {
	var userId = req.body.userId;
	var password = req.body.password;	
	
	var url = "http://portal.yuhan.ac.kr/user/loginProcess.face?userId="+userId+"&password="+password;
	var param = {};

	cheerio.fetch(url, param, function(error, $, response) {
		if(error) {
			console.log(err);
			return;
		}
		else {
			if(response.cookies.EnviewSessionId) {
				var tempInfo = [];
				
				cheerio.set('browser', 'chrome');
				cheerio.fetch("http://m.yuhan.ac.kr/bachelor/bcUserInfoR.jsp", param, function(error, $, response) {
					if(error) {
						console.log(error);
						return;
					}
					else {
						$("td").each(function(index, element) {
							tempInfo.push($(this).text().trim());
						});
					}
					
					var userInfo = {
						stuCode: tempInfo[0],
						stuName: tempInfo[1],
						stuRegNum: tempInfo[2],
						stuMajor: tempInfo[3],
						stuHomeNum: tempInfo[4],
						stuPhoneNum: tempInfo[5],
						stuEmail: tempInfo[6],
						stuAddr: tempInfo[7]
					}
					
					console.log(userInfo);
					res.send(userInfo);
				});
			}
			else {
				res.redirect('/');
			}
		}
	});
});
