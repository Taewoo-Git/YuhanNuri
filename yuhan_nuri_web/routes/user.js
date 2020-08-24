const express = require('express');
const router = express.Router();

const cheerio = require('cheerio-httpcli');
const moment = require('moment');

const db = require('../public/res/js/database.js')();
const connection = db.init();

db.open(connection);

router.post('/', function (req, res) { //POST /user
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
			username: userInfo.stuName
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

router.get('/logout', function (req, res) { //GET /user/logout
    req.session.destroy();
    res.redirect('/');
});

router.get('/reservation', function (req, res) { //GET /user/reservation
    res.render('reservation');
});

router.post('/reservation', function (req, res) { //POST /user/reservation
    let reservation_date = req.body.reservation_data;
    let reservation_time = req.body.reservation_time;

	let inputReservationInfo_sql = "INSERT INTO Reservation VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)";
	let nowMoment = moment().format("YYYYMMDD");
	
	let getMaxPkSql = "SELECT MAX(no) as RESULT FROM Reservation WHERE no LIKE ?";
		
	connection.execute(getMaxPkSql, [nowMoment + '%'], (err, rows) => {
		let rowcount = 0;
		let newSerialNum = "";
		
		if(err) console.error(err);
		else rows[0].RESULT !== null ? rowcount = 1 : rowcount = 0;
		
		if(!rowcount) newSerialNum = nowMoment.concat("0001");
		else {
			console.info(rows[0].RESULT.substring(8));
			console.info(Number(rows[0].RESULT.substring(8)));
			
			let num = (Number(rows[0].RESULT.substring(8)) + 1).toString();
			
			for(let index = num.length; index < 4; index++) {
				num = '0' + num;
			}
			
			newSerialNum = nowMoment.concat(num);
		}
	
		connection.execute(inputReservationInfo_sql, [
			newSerialNum, 
			"11111",
			req.session.userInfo.stuCode,
			"emp100001", 
			reservation_date,
			reservation_time,
			reservation_time,
			0,
			0
		],
		(err, rows) => {
			if(err) console.error(err);
		});
	});
	
	res.redirect('/main');
});

module.exports = router;
