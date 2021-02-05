const express = require('express');
const router = express.Router();

const cheerio = require('cheerio-httpcli');

const db = require('./database.js')();
const connection = db.init();

db.open(connection,'user');

const moment = require('moment');
require('moment-timezone');
moment.tz.setDefault("Asia/Seoul");

const {isUserLoggedIn} = require('./middlewares');

const bcrypt = require('bcrypt');

const ErrorLogger = require('./logger_error.js');
const logTimeFormat = "YYYY-MM-DD HH:mm:ss";

router.post('/', function(req, res, next) { //POST /user
    const userId = req.body.userId; // 사용자 아이디
    const password = req.body.password; // 사용자 패스워드
	//const isAutoLogin = req.body.isAutoLogin; // 자동 로그인 여부
	
	let adminCheckSql = "SELECT * FROM Counselor WHERE empid = ? and Counselor.use = 'Y'" // 관리자 계정인지 체크하는 함수

	connection.execute(adminCheckSql, [userId], (err, rows) => {
		if(err) {
			ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else if(rows[0] !== undefined) {
			bcrypt.compare(password, rows[0].emppwd).then(function(result){
				if(result) {
					let adminInfo = {
						empid: rows[0].empid,
						empname: rows[0].empname,
						author: rows[0].positionno
					};
					req.session.adminInfo = adminInfo; // 사용자 정보를 세션으로 저장
					
					res.redirect('/admin');
				}
				else {
					res.send("<script>alert('로그인 정보가 잘못되었습니다.'); window.location.href = '/';</script>");
				}
			});
		}
		else res.send("<script>alert('로그인 정보가 잘못되었습니다.'); window.location.href = '/';</script>");
	});
});

router.get('/logout', function(req, res) { //GET /user/logout
    req.session.destroy();
	res.clearCookie('_uid');
    res.redirect('/');
});

router.get('/auto', function(req, res) { //GET /user/auto
	// 자동 로그인 쿠키가 살아있을 경우 해당 경로로 넘어와 세션 생성 후 main으로 이동
	let userInfoSelect = 'SELECT * FROM User WHERE stuno = ?';
	
	connection.execute(userInfoSelect, [req.signedCookies._uid], (err, result) => {
		if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else {
			let userInfo = { // 학생 학번과 이름을 세션으로 저장
				stuCode: result[0].stuno,
				stuName: result[0].stuname,
			};
			req.session.userInfo = userInfo;
			res.redirect('/');
		}
	});
});

router.post('/mobile', function(req, res) { //POST /user/mobile	
    const userId = req.body.userId; // 사용자 아이디
    const password = req.body.password; // 사용자 패스워드
	const isAutoLogin = req.body.isAutoLogin; // 자동 로그인 여부
	const userToken = req.body.myToken; // 스마트폰 토큰
	
	getUserInfo(userId, password)
	.then(function(userInfo) {
		req.session.userInfo = { stuCode: userInfo.stuCode, stuName: userInfo.stuName }; // 학생 학번과 이름을 세션으로 저장

		if(isAutoLogin == 'true') {
			let expiryDate = new Date(Date.now() + 10 * 60 * 1000); // 만료기간 10분, 60 * 60 * 1000 * 24 * 30 == 30일
			res.cookie('_uid', userInfo.stuCode, {
				expires: expiryDate,
				signed: true 
			});
		}
		else {
			res.cookie('_uid', userInfo.stuCode, {
				signed: true 
			});
		}
		
		if(userInfo != null) {
			let selectQuery = "select * from User where stuno = ?";
			let updateQuery = "update User set stuname = ?, birth = ?, major = ?, phonenum = ?, addr = ?, email = ?, token = ? where stuno = ?";
			let insertQuery = "insert into User(stuno, stuname, birth, major, phonenum, addr, email, token) values(?, ?, ?, ?, ?, ?, ?, ?)";
			
			let updateParam = [userInfo.stuName, userInfo.stuBirth, userInfo.stuMajor, userInfo.stuPhoneNum, userInfo.stuAddr, userInfo.stuEmail, userToken, userInfo.stuCode];
			
			let insertParam = [userInfo.stuCode, userInfo.stuName, userInfo.stuBirth, userInfo.stuMajor, userInfo.stuPhoneNum, userInfo.stuAddr, userInfo.stuEmail, userToken];

			connection.execute(selectQuery, [userInfo.stuCode], (err, result) => {
				if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
				else {
					if(result.length > 0) {
						connection.execute(updateQuery, updateParam, (updateErr) => {
							if(updateErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${updateErr}`);
						});
					}
					else if(result.length == 0) {
						connection.execute(insertQuery, insertParam, (insertErr) => {
							if(insertErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${insertErr}`);
						});
					}
				}
			});
		}
		res.json("Login Success");
	}, function(error) {
		//ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${error}`);
		res.json(null)
	});
});

router.get('/question', isUserLoggedIn, function (req, res) { //GET /user/question
    res.render('question');
});

router.post('/question', isUserLoggedIn, function (req, res) { //POST /user/question
	let questionTitle = req.body.questionTitle;
	let questionText = req.body.questionText;
	let questionType = req.body.questionType;
	let stuno=req.session.userInfo.stuCode;
	let questionInfoSql = "insert into QuestionBoard(stuno, type, date, title, content) values (?, ?, ?, ?, ?)";
	let nowMoment = moment().format("YYYYMMDD");
	
	connection.execute(questionInfoSql, [stuno, questionType, nowMoment, questionTitle, questionText], (err, result) => {
		if(err) {
			ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else res.redirect('/');
	});
});

router.get('/satisfaction', isUserLoggedIn, function (req, res) { //GET /user/satisfaction
	let stuno = req.session.userInfo.stuCode;
	let selectTestAsk = "SELECT DISTINCT a.askno, a.ask, t.choicetypename, (SELECT GROUP_CONCAT(choice SEPARATOR '|') FROM ChoiceList WHERE askno = a.askno) AS 'choices' " +
						"FROM AskList a, ChoiceType t WHERE a.typeno = 3 AND a.choicetypeno = t.choicetypeno AND a.use ='Y'";
	
	let selectReservationNo = "SELECT serialno FROM Reservation WHERE stuno = ? AND research = 0 LIMIT 1";
	
	connection.execute(selectReservationNo, [stuno], (err, result) => {
		if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else {
			connection.execute(selectTestAsk, [], (aErr, aResult) => {
				if(aErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${aErr}`);
				else res.render('satisfaction', {serial: result, testAsk: aResult, userInfo: req.session.userInfo});
			});
		}
	});
});

router.post('/satisfaction', isUserLoggedIn, function (req, res, next) { //POST /user/satisfaction
	let insertAnswerLogResearch = "INSERT INTO AnswerLog(serialno, askno, choiceanswer) VALUES(?, ?, ?)";
	let updateReservationResearch = "UPDATE Reservation SET research = 1, researchdatetime = ? WHERE serialno = ?";
	let dataList = JSON.parse(req.body.Fulldata);
	let nowDateTime = moment().format("YYYY-MM-DD HH:mm:ss");
	
	for(let i = 0; i < dataList.length; i++) {
		connection.execute(insertAnswerLogResearch, [req.body.reservationNo, dataList[i].question, dataList[i].answer], (err) => {
			if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
		});
	}
	
	connection.execute(updateReservationResearch, [nowDateTime, req.body.reservationNo], (upErr) => {
		if(upErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${upErr}`);
		else res.send("<script>window.location.href = '/user/mypage';</script>");
	});
});

router.get('/reservation', isUserLoggedIn, function (req, res) { //GET /user/reservation
	let selectReservation = "SELECT COUNT(*) AS cnt FROM Reservation WHERE stuno = ? AND research = 0 LIMIT 1";
	
    let selectUserInfo = "SELECT * FROM User WHERE stuno = ?";
	
	let selectConsultAsk = "SELECT DISTINCT a.askno, a.ask, t.choicetypename, (SELECT GROUP_CONCAT(choice SEPARATOR '|') FROM ChoiceList WHERE askno = a.askno) AS 'choices' " +
						   "FROM AskList a, ChoiceType t WHERE a.typeno = 1 AND a.choicetypeno = t.choicetypeno AND a.use = 'Y'";
	
	let selectTestAsk = "SELECT DISTINCT a.askno, a.ask, t.choicetypename, (SELECT GROUP_CONCAT(choice SEPARATOR '|') FROM ChoiceList WHERE askno=a.askno) AS 'choices' " +
						"FROM AskList a, ChoiceType t WHERE a.typeno = 2 AND a.choicetypeno = t.choicetypeno AND a.use = 'Y'";
	
	let selectPsyTestList = "SELECT * FROM PsyTestList p WHERE p.use = 'Y'";
	
	connection.execute(selectReservation, [req.session.userInfo.stuCode], (selectReservationErr, result) => {
		if(result[0].cnt == 0) {
			connection.execute(selectUserInfo, [req.session.userInfo.stuCode], (userInfoErr, userInfoResult) => {
				if(userInfoErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${userInfoErr}`);
				else {
					connection.execute(selectConsultAsk, [], (caErr, caResult) => {
						if(caErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${caErr}`);
						else {
							connection.execute(selectTestAsk, [], (taErr, taResult) => {
								if(taErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${taErr}`);
								else {
									connection.execute(selectPsyTestList, [], (ptlErr, ptlResult) => {
										if(ptlErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${ptlErr}`);
										else {
											res.render('reservation', {consultAsk: caResult, testAsk: taResult, psyTestList: ptlResult, stuInfo: userInfoResult[0]});
										}
									});
								}
							});
						}
					});
				}
			});
		}
		else res.render('unreservation');
	});
	
});

router.get('/mypage', isUserLoggedIn, function (req, res) { //GET /user/mypage	
	let reservationSelect = 'SELECT date, starttime, status, empid FROM Reservation ' +
		'WHERE typeno = 1 AND stuno = ? AND finished = 0 order by date desc, starttime desc';
	
	let questionSelect='SELECT * from QuestionBoard where stuno = ?';
	
	let reservationCheckSelect = 'SELECT * From Reservation WHERE stuno = ? AND research = 0';
	
	let reservationStatusConsultSelect = 'SELECT t1.typename, t2.empname, t3.serialno, t3.date, t3.starttime, t3.status, t3.finished, t3.research FROM '+
		'ConsultType t1, Counselor t2, Reservation t3 WHERE t3.typeno = t1.typeno AND t3.empid = t2.empid AND t3.stuno = ? AND t3.research = 0';
	
	let reservationStatusPsyTestSelect = 'SELECT t1.serialno, t1.status, t1.finished, t1.research, t3.testname FROM Reservation t1, PsyTest t2, PsyTestList t3 WHERE t1.research = 0 '+
		'AND t1.stuno = ? AND t1.serialno = t2.serialno AND t2.testno = t3.testno;';
	
	let isAnswerList = [];
	let empid = '';
	let isChatting;	// 0: "예약된 채팅상담이 없습니다."
					// 1: 채팅창 제공
					// 2: "예약 접수를 기다리고 있습니다."
					// 3: "아직 채팅상담 시간이 아닙니다."
	
	connection.execute(reservationSelect, [req.session.userInfo.stuCode], (err, result) => {
		if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else {					
			if(result.length == 0) isChatting = 0;
			else {
				const now = moment().format('YYYY-MM-DD');
				const rsv = moment(result[0].date.toString()).format('YYYY-MM-DD');

				if(result[0].status === 1) {
					if(now == rsv) {
						if(result[0].starttime === Number(moment().format('HH'))) {
							isChatting = 1;
							empid = result[0].empid;
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
	
	connection.execute(questionSelect, [req.session.userInfo.stuCode], (err, rows) => {
		if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else {
			rows.forEach((data, index) => {
				if(data.empname === null && data.answerdate === null && data.answer === null) isAnswerList.push('미완료');
				else isAnswerList.push('완료');
			});
			
			connection.execute(reservationCheckSelect, [req.session.userInfo.stuCode], (chErr, chResult) => {
				if(chErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${chErr}`);
				else {
					if(chResult.length !== 0) {
						if(chResult[0].starttime === null) {
							// 심리검사일경우
							connection.execute(reservationStatusPsyTestSelect, [req.session.userInfo.stuCode], (ptErr, ptResult) => {
								if(ptErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${ptErr}`);
								else{
									res.render('mypage', {
										stuName: req.session.userInfo.stuName,
										stuCode: req.session.userInfo.stuCode,
										empid: empid,
										isChatting: isChatting,
										questions: rows,
										isAnswerList: isAnswerList,
										isReservationType: 0,
										reservationBoard: ptResult,
									});
								}
							});
						}
						else { // 상담예약일경우
							connection.execute(reservationStatusConsultSelect, [req.session.userInfo.stuCode], (clErr, clResult) => {
								if(clErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${clErr}`);
								else{
									res.render('mypage', {
										stuName: req.session.userInfo.stuName,
										stuCode: req.session.userInfo.stuCode,
										empid: empid,
										isChatting: isChatting,
										questions: rows,
										isAnswerList: isAnswerList,
										isReservationType: 1,
										reservationBoard: clResult,
									});
								}
							});
						}
					}
					else {
						res.render('mypage', {
							stuName: req.session.userInfo.stuName,
							stuCode: req.session.userInfo.stuCode,
							empid: empid,
							isChatting: isChatting,
							questions: rows,
							isAnswerList: isAnswerList,
							isReservationType: 2,
							reservationBoard: '',
						});
					}
				}
			});
		}
	});
});

router.post('/mypage', isUserLoggedIn, function (req, res, next) { //POST /user/question
	let userReservationNum = req.body.btnCancelReservation;
	let reservationStatusSelect = 'SELECT status, finished FROM Reservation WHERE serialno = ?';
	let reservationCancelSql = 'UPDATE Reservation SET status = 1, finished = 1, research = 1 WHERE serialno = ?';
	
	connection.execute(reservationStatusSelect, [userReservationNum], (err, result) => {
		if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else {
			if(result[0].status === 0 && result[0].finished === 0){
				connection.execute(reservationCancelSql, [userReservationNum], (clErr, clResult) => {
					if(clErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${clErr}`);
					else res.send("<script>alert('취소가 완료되었습니다.'); window.location.href = '/user/mypage';</script>");
				});
			}
			else res.send("<script>alert('접수가 이미 완료되었거나 취소되었습니다.'); window.location.href = '/user/mypage';</script>");
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
			if(result.response.cookies.EnviewSessionId) {
				return cheerio.fetch('http://m.yuhan.ac.kr/bachelor/bcUserInfoR.jsp'); // 사용자 정보 URL
			}
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
			reject("Login Fail");
		})
			.finally(function() {
			cheerio.reset(); // cheerio 초기화 → 로그인 세션 중복 해결
		});
	});
}

module.exports = router;