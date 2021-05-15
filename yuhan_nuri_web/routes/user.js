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

const _Handler = function(query, param) {
	return new Promise(function(resolve, reject) {
		connection.execute(query, param, (err, result) => {
			if(err) {
				logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
				reject(err);
			}
			else resolve(result);
		});
	});
};

router.post('/set/login', function(req, res) {	
	const userToken = req.body.userToken; // 사용자 토큰
    const userId = req.body.userId; // 사용자 아이디
    const password = req.body.password; // 사용자 패스워드
	const isAutoLogin = req.body.isAutoLogin; // 자동 로그인 여부
	
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
		
		getUserGender(userId, password)
		.then(function(gender) {
			let updateUserGener = "update User set gender = ? where stuno = ?";
			connection.execute(updateUserGener, [gender.toString(), userInfo.stuCode], (err, result) => {
				if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			});
		}, function(error) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${error}`);
		});
		
		res.send("success");
	}, function(error) {
		logger.error.info(`[${moment().format(logTimeFormat)}] ${error}`);
		res.send("fail")
	});
});

router.post('/get/status', function(req, res) {
	const userToken = req.body.userToken;
	const command = req.body.command;
	
	const updateToken = "update User set token = 'temp' where token = ?";
	const selectToken = "select stuno from User where token = ?";
    
	if(command === "logout") {
		connection.execute(updateToken, [userToken], (err, result) => {
			if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		});
    }
	else if(command === "login") {
		connection.execute(selectToken, [userToken], (err, result) => {
			if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			else {
				if(result.length > 0) res.send("keep");
				else if(result.length == 0) res.send("again");
			}
		});
	}
});

router.get('/get/home/:page', isUserLoggedIn, function(req, res) {
	const page = parseInt(req.params.page);
	const unit = 6;
	
	let selectHomeBoard = "SELECT * FROM HomeBoard LIMIT " + ((page - 1) * unit).toString() + ", " + unit.toString();
	
	connection.execute(selectHomeBoard, (err, result) => {
		if(err) Logger.Error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else res.send(result);
	});
});

router.get('/get/search/:keyword', isUserLoggedIn, function(req, res) {
	const keyword = req.params.keyword.toString();
	
	let selectSearchedHomeBoard = "SELECT * FROM HomeBoard WHERE title LIKE '%" + keyword + "%' OR content LIKE '%" + keyword + "%'"
	
	connection.execute(selectSearchedHomeBoard, (err, result) => {
		if(err) Logger.Error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else res.send(result);
	});
});

router.post('/get/mypage', isUserLoggedIn, function(req, res) {
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
	
	const selectUser = "SELECT * FROM User WHERE stuno = ?";
	
	const selectLastConsult = "SELECT r.date FROM Reservation r WHERE stuno = ? AND finished = 1 ORDER BY r.date DESC LIMIT 1";
	
	connection.execute(selectUser, [req.session._uid], (err1, result1) => {
		if(err1) Logger.Error.info(`[${moment().format(logTimeFormat)}] ${err1}`);
		else {
			connection.execute(selectLastConsult, [req.session._uid], (err2, result2) => {
				if(err2) Logger.Error.info(`[${moment().format(logTimeFormat)}] ${err2}`);
				else {
					result1[0]['last'] = result2[0] ? result2[0].date : "없음";
					res.json(result1[0]);
				}
			});
		}
	});
});

router.post('/set/push', isUserLoggedIn, function(req, res) {
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
	
	const updateUserToken = "UPDATE User SET token = ? WHERE stuno = ?";
	
	connection.execute(updateUserToken, [req.body.token, req.session._uid], (err) => {
		if(err) Logger.Error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else res.end();
	});
});

router.get('/get/question', isUserLoggedIn, function (req, res) {
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
    
	const selectQuestion = "select * from QuestionBoard where stuno = ?";
	
	connection.execute(selectQuestion, [req.session._uid], (err, result) => {
		if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else res.json(result);
	});
});

router.post('/set/question', isUserLoggedIn, function (req, res) {
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
	
	let questionType = req.body.type;
	let questionTitle = req.body.title;
	let questionContent = req.body.content;
	
	let insertQuestion = "insert into QuestionBoard(stuno, type, date, title, content) values (?, ?, CURDATE(), ?, ?)";
	
	connection.execute(insertQuestion, [req.session._uid, questionType, questionTitle, questionContent], (err, result) => {
		if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else res.end();
	});
});

router.get('/get/reservation', isUserLoggedIn, function (req, res) {
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
	
	let selectReservation = "SELECT COUNT(*) AS cnt FROM Reservation WHERE stuno = ? AND research = 0 LIMIT 1";
	
	let selectConsultAsk = "SELECT DISTINCT a.askno, a.ask, t.choicetypename, (SELECT GROUP_CONCAT(choice SEPARATOR '|') FROM ChoiceList WHERE askno = a.askno) AS 'choices' " +
						   "FROM AskList a, ChoiceType t WHERE a.typeno = 1 AND a.choicetypeno = t.choicetypeno AND a.use = 'Y' ORDER BY a.askno";
	
	let selectTestAsk = "SELECT DISTINCT a.askno, a.ask, t.choicetypename, (SELECT GROUP_CONCAT(choice SEPARATOR '|') FROM ChoiceList WHERE askno=a.askno) AS 'choices' " +
						"FROM AskList a, ChoiceType t WHERE a.typeno = 2 AND a.choicetypeno = t.choicetypeno AND a.use = 'Y' ORDER BY a.askno";
	
	let selectPsyTestList = "SELECT * FROM PsyTestList p WHERE p.use = 'Y' ORDER BY p.testno";
	
	let reservationCheckSelect = 'SELECT * From Reservation WHERE stuno = ? AND research = 0';
	
	let reservationStatusConsultSelect = 'SELECT t1.typename, t2.empname, t3.serialno, t3.date, t3.starttime, t3.status, t3.finished, t3.research, t3.typeno ' +
		'FROM ConsultType t1, Counselor t2, Reservation t3 WHERE t3.typeno = t1.typeno AND t3.empid = t2.empid AND t3.stuno = ? AND t3.research = 0';
	
	let reservationStatusPsyTestSelect = 'SELECT t1.serialno, t1.status, t1.finished, t1.research, t1.typeno, t3.testname ' +
		'FROM Reservation t1, PsyTest t2, PsyTestList t3 WHERE t1.research = 0 AND t1.stuno = ? AND t1.serialno = t2.serialno AND t2.testno = t3.testno;';
	
	connection.execute(selectReservation, [req.session._uid], (err1, result1) => {
		if(result1[0].cnt == 0) {
			connection.execute(selectConsultAsk, [], (err2, result2) => {
				if(err2) logger.error.info(`[${moment().format(logTimeFormat)}] ${err2}`);
				else {
					connection.execute(selectTestAsk, [], (err3, result3) => {
						if(err3) logger.error.info(`[${moment().format(logTimeFormat)}] ${err3}`);
						else {
							connection.execute(selectPsyTestList, [], (err4, result4) => {
								if(err4) logger.error.info(`[${moment().format(logTimeFormat)}] ${err4}`);
								else {
									res.json({isPossible: true, consultAsk: result2, testAsk: result3, psyTestList: result4});
								}
							});
						}
					});
				}
			});
		}
		else {
			connection.execute(reservationCheckSelect, [req.session._uid], (err2, result2) => {
				if(err2) logger.error.info(`[${moment().format(logTimeFormat)}] ${err2}`);
				else {
					if(result2.length !== 0) {
						if(result2[0].starttime === null) {
							connection.execute(reservationStatusPsyTestSelect, [req.session._uid], (err3, result3) => {
								if(err3) logger.error.info(`[${moment().format(logTimeFormat)}] ${err3}`);
								else res.json({isPossible: false, data: result3});
							});
						}
						else {
							connection.execute(reservationStatusConsultSelect, [req.session._uid], (err3, result3) => {
								if(err3) logger.error.info(`[${moment().format(logTimeFormat)}] ${err3}`);
								else res.json({isPossible: false, data: result3});
							});
						}
					}
					else res.end();
				}
			});
		}
	});
});

router.get('/get/counselor', isUserLoggedIn, function (req, res) {
	let selectCounselor = "SELECT empname, empid FROM Counselor WHERE positionno = 1 AND Counselor.use = 'Y'";

	connection.execute(selectCounselor, (err, result) => {
		if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else res.json(result);
	});
});

router.post('/get/schedule', isUserLoggedIn, function (req, res) {
	let selectSchedule = "SELECT DISTINCT(DATE(start)) AS possible FROM Schedule WHERE empid = ? AND DATE(start) > CURDATE() AND calendarId = 'Reservation'";

	connection.execute(selectSchedule, [req.body.empid], (err, result) => {
		if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else res.json(result);
	});
});

router.post('/get/times', isUserLoggedIn, function (req, res) {
	const empid = req.body.empid;
	const consultDate = req.body.consultDate;
	
	const getCanCounselTime = "SELECT scheduleno, HOUR(start) as start, HOUR(end) as end FROM Schedule WHERE calendarId='Reservation' AND DATE(start) = ? AND empid = ?";
			
	const subtractReservation = "select starttime from Reservation where date = ? and empid = ? and status = 1 and finished = 0";

	let scheduled_time = [];

	connection.execute(getCanCounselTime, [consultDate, empid], (err1, result1) => {
		if(err1) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err1}`);
		}
		else if(result1.length !== 0) {
			connection.execute(subtractReservation, [consultDate, empid], (err2, result2) => {
				if(err2) {
					logger.error.info(`[${moment().format(logTimeFormat)}] ${err2}`);
				}
				else {
					result1.forEach((value, index) => {
						for(let time = value.start; time < value.end; time++) {
							scheduled_time.push(time);
						}
					});

					result2.forEach((value, index) => {
						if(scheduled_time.indexOf(value.starttime) != -1) {
							scheduled_time.splice(scheduled_time.indexOf(value.starttime), 1);	
						}
					});

					res.json(scheduled_time);
				}
			});
		}
	});
});

router.get('/get/selfcheck', isUserLoggedIn, function (req, res) {
	let selectSelfCheck = "SELECT checkno, checkname FROM SelfCheckList s WHERE s.use = 'Y' ORDER BY checkno";

	connection.execute(selectSelfCheck, [], (err, result) => {
		if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else res.json(result);
	});
});

router.post('/set/reservation', isUserLoggedIn, function (req, res) {
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
	
	const recv = req.body;
	
	let serialno = 0;
	
	let userInfo;
	
	let selectUserInfo = "SELECT * FROM User WHERE stuno = ?";
	
	let selectSimpleApplyForm = "SELECT MAX(serialno) AS serialno from SimpleApplyForm";

	let insertSimpleApplyFormMental = "INSERT INTO SimpleApplyForm(serialno, stuno, stuname, gender, birth, email, date) " +
									  "VALUES(?, ?, ?, ?, ?, ?, CURDATE())";

	let insertReservationMental = "INSERT INTO Reservation(serialno, stuno) VALUES(?, ?)";

	let insertAnswerLogMental = "INSERT INTO AnswerLog(serialno, askno, choiceanswer) VALUES(?, ?, ?)";

	let insertPsyTest = "INSERT INTO PsyTest(serialno, testno) VALUES(?, ?)";

	let insertSimpleApplyFormConsult = "INSERT INTO SimpleApplyForm(serialno, stuno, stuname, gender, birth, email, date) " +
									   "VALUES(?, ?, ?, ?, ?, ?, CURDATE())";

	let insertReservationConsult = "INSERT INTO Reservation(serialno, stuno, empid, typeno, date, starttime) VALUES(?, ?, ?, ?, ?, ?)";

	let insertAnswerLogConsult = "INSERT INTO AnswerLog(serialno, askno, choiceanswer) VALUES(?, ?, ?)";

	let insertSelfCheck = "INSERT INTO SelfCheck(serialno, checkno, score) VALUES(?, ?, ?)";
	
	_Handler(selectUserInfo, [req.session._uid])
	.then((result) => {
		userInfo = result[0];
		return _Handler(selectSimpleApplyForm, []);
	})
	.then((result) => {
		const now = new Date().getFullYear().toString().substring(2, 4);

		if (parseInt(now) > parseInt(userInfo.birth.substring(0, 2))) {
			userInfo.birth = "20" + userInfo.birth.substring(0, 2) + "-" + userInfo.birth.substring(2, 4) + "-" + userInfo.birth.substring(4, 6);
		}
		else {
			userInfo.birth = "19" + userInfo.birth.substring(0, 2) + "-" + userInfo.birth.substring(2, 4) + "-" + userInfo.birth.substring(4, 6);
		}

		if(result.length == 0) serialno = 1;
		else if(result.length > 0) serialno = result[0].serialno + 1;

		let simpleApplyFormData = [
			serialno,
			userInfo.stuno,
			userInfo.stuname,
			userInfo.gender,
			userInfo.birth,
			userInfo.email
		];
		
		if (recv.type === 1) {
			return _Handler(insertSimpleApplyFormConsult, simpleApplyFormData);
		}
		else if (recv.type === 2) {
			return _Handler(insertSimpleApplyFormMental, simpleApplyFormData);
		}
	})
	.then(() => {
		if (recv.type === 1) {
			let reservationDate = [
				serialno,
				userInfo.stuno,
				recv.empid,
				recv.reservationCode,
				recv.date,
				recv.time
			];
			
			return _Handler(insertReservationConsult, reservationDate);
		}
		else if (recv.type === 2) {
			return _Handler(insertReservationMental, [serialno, userInfo.stuno]);
		}
	})
	.then(() => {
		if (recv.type === 1) {
			for (let i = 0; i < recv.stuAnswer.length; i++) {
				_Handler(insertAnswerLogConsult, [serialno, recv.stuAnswer[i].question, recv.stuAnswer[i].answer]);
			}

			for (let i = 0; i < recv.selfcheckCode.length; i++) {
				_Handler(insertSelfCheck, [serialno, recv.selfcheckCode[i], recv.selfcheckNum[i]]);
			}
		}
		else if (recv.type === 2) {
			for (let i = 0; i < recv.stuAnswer.length; i++) {
				_Handler(insertAnswerLogMental, [serialno, recv.stuAnswer[i].question, recv.stuAnswer[i].answer]);
			}

			for (let i = 0; i < recv.psyTestList.length; i++) {
				_Handler(insertPsyTest, [serialno, recv.psyTestList[i]]);
			}
		}
	})
	.catch((e) => console.error(e))
	.finally(() => res.end());
});

router.get('/get/selfcheck', isUserLoggedIn, function (req, res) {
	let selectSelfCheck = "SELECT checkno, checkname FROM SelfCheckList s WHERE s.use = 'Y' ORDER BY checkno";

	connection.execute(selectSelfCheck, [], (err, result) => {
		if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else res.json(result);
	});
});

router.post('/set/cancel', isUserLoggedIn, function (req, res, next) {
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
	
	const serialno = req.body.serialno;
	const selectReservationStatus = 'SELECT status, finished FROM Reservation WHERE serialno = ?';
	const deleteReservation = 'DELETE FROM Reservation WHERE serialno = ?';
	
	connection.execute(selectReservationStatus, [serialno], (err1, result1) => {
		if(err1) logger.error.info(`[${moment().format(logTimeFormat)}] ${err1}`);
		else if(result1.length > 0) {
			if(result1[0].status === 0 && result1[0].finished === 0){
				connection.execute(deleteReservation, [serialno], (err2, result2) => {
					if(err2) logger.error.info(`[${moment().format(logTimeFormat)}] ${err2}`);
					else res.json({isComplete: true});
				});
			}
			else res.json({isComplete: false});
		}
		else res.json({isComplete: false});
	});
});

router.get('/get/satisfaction', isUserLoggedIn, function (req, res) {
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
	
	let selectTestAsk = "SELECT DISTINCT a.askno, a.ask, t.choicetypename, (SELECT GROUP_CONCAT(choice SEPARATOR '|') FROM ChoiceList WHERE askno = a.askno) AS 'choices' " +
						"FROM AskList a, ChoiceType t WHERE a.typeno = 3 AND a.choicetypeno = t.choicetypeno AND a.use = 'Y' ORDER BY a.askno";
	
	let selectReservationNo = "SELECT serialno, typeno FROM Reservation WHERE stuno = ? AND research = 0 LIMIT 1";
	
	connection.execute(selectReservationNo, [req.session._uid], (err1, result1) => {
		if(err1) logger.error.info(`[${moment().format(logTimeFormat)}] ${err1}`);
		else {
			connection.execute(selectTestAsk, [], (err2, result2) => {
				if(err2) logger.error.info(`[${moment().format(logTimeFormat)}] ${err2}`);
				else res.json({serial: result1, testAsk: result2});
			});
		}
	});
});

router.post('/set/satisfaction', isUserLoggedIn, function (req, res) {
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
	
	let insertAnswerLogResearch = "INSERT INTO AnswerLog(serialno, askno, choiceanswer) VALUES(?, ?, ?)";
	let updateReservationResearch = "UPDATE Reservation SET research = 1, researchdatetime = NOW() WHERE serialno = ?";
	
	for(let i = 0; i < req.body.dataList.length; i++) {
		connection.execute(insertAnswerLogResearch, [req.body.serialno, req.body.dataList[i].question, req.body.dataList[i].answer], (err) => {
			if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		});
	}
	
	connection.execute(updateReservationResearch, [req.body.serialno], (err) => {
		if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
	});
	
	res.end();
});

router.get('/get/chat', isUserLoggedIn, function (req, res) {
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
	
	let selectSudentName = 'SELECT stuname FROM User WHERE stuno = ?';
	
	let reservationSelect = 'SELECT date, starttime, status, empid FROM Reservation ' +
							'WHERE typeno = 1 AND stuno = ? AND finished = 0 order by date desc, starttime desc';
	
	connection.execute(selectSudentName, [req.session._uid], (err1, result1) => {
		if(err1) logger.error.info(`[${moment().format(logTimeFormat)}] ${err1}`);
		else {
			connection.execute(reservationSelect, [req.session._uid], (err2, result2) => {
				if(err2) logger.error.info(`[${moment().format(logTimeFormat)}] ${err2}`);
				else {
					if(result2.length == 0) res.json({status: 0});
					else {
						const info = {
							stuno: req.session._uid,
							stuname: result1[0].stuname,
						};
						
						let status;	// 0: "예약된 채팅상담이 없습니다."
									// 1: "상담 대기 중입니다, 잠시만 기다려 주세요."
									// 2: "예약 접수를 기다리고 있습니다."
									// 3: "아직 채팅상담 시간이 아닙니다."
						
						const now = moment().format('YYYY-MM-DD');
						const rsv = moment(result2[0].date.toString()).format('YYYY-MM-DD');

						if(result2[0].status === 1) {
							if(now == rsv) {
								if(result2[0].starttime === Number(moment().format('HH'))) {
									status = 1;
									info.empid = result2[0].empid;
								}
								else status = 3;
							}
							else if(now > rsv) status = 0;
							else status = 3;
						}
						else status = 2;
						
						info.status = status;
						
						res.json(info);
					}
				}
			});
		}
	});
});

let getUserGender = function(userId, password) {
	return new Promise(function (resolve, reject) {
		let url = 'http://portal.yuhan.ac.kr/user/loginProcess.face?userId=' + userId + '&password=' + password;
		
		cheerio.set('browser', 'android'); // user-agent 설정
		cheerio.fetch(url)
			.then(function(result) {
			if(result.response.cookies.EnviewSessionId) {
				return cheerio.fetch('https://m.yuhan.ac.kr/bachelor/RgstReport.jsp?printDiv=1&reportType=8');
			}
		})
			.then(function(result) {
			let mrd_param = result.body.split('mrd_param')[2].split("\"")[1].trim();
			
			let body = {
				opcode: 700,
				mrd_path: 'https://info.yuhan.ac.kr/yhcdoc/reports/suh/SuhrGradeSumTable_3.mrd',
				mrd_param: '/rp ' + mrd_param + ' /rsn [yhc]',
				mrd_plain_param: '',
				mrd_data: '',
				runtime_param: '',
				mmlVersion: 0,
				protocol: 'sync'
			}
			
			return cheerio.fetch('https://rd.yuhan.ac.kr/ReportingServer/service', body);
		})
			.then(function(result) {
			let genderNum = parseInt(result.body.split('주민등록번호')[1].split('*')[0].split('-')[1]);
			let genderStr = "";
			
			if(genderNum % 2 === 1) genderStr = "남성";
			else genderStr = "여성";
			
			resolve(genderStr);
		})
			.catch(function(err) {
			reject("Fail");
		})
			.finally(function() {
			cheerio.reset(); // cheerio 초기화 → 로그인 세션 중복 해결
		});
	});
}

let getUserInfo = function(userId, password) {
	return new Promise(function (resolve, reject) {
		let tempInfo = []; // 임시 배열
		let userInfo = null; // 사용자 정보
		let url = 'http://portal.yuhan.ac.kr/user/loginProcess.face?userId=' + userId + '&password=' + password; // 로그인 세션 URL
		
		cheerio.set('browser', 'android'); // user-agent 설정
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
			//console.log(result.response.req._header); // Header 확인 로그
			
			if(userInfo.stuCode.trim() === "") reject();
			else resolve(userInfo);
		})
			.catch(function(err) {
			reject();
		})
			.finally(function() {
			cheerio.reset(); // cheerio 초기화 → 로그인 세션 중복 해결
		});
	});
}

/*
router.get('/verify/:id/:pwd', function (req, res) {
	const userId = req.params.id;
    const userPwd = req.params.pwd;
	
	getUserInfo(userId, userPwd)
	.then(function(userInfo) {
		res.send(userInfo);
	}, function(error) {
		res.json(error)
	});
});
*/

module.exports = router;