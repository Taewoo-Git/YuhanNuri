const express = require('express');
const router = express.Router();

const cheerio = require('cheerio-httpcli');

const db = require('../public/res/js/database.js')();
const connection = db.init();

db.open(connection,'user');

const moment = require('moment');
require('moment-timezone'); 
moment.tz.setDefault("Asia/Seoul");

const {isUserLoggedIn}=require('./middlewares');

const bcrypt=require('bcrypt');

router.post('/', function(req, res,next) { //POST /user
    const userId = req.body.userId; // 사용자 아이디
    const password = req.body.password; // 사용자 패스워드
	const isAutoLogin = req.body.isAutoLogin; // 자동 로그인 여부
	
	let adminCheckSql = "SELECT empno, empname, password FROM Counselor WHERE empno = ?" // 관리자 계정인지 체크하는 함수

	connection.execute(adminCheckSql, [userId], (err, rows) => {
		
		if(err) {
			console.error(err);
			next(err);
		}
		else if(rows[0] !== undefined) {
			bcrypt.compare(password,rows[0].password).then(function(result){
				if(result){
					let adminInfo = {
						empno : rows[0].empno,
						empname : rows[0].empname
					};

					req.session.adminInfo = adminInfo; // 사용자 정보를 세션으로 저장

					console.info(req.session.adminInfo.empname);

					res.redirect('/admin');
				}else{
					const error=new Error('로그인 정보가 잘못되었습니다.');
					error.status=404;
					next(error); 
				}
			});
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
	// console.log(req.body); 엌ㅋㅋㅋ 비번 털림 ㅋㅋ루삥뽕
	
    const userId = req.body.userId; // 사용자 아이디
    const password = req.body.password; // 사용자 패스워드
	const isAutoLogin = req.body.isAutoLogin; // 자동 로그인 여부
	const userToken = req.body.myToken;
	
	console.log(userToken);
	
	let selectUser = 'SELECT * FROM User WHERE stuno=?';
	let insertToekn = 'UPDATE User SET token=? WHERE stuno=?';
	
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
		
		connection.execute(selectUser, [userInfo.stuCode], (selectErr, rows) => {
			if(selectErr) console.error(selectErr);
			else if(rows.length > 0) {
				connection.execute(insertToekn, [userToken, userInfo.stuCode], (insertErr) => {
					if(insertErr) console.error(insertErr);
				});
			}
		});
		
		res.json(userInfo);
	}, function(error) {
		res.json(null)
		console.error(error);
	});
});

/*router.post('/reservation', function (req, res) { //POST /user/reservation
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
});*/

router.get('/privacy', function (req, res) { //GET /user/privacy
    res.render('privacy');
});

router.post('/privacy', function (req, res) { //POST /user/privacy
	console.info(req.body);
	res.redirect('/');
});

router.get('/question', isUserLoggedIn,function (req, res) { //GET /user/question
    res.render('question');
});

router.post('/question', isUserLoggedIn,function (req, res, next) { //POST /user/question
	// console.info("테슷흐");
	console.info(req.body);
	let questionTitle = req.body.questionTitle;
	let questionText = req.body.questionText;
	let stuno=req.session.userInfo.stuCode;
	let questionInfoSql = "insert into QuestionBoard (stuno, date,title, content) values (?,?,?,?)";
	let nowMoment = moment().format("YYYYMMDD");
	
	connection.execute(questionInfoSql, [stuno,nowMoment,questionTitle,questionText], (err, result) => {
		if(err){
			console.error(err);
			next(err);
		}else {
			console.info("문의 입력 완료")
		}
		res.redirect('/');
	});
});

/*router.get('/reservation', function (req, res,next) { //GET /user/reservation
	let questionSelect = 'SELECT *, (SELECT GROUP_CONCAT(content) FROM FormAnswer WHERE cardno=c.cardno) AS answer '
						+ 'FROM FormTypeContent c WHERE typeno=?';
	
	let mentalTypeSelect = 'SELECT * FROM PsyCounselType';
	
	let questionResult = "";
	
	connection.execute(questionSelect, [0], (err, result) => {
		if(err) console.error(err);
		else {
			connection.execute(mentalTypeSelect, [0], (err, result) =>{
				if(err) console.error(err);
				else{
					res.render('reservation', {result:questionResult, mentalResult:result});
				}
			});
		}
	});
});*/

router.get('/reservation', function (req, res) { //GET /user/reservation
    let questionSelect = 'SELECT * FROM EditTest WHERE no = 3';
	let mentalTypeSelect = 'SELECT * FROM PsyCounselType';
	let questionResult = "";
	
	connection.execute(questionSelect, [0], (err, result) => {
		if(err) console.error(err);
		else {
			questionResult = result;
			connection.execute(mentalTypeSelect, [0], (err, result) => {
				if(err) console.error(err);
				else{
					res.render('reservation', {result:questionResult, mentalResult:result, stuInfo: req.session.userInfo});
				}
			});
		}
	});
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

router.get('/mypage',isUserLoggedIn, function (req, res) { //GET /user/mypage	
	let reservationSelect = 'SELECT date, starttime, status, empno FROM Reservation ' +
		'WHERE typecode=1 AND stuno=? order by date desc';
	let questionSelect='SELECT * from QuestionBoard where stuno=?';
	let isAnswerList=[];
	
	let empno = '';
	let isChatting;	// 0: "예약된 채팅상담이 없습니다."
					// 1: 채팅창 제공
					// 2: "예약 접수를 기다리고 있습니다."
					// 3: "아직 채팅상담 시간이 아닙니다."
	
	connection.execute(reservationSelect, [req.session.userInfo.stuCode], (err, result) => {
		if(err) console.error(err);
		else {					
			if(result.length == 0) isChatting = 0;
			else {
				const now = moment().format('YYYY-MM-DD');
				const rsv = moment(result[0].date.toString()).format('YYYY-MM-DD');

				if(result[0].status === 1) {
					if(now == rsv) {
						if(result[0].starttime === Number(moment().format('HH'))) {
							isChatting = 1;
							empno = result[0].empno;
						}
						else isChatting = 3;
					}
					else if(now > rsv) isChatting = 0;
					else isChatting = 3;
				}
				else isChatting = 2;
			}
		}
	});
	
	connection.execute(questionSelect,[req.session.userInfo.stuCode],(err,rows)=>{
		if(err){
			console.error(err);
		}else{
			rows.forEach((data,index)=>{
				if(data.empno===null && data.answerdata===undefined && data.answer===null){
					isAnswerList.push('미완료');
				}else{
					isAnswerList.push('완료');
				}
			});
			res.render('mypage', {
				stuName: req.session.userInfo.stuName,
				stuCode: req.session.userInfo.stuCode,
				empno: 'emp100001', //empno,
				isChatting: 1, //isChatting,
				questions:rows,
				isAnswerList:isAnswerList,
			});
		}
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
