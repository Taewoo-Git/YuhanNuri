const express = require('express');
const router = express.Router();

const cheerio = require('cheerio-httpcli');

const db = require('../public/res/js/database.js')();
const connection = db.init();
db.open(connection);

const moment = require('moment');
require('moment-timezone'); 
moment.tz.setDefault("Asia/Seoul");

router.post('/', function (req, res) { //POST /user
    const userId = req.body.userId; // 사용자 아이디
    const password = req.body.password; // 사용자 패스워드
	const autoLogin = req.body.autoLogin; // 자동 로그인 여부
	
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
			stuPhoneNum: tempInfo[5]
		};
		
		if(autoLogin) {
			let expiryDate = new Date(Date.now() + 10 * 60 * 1000); // 만료기간 10분, 60 * 60 * 1000 * 24 * 30 == 30일
			
			res.cookie('AutoLogin', userInfo.stuCode, { // 자동 로그인 체크시 암호화된 학번으로 쿠키 생성
				expires: expiryDate,
				httpOnly: true,
				signed: true
			});
		}
		
		req.session.userInfo = userInfo; // 사용자 정보를 세션으로 저장
		res.redirect('/');
	})
	.catch(function(err) {
		console.error(err);
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

router.get('/logout', function(req, res) { //GET /user/logout
    req.session.destroy();
	res.clearCookie('AutoLoginUser');
    res.redirect('/');
});

router.get('/auto', function(req, res) { //GET /user/auto
	// 자동 로그인 쿠키가 살아있을 경우 해당 경로로 넘어와 세션 생성 후 main으로 이동
	let userInfoSelect = 'SELECT * FROM User WHERE stuno = ?';
	connection.execute(userInfoSelect, [req.signedCookies.AutoLogin], (err, result) => {
		if(err) console.error(err);
		else {
			let userInfo = {
				stuCode: result[0].stuno,
				stuName: result[0].stuname,
				stuBirth: result[0].birth,
				stuMajor: result[0].major,
				stuAddr: result[0].addr,
				stuEmail: result[0].email,
				stuPhoneNum: result[0].phonenum
			};

			req.session.userInfo = userInfo;
			res.redirect('/');
		}
	});
});

router.get('/reservation', function (req, res) { //GET /user/reservation
    res.render('reservation');
});

router.post('/reservation', function (req, res) { //POST /user/reservation
    let reservation_date = req.body.reserv_date;
    let reservation_time = req.body.reserv_time;

	let inputReservationInfo_sql = "INSERT INTO Reservation VALUES(?, ?, ?, ?, ?, ?, ?, ?)";
	let nowMoment = moment().format("YYYYMMDD");
	
	
	let getMaxPkSql = "SELECT MAX(no) as RESULT FROM Reservation WHERE no LIKE ?";
		
	connection.execute(getMaxPkSql, [nowMoment + '%'], (err, rows) => {
		let rowcount = 0;
		let newSerialNum = "";
		
		if(err) console.error(err);
		else rows[0].RESULT !== null ? rowcount = 1 : rowcount = 0;
		console.info(rowcount);
		
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
	
		console.info(newSerialNum);
		connection.execute(inputReservationInfo_sql, [
			newSerialNum, 
			"11111",
			req.session.userInfo.stuCode,
			"emp100001", 
			reservation_date,
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

router.post("/postTest", function(req, res){ //POST /user/postTest
	// 예약 승인이 되었을때의 기준 (status = 1)
	let getReservationByDateSql = "SELECT starttime, COUNT(starttime) AS CNT FROM Reservation WHERE date = ? AND status = 1 GROUP BY starttime";
	console.info(req.body.sendAjax);
	
	connection.execute(getReservationByDateSql, [req.body.sendAjax], (error, rows, fields) => {
  		if (error) throw error;
		
		console.info(rows);
		res.json({ok: true, rtntime: rows});
	});
});

router.get("/admin",function(req,res){ //GET /user/admin
	const getReservationData = "SELECT * FROM Reservation WHERE status = 0";
	
	connection.execute(getReservationData, (err,rows) => {
		if(err) console.error(err);
		
		console.info('admionrows', rows);
		res.render('admin', {getReservation: rows});
	});
});

router.post("/accessReservation", function(req,res) {
	const getAccessReservationData = "UPDATE Reservation SET status=1 WHERE no = ?";
	let data = req.body.sendAjax;
	
	connection.execute(getAccessReservationData, [data], (err,rows) => {
		if(err) console.error(err);
		
		res.json({getReservation: rows});
	});
})

module.exports = router;
