const express = require('express');
const router = express.Router();

const cheerio = require('cheerio-httpcli');

const db = require('../public/res/js/database.js')();
const connection = db.init();
db.open(connection,'user');

const moment = require('moment');
require('moment-timezone'); 
moment.tz.setDefault("Asia/Seoul");

router.post('/', function (req, res) { //POST /user
    const userId = req.body.userId; // 사용자 아이디
    const password = req.body.password; // 사용자 패스워드
	const isAutoLogin = req.body.isAutoLogin; // 자동 로그인 여부
	
	let adminCheckSql = "SELECT empno, empname FROM Counselor WHERE empno = ?" // 관리자 계정인지 체크하는 함수
	
	connection.execute(adminCheckSql, [userId], (err, rows) => {
		
		if(err) {
			console.error(err)
		}
		else if(rows[0] !== undefined) {
			// 관리자 계정일 경우 - 윤권 (근로학생도 포함)
			let adminInfo = {
				empno : rows[0].empno,
				empname : rows[0].empname
			}
			req.session.adminInfo = adminInfo; // 사용자 정보를 세션으로 저장
		
			console.info(req.session.adminInfo.empname);
			
			res.redirect('/admin');
		}
		else {
			// 학생 계정일 경우 아래와 같이 정상 로그인 로직 수행 - 윤권
			getUserInfo(userId, password)
			.then(function(userInfo) {
				req.session.userInfo = userInfo; // 사용자 정보를 세션으로 저장
				if(isAutoLogin) {
					let expiryDate = new Date(Date.now() + 10 * 60 * 1000); // 만료기간 10분, 60 * 60 * 1000 * 24 * 30 == 30일
					res.cookie('isAutoLogin', userInfo.stuCode, { // 자동 로그인 체크시 암호화된 학번으로 쿠키 생성
						expires: expiryDate,
						httpOnly: true,
						signed: true
					});
				}
				console.info(req.session);
				res.redirect('/');
			}, function(error) {
				console.error(error);
				res.redirect('/');
			});
		}
	});
});

router.get('/logout', function(req, res) { //GET /user/logout
    req.session.destroy();
	res.clearCookie('isAutoLogin');
    res.redirect('/');
});

router.get('/auto', function(req, res) { //GET /user/auto
	// 자동 로그인 쿠키가 살아있을 경우 해당 경로로 넘어와 세션 생성 후 main으로 이동
	let userInfoSelect = 'SELECT * FROM User WHERE stuno = ?';
	
	connection.execute(userInfoSelect, [req.signedCookies.isAutoLogin], (err, result) => {
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

router.post('/mobile', function(req, res) { //POST /user/mobile
	console.log(req.body);
	
    const userId = req.body.userId; // 사용자 아이디
    const password = req.body.password; // 사용자 패스워드
	const isAutoLogin = req.body.isAutoLogin; // 자동 로그인 여부
	
	getUserInfo(userId, password)
	.then(function(userInfo) {
		req.session.userInfo = userInfo; // 사용자 정보를 세션으로 저장
		if(isAutoLogin == 'true') {
			let expiryDate = new Date(Date.now() + 10 * 60 * 1000); // 만료기간 10분, 60 * 60 * 1000 * 24 * 30 == 30일
			res.cookie('isAutoLogin', userInfo.stuCode, { // 자동 로그인 체크시 암호화된 학번으로 쿠키 생성
				expires: expiryDate,
				// httpOnly: true,
				signed: true
			});
		}
		res.json(userInfo);
	}, function(error) {
		res.json(null)
		console.error(error);
	});
});

router.get('/reservation', function (req, res) { //GET /user/reservation
	
	// 상담사를 먼저 선택하고 ajax 로 받아서 그다음에 일정을 처리해야 할것으로 보임
	const sql_counselorList = "SELECT empno, empname FROM Counselor WHERE position = 'counselor'";

	connection.execute(sql_counselorList, (err, rows) => {
		if(err){
			console.error(err);
			return;
		}else{
			let counselorNameList = rows.map(v => [v.empno, v.empname]);
		
			console.info(counselorNameList);
			res.render('reservation', {counselorNameList : counselorNameList});
		}
		
	});
	

});

router.post('/reservation', function (req, res) { //POST /user/reservation
	let reservation_counselorId = req.body.reserv_counselorId;
    let reservation_date = req.body.reserv_date;
    let reservation_time = req.body.reserv_time;
	let reservation_type = req.body.reserv_type;
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
			reservation_type,
			req.session.userInfo.stuCode,
			reservation_counselorId, 
			reservation_date,
			reservation_time,
			0,
			0
		],
		(err, rows) => {
			if(err) console.error(err);
		});
	});
	
	res.redirect('/user/privacy');
});

router.get('/privacy', function (req, res) { //GET /user/privacy
    res.render('privacy');
});

router.post('/privacy', function (req, res) { //POST /user/privacy
	console.info(req.body);
	res.redirect('/');
});

router.get('/selfcheck', function (req, res) { //GET /user/privacy
    let questionSelect = 'SELECT *, (SELECT GROUP_CONCAT(content) FROM FormAnswer WHERE cardno=c.cardno) AS answer '
						+ 'FROM FormTypeContent c WHERE typeno=?';
	
	connection.execute(questionSelect, [0], (err, result) => {
		if(err) console.error(err);
		else {
			res.render('selfcheck', {
				result: result
			});
		}
	});
});

/*router.post('/selfcheck', function (req, res) { //POST /user/privacy
	
});*/

router.post("/getPossibleTime", function(req, res){ //POST /user/postTest
	// 예약 승인이 되었을때의 기준 (status = 1)
	//let getReservationByDateSql = "SELECT starttime, COUNT(starttime) AS CNT FROM Reservation WHERE date = ? AND status = 1 GROUP BY starttime";
	let getCanCounselSchedule = "SELECT starttime FROM CanCounselSchedule WHERE date = ? AND empno = ?";
	
	
	let empno = req.body.ajax_counselorId;
	let date = req.body.ajax_date;
	
	
	connection.execute(getCanCounselSchedule, [date, empno], (error, rows, fields) => {
  		if (error) console.error(error);
		
		else  
			res.json({ok: true, rtntime: rows});
	});
});

let getUserInfo = function(userId, password) {
	return new Promise(function (resolve, reject) {
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

			resolve(userInfo);
		})
		.catch(function(err) {
			//console.error(err);
			reject("Login Fail");
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
		});
	});
}

module.exports = router;
