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

const logger = require('./logger.js');
const logTimeFormat = "YYYY-MM-DD HH:mm:ss";

router.post('/mobile', function(req, res) { //POST /user/mobile	
    const userId = req.body.userId; // 사용자 아이디
    const password = req.body.password; // 사용자 패스워드
	const isAutoLogin = req.body.isAutoLogin; // 자동 로그인 여부
	const userToken = req.body.myToken; // 스마트폰 토큰
	
	getUserInfo(userId, password)
	.then(function(userInfo) {
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

			connection.execute(selectQuery, [userInfo.stuCode], (err1, result) => {
				if(err1) logger.error.info(`[${moment().format(logTimeFormat)}] ${err1}`);
				else {
					if(result.length > 0) {
						connection.execute(updateQuery, updateParam, (err2) => {
							if(err2) logger.error.info(`[${moment().format(logTimeFormat)}] ${err2}`);
						});
					}
					else if(result.length == 0) {
						connection.execute(insertQuery, insertParam, (err3) => {
							if(err3) logger.error.info(`[${moment().format(logTimeFormat)}] ${err3}`);
						});
					}
				}
			});
		}
		res.json("Login Success");
	}, function(error) {
		res.json(null)
	});
});

router.get('/question', isUserLoggedIn, function (req, res) { //GET /user/question
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
    res.render('question');
});

router.post('/question', isUserLoggedIn, function (req, res) { //POST /user/question
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
	
	let questionTitle = req.body.questionTitle;
	let questionText = req.body.questionText;
	let questionType = req.body.questionType;
	
	let questionInfoSql = "insert into QuestionBoard(stuno, type, date, title, content) values (?, ?, ?, ?, ?)";
	
	let nowMoment = moment().format("YYYYMMDD");
	
	connection.execute(questionInfoSql, [req.session._uid, questionType, nowMoment, questionTitle, questionText], (err, result) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else res.redirect('/');
	});
});

router.get('/satisfaction', isUserLoggedIn, function (req, res) { //GET /user/satisfaction
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
	
	let selectTestAsk = "SELECT DISTINCT a.askno, a.ask, t.choicetypename, (SELECT GROUP_CONCAT(choice SEPARATOR '|') FROM ChoiceList WHERE askno = a.askno) AS 'choices' " +
						"FROM AskList a, ChoiceType t WHERE a.typeno = 3 AND a.choicetypeno = t.choicetypeno AND a.use ='Y'";
	
	let selectReservationNo = "SELECT serialno, typeno FROM Reservation WHERE stuno = ? AND research = 0 LIMIT 1";
	
	connection.execute(selectReservationNo, [req.session._uid], (err1, result1) => {
		if(err1) logger.error.info(`[${moment().format(logTimeFormat)}] ${err1}`);
		else {
			connection.execute(selectTestAsk, [], (err2, result2) => {
				if(err2) logger.error.info(`[${moment().format(logTimeFormat)}] ${err2}`);
				else res.render('satisfaction', {serial: result1, testAsk: result2});
			});
		}
	});
});

router.post('/satisfaction', isUserLoggedIn, function (req, res, next) { //POST /user/satisfaction
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
	
	let insertAnswerLogResearch = "INSERT INTO AnswerLog(serialno, askno, choiceanswer) VALUES(?, ?, ?)";
	let updateReservationResearch = "UPDATE Reservation SET research = 1, researchdatetime = ? WHERE serialno = ?";
	let dataList = JSON.parse(req.body.answers);
	let nowDateTime = moment().format("YYYY-MM-DD HH:mm:ss");
	
	for(let i = 0; i < dataList.length; i++) {
		connection.execute(insertAnswerLogResearch, [req.body.reservationNo, dataList[i].question, dataList[i].answer], (err) => {
			if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		});
	}
	
	connection.execute(updateReservationResearch, [nowDateTime, req.body.reservationNo], (err) => {
		if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else res.send("<script>window.location.href = '/user/mypage';</script>");
	});
});

router.get('/reservation', isUserLoggedIn, function (req, res) { //GET /user/reservation
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
	
	let selectReservation = "SELECT COUNT(*) AS cnt FROM Reservation WHERE stuno = ? AND research = 0 LIMIT 1";
	
    let selectUserInfo = "SELECT * FROM User WHERE stuno = ?";
	
	let selectConsultAsk = "SELECT DISTINCT a.askno, a.ask, t.choicetypename, (SELECT GROUP_CONCAT(choice SEPARATOR '|') FROM ChoiceList WHERE askno = a.askno) AS 'choices' " +
						   "FROM AskList a, ChoiceType t WHERE a.typeno = 1 AND a.choicetypeno = t.choicetypeno AND a.use = 'Y'";
	
	let selectTestAsk = "SELECT DISTINCT a.askno, a.ask, t.choicetypename, (SELECT GROUP_CONCAT(choice SEPARATOR '|') FROM ChoiceList WHERE askno=a.askno) AS 'choices' " +
						"FROM AskList a, ChoiceType t WHERE a.typeno = 2 AND a.choicetypeno = t.choicetypeno AND a.use = 'Y'";
	
	let selectPsyTestList = "SELECT * FROM PsyTestList p WHERE p.use = 'Y'";
	
	connection.execute(selectReservation, [req.session._uid], (err1, result1) => {
		if(result1[0].cnt == 0) {
			connection.execute(selectUserInfo, [req.session._uid], (err2, result2) => {
				if(err2) logger.error.info(`[${moment().format(logTimeFormat)}] ${err2}`);
				else {
					connection.execute(selectConsultAsk, [], (err3, result3) => {
						if(err3) logger.error.info(`[${moment().format(logTimeFormat)}] ${err3}`);
						else {
							connection.execute(selectTestAsk, [], (err4, result4) => {
								if(err4) logger.error.info(`[${moment().format(logTimeFormat)}] ${err4}`);
								else {
									connection.execute(selectPsyTestList, [], (err5, result5) => {
										if(err5) logger.error.info(`[${moment().format(logTimeFormat)}] ${err5}`);
										else {
											res.render('reservation', {stuInfo: result2[0], consultAsk: result3, testAsk: result4, psyTestList: result5});
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
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
	
	let reservationSelect = 'SELECT date, starttime, status, empid FROM Reservation ' +
		'WHERE typeno = 1 AND stuno = ? AND finished = 0 order by date desc, starttime desc';
	
	let questionSelect='SELECT * from QuestionBoard where stuno = ?';
	
	let reservationCheckSelect = 'SELECT * From Reservation WHERE stuno = ? AND research = 0';
	
	let reservationStatusConsultSelect = 'SELECT t1.typename, t2.empname, t3.serialno, t3.date, t3.starttime, t3.status, t3.finished, t3.research, t3.typeno ' +
		'FROM ConsultType t1, Counselor t2, Reservation t3 WHERE t3.typeno = t1.typeno AND t3.empid = t2.empid AND t3.stuno = ? AND t3.research = 0';
	
	let reservationStatusPsyTestSelect = 'SELECT t1.serialno, t1.status, t1.finished, t1.research, t1.typeno, t3.testname ' +
		'FROM Reservation t1, PsyTest t2, PsyTestList t3 WHERE t1.research = 0 AND t1.stuno = ? AND t1.serialno = t2.serialno AND t2.testno = t3.testno;';
	
	let selectSudentName = 'SELECT stuname FROM User WHERE stuno = ?';
	
	connection.execute(selectSudentName, [req.session._uid], (err1, result1) => {
		if(err1) logger.error.info(`[${moment().format(logTimeFormat)}] ${err1}`);
		else {
			let isAnswerList = [];
	
			let isChatting;	// 0: "예약된 채팅상담이 없습니다."
							// 1: 채팅창 제공
							// 2: "예약 접수를 기다리고 있습니다."
							// 3: "아직 채팅상담 시간이 아닙니다."
			
			let info = {
				stuName: result1[0].stuname,
				stuCode: req.session._uid,
				empid: '',
			}
			
			connection.execute(reservationSelect, [req.session._uid], (err2, result2) => {
				if(err2) logger.error.info(`[${moment().format(logTimeFormat)}] ${err2}`);
				else {
					
					if(result2.length == 0) isChatting = 0;
					else {
						const now = moment().format('YYYY-MM-DD');
						const rsv = moment(result2[0].date.toString()).format('YYYY-MM-DD');

						if(result2[0].status === 1) {
							if(now == rsv) {
								if(result2[0].starttime === Number(moment().format('HH'))) {
									isChatting = 1;
									info.empid = result2[0].empid;
								}
								else isChatting = 3;
							}
							else if(now > rsv) isChatting = 0;
							else isChatting = 3;
						}
						else isChatting = 2;
					}

					info.isChatting = isChatting;

					connection.execute(questionSelect, [req.session._uid], (err3, result3) => {
						if(err3) logger.error.info(`[${moment().format(logTimeFormat)}] ${err3}`);
						else {
							result3.forEach((data, index) => {
								if(data.empname === null && data.answerdate === null && data.answer === null) isAnswerList.push('미완료');
								else isAnswerList.push('완료');
							});

							info.questions = result3;
							info.isAnswerList = isAnswerList;

							connection.execute(reservationCheckSelect, [req.session._uid], (err4, result4) => {
								if(err4) logger.error.info(`[${moment().format(logTimeFormat)}] ${err4}`);
								else {
									if(result4.length !== 0) {
										if(result4[0].starttime === null) {
											connection.execute(reservationStatusPsyTestSelect, [req.session._uid], (err5, result5) => {
												if(err5) logger.error.info(`[${moment().format(logTimeFormat)}] ${err5}`);
												else {
													info.reservationBoard = result5;
													res.render('mypage', info);
												}
											});
										}
										else {
											connection.execute(reservationStatusConsultSelect, [req.session._uid], (err5, result5) => {
												if(err5) logger.error.info(`[${moment().format(logTimeFormat)}] ${err5}`);
												else {
													info.reservationBoard = result5;
													res.render('mypage', info);
												}
											});
										}
									}
									else {
										info.reservationBoard = null;
										res.render('mypage', info);
									}
								}
							});
						}
					});
				}
			});
		}
	});
});

router.post('/mypage', isUserLoggedIn, function (req, res, next) { //POST /user/question
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
	
	let userReservationNum = req.body.btnCancelReservation;
	let reservationStatusSelect = 'SELECT status, finished FROM Reservation WHERE serialno = ?';
	// let reservationCancelSql = 'UPDATE Reservation SET status = 1, finished = 1, research = 1 WHERE serialno = ?';
	
	let reservationCancelSql = 'DELETE FROM Reservation WHERE serialno = ?';
	connection.execute(reservationStatusSelect, [userReservationNum], (err1, result1) => {
		if(err1) logger.error.info(`[${moment().format(logTimeFormat)}] ${err1}`);
		else {
			if(result1[0].status === 0 && result1[0].finished === 0){
				connection.execute(reservationCancelSql, [userReservationNum], (err2, result2) => {
					if(err2) logger.error.info(`[${moment().format(logTimeFormat)}] ${err2}`);
					else res.send("<script>alert('취소가 완료되었습니다.'); window.location.href = '/user/mypage';</script>");
				});
			}
			else res.send("<script>alert('접수가 이미 완료되었거나 취소되었습니다.'); window.location.href = '/user/mypage';</script>");
		}
	});
});

router.get('/test', function (req, res) {
	const userId = req.query.id;
    const password = req.query.pwd;
	
	getUserInfo(userId, password)
	.then(function(userInfo) {
		res.json(userInfo);
	}, function(error) {
		res.json(error)
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