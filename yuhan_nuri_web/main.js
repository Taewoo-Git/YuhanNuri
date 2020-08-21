const port = 3000;

const express = require('express');
const app = express();

const cheerio = require('cheerio-httpcli');
const session = require('express-session');
const moment = require('moment');

const userRouter = require('./routes/user');

app.listen(port, () => {
    console.log('Listening on port ' + port + '\n');
});

app.set('views', __dirname + '/views');
app.set('view engine', 'ejs');
app.engine('html', require('ejs').renderFile);

app.use(express.static(__dirname + '/public'));

app.use(express.json());
app.use(express.urlencoded({ extended: false }));

app.use(session({ secret: '@#@$ynuri#@$!', resave: false, saveUninitialized: false }));

let database = require(__dirname + '/public/res/js/mariadb_config.js')();
let connection = database.init();

database.open(connection);

app.get('/', function (req, res) {
    res.redirect('login.html');
});

app.get('/logout', function (req, res) { //GET /user/logout
    req.session.destroy();
    res.redirect('/');
});

app.get('/main', function (req, res) { //Mr.애매모호
    console.log('Session', req.session);
    res.render('main', {
        username: req.session.userInfo.stuName,
    });
});

app.get('/reservation', function (req, res) { //GET /user/reservation
    res.render('reservation');
});

app.post('/reservation', function (req, res) { //POST /user/reservation
    
});

app.post('/', function (req, res) { //POST /user
    const userId = req.body.userId; // 사용자 아이디
    const password = req.body.password; // 사용자 패스워드
	
    let tempInfo = []; // 임시 배열
	let userInfo = null; // 사용자 정보

    let url = 'http://portal.yuhan.ac.kr/user/loginProcess.face?userId=' + userId + '&password=' + password; // 로그인 세션 URL
	
	cheerio.set('browser', 'chrome'); // 브라우저 설정
	cheerio.fetch(url)
	.then(function(result) {
		if(result.response.cookies.EnviewSessionId)
			return cheerio.fetch('http://m.yuhan.ac.kr/bachelor/bcUserInfoR.jsp'); // 사용자 정보 URL
	})
	.then(function(result) {
		result.$('td').each(function(index, element) {
			tempInfo.push(result.$(this).text().trim()); // 사용자 정보 임시 저장
		});
		
		userInfo = {
			stuCode: tempInfo[0],
			stuName: tempInfo[1],
			stuBirth: tempInfo[2].split('-')[0],
			stuMajor: tempInfo[3],
			stuAddr: tempInfo[7],
			stuEmail: tempInfo[6],
			stuPhoneNum: tempInfo[5],
		};
		
		req.session.userInfo = userInfo; // 사용자 정보를 세션으로 저장
		res.render('main', {
			username: userInfo.stuName,
		});
	})
	.catch(function(err) {
		//console.error(err);
		res.redirect('/');
	})
	.finally(function() {
		if(userInfo != null) {
			let userSelect = 'SELECT * FROM User WHERE stuno = ?';
			let userInsert = 'INSERT INTO User VALUES(?, ?, ?, ?, ?, ?, ?)';

			connection.execute(userSelect, [userInfo.stuCode], (err, result) => {
				if(err) console.error(err);
				else {
					if(result.length === 0) {
                        // Object.values(userInfo)로 객체의 값을 배열로 바로 가져옴.
						connection.execute(userInsert, Object.values(userInfo), (err, result) => {
								if(err) console.error(err);
						});
					}
				}
			});
		}
		
		cheerio.reset(); // cheerio 초기화 → 로그인 세션 중복 해결
		console.info(req.session);
	});
});