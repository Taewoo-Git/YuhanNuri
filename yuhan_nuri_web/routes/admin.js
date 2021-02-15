const express = require('express');
const router = express.Router();

const db = require('./database.js')();
const connection = db.init();
db.open(connection, "admin");

const sanitizeHtml = require('sanitize-html');
const bcrypt = require('bcrypt');

const fs = require('fs');
const path = require('path');
const multer = require('multer');

const schedule = require('node-schedule');
const pdfDocument = require('pdfkit');

const {ReservationAcceptPush, AnswerPush, SatisfactionPush, NoticeReservationCancelPush} = require('./fcm'); 
const {isAdminLoggedIn, isAccessDenied} = require('./middlewares');  

const excel = require('exceljs');

const moment = require("moment");
require('moment-timezone'); 
moment.tz.setDefault("Asia/Seoul");

let deleteRule = new schedule.RecurrenceRule();
deleteRule.dayOfWeek = [0, new schedule.Range(0,6)];
deleteRule.hour = 00;
deleteRule.minute = 00;

const logger = require('./logger.js');
const logTimeFormat = "YYYY-MM-DD HH:mm:ss";

router.use(function(req, res, next) {
     res.locals.adminInfo = req.session.adminInfo;
     next();
});

try {
	// uploads 폴더가 없을 경우 생성
	fs.readdirSync('uploads');
}
catch(error) {
	fs.mkdirSync('uploads');
}

const upload = multer({
	storage: multer.diskStorage({
		destination(req, file, cb) {
			cb(null, 'uploads/');
		},
		filename(req, file, cb) {
			const ext = path.extname(file.originalname);
			cb(null, path.basename(file.originalname, ext) + Date.now() + ext);
		},
	}),
	limits: {fileSize: 5 * 1024 * 1024}, // 5MB
});

router.get("/", isAdminLoggedIn, function(req, res, next) { //GET /admin
	const getReservationData = "SELECT User.stuname as stuname, User.phonenum as phonenum, reserv.serialno as no, " +
		  "reserv.stuno as stuno, consult.typename as typename, reserv.starttime as starttime, reserv.date as date " +  
		  "FROM User JOIN Reservation reserv ON User.stuno = reserv.stuno LEFT JOIN ConsultType consult ON reserv.typeno = consult.typeno " +
		  "WHERE reserv.status = 0 AND (reserv.empid = ? OR reserv.empid IS NULL) ORDER BY no";
	
	const getReservationData_forWorkstu = "SELECT User.stuname as stuname, User.phonenum as phonenum, reserv.serialno as no, " +
		  "reserv.stuno as stuno, consult.typename as typename, reserv.starttime as starttime, reserv.date as date " +  
		  "FROM User JOIN Reservation reserv ON User.stuno = reserv.stuno LEFT JOIN ConsultType consult ON reserv.typeno = consult.typeno " +
		  "WHERE reserv.status = 0 ORDER BY no";
	
	let author = req.session.adminInfo.author;
	let empid = req.session.adminInfo.empid;
	
	if(author === 1) {
		connection.execute(getReservationData, [empid], (err, rows) => {
			if(err) {
				logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
				next(err);
			}
			else res.render('admin', {getReservation: rows});
		});
	}
	else res.redirect('admin/schedule');
});

router.post('/login', function(req, res, next) { //POST /user
	const userId = req.body.userId; // 사용자 아이디
    const password = req.body.password; // 사용자 패스워드
	//const isAutoLogin = req.body.isAutoLogin; // 자동 로그인 여부
	
	let adminCheckSql = "SELECT * FROM Counselor WHERE empid = ? and Counselor.use = 'Y'" // 관리자 계정인지 체크하는 함수

	connection.execute(adminCheckSql, [userId], (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
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
				else res.send("<script>alert('로그인 정보가 잘못되었습니다.'); window.location.href = '/';</script>");
			});
		}
		else res.send("<script>alert('로그인 정보가 잘못되었습니다.'); window.location.href = '/';</script>");
	});
});

router.get('/myname', isAdminLoggedIn, (req, res, next) => {
	res.json({name: req.session.adminInfo.empname});
});

router.get('/explanation', isAdminLoggedIn, (req, res, next) => {
	res.render('adminExplanation');
});

router.post('/explanation', isAdminLoggedIn, (req, res, next) => {
	req.session.fileSave = 'yes';
	
	const fileUrl = req.body.fileUrl;
	const content = req.body.content;
	const empid = req.session.adminInfo.empid;
	const empname = req.session.adminInfo.empname;
	
	let fileType = "";

	const insertExplanation = "INSERT INTO Explanation(empid, empname, content, filetype, savetime) VALUES(?, ?, ?, ?, NOW());";
	const selectStuname = "SELECT User.stuname FROM Reservation reserv JOIN User ON reserv.stuno = User.stuno WHERE reserv.serialno = ?";
	
	switch(fileUrl) {
		case "getMyReservationHistory":
			fileType = "내 예약 내역";
			break;
		case "getSatisfactionResult":
			fileType = "만족도조사"
			break;
		case "getAllReservationHistory":
			fileType = "전체 예약 내역";
			break;
		case "getAllChatLog":
			fileType = "전체 채팅 내역";
			break;
		default:
			break;
	}

	if(fileUrl.includes("getSimpleApplyFormPDF")) {
		let serialno = fileUrl.split('/')[1];

		connection.execute(selectStuname, [serialno], (err1, rows) => {
			if(err1) logger.error.info(`[${moment().format(logTimeFormat)}] ${err1}`);
			else {	
				fileType = `${rows[0].stuname} 학생 간단 신청서`;

				connection.execute(insertExplanation, [empid, empname, content, fileType], (err2) => {
					if(err2) logger.error.info(`[${moment().format(logTimeFormat)}] ${err2}`);
					else {
						res.send("<script>opener.location.href = '/admin/" + fileUrl + "'; window.close();</script>");
						logger.file.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${fileType}을(를) 저장.`);
					}
				});
			}
		});
	}
	else {
		connection.execute(insertExplanation, [empid, empname, content, fileType], (err1) => {
			if(err1) logger.error.info(`[${moment().format(logTimeFormat)}] ${err1}`);
			else {
				res.send("<script>opener.location.href = '/admin/" + fileUrl + "'; window.close();</script>");
				logger.file.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${fileType}을(를) 저장.`);
			}
		});
	}
});

router.post("/readReservedSchedule", isAdminLoggedIn, function(req, res, next) {	
	const sql_readReservedSchedule = "SELECT consulttype.typename as typename, user.stuno as stuno, " +
		  "user.stuname as stuname, reserv.date as date, reserv.finished as finished, reserv.empid, " +
		  "reserv.starttime as starttime, reserv.date as date " +
		  "FROM Reservation reserv JOIN User user ON reserv.stuno = user.stuno " +
		  "JOIN ConsultType consulttype ON reserv.typeno = consulttype.typeno " +
		  "WHERE reserv.empid = ? AND reserv.status = 1";
	
	const sql_readReservedSchedule_forWorkstu = "SELECT consulttype.typename as typename, user.stuno as stuno, " +
		  "user.stuname as stuname, reserv.date as date, reserv.finished as finished, reserv.empid, " +
		  "reserv.starttime as starttime, reserv.date as date, Counselor.empname as empname " +
		  "FROM Reservation reserv JOIN User user ON reserv.stuno = user.stuno " +
		  "JOIN ConsultType consulttype ON reserv.typeno = consulttype.typeno JOIN Counselor " +
		  "ON reserv.empid = Counselor.empid WHERE reserv.status = 1";
	
	let sql_getReservedSchedule = "";
	
	// 수락이 된 것만 스케줄에 표시가 됨
	const sql_maxIdInSchedule = "SELECT MAX(scheduleno) as maxIdValue FROM Schedule";
	const date_format = "YYYY-MM-DD HH:mm:ss";
	
	let maxid = 0;
	let empid = req.session.adminInfo.empid;
	
	connection.execute(sql_maxIdInSchedule, (err, rows) => {
		if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else {
			if(rows.length > 0) maxid = rows[0].maxIdValue;
			
			if(req.session.adminInfo.author === 1) sql_getReservedSchedule = sql_readReservedSchedule;
			else sql_getReservedSchedule = sql_readReservedSchedule_forWorkstu;
			
			connection.execute(sql_getReservedSchedule, [empid], (err, rows) => {
				if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
				else{
					rows.forEach((row, index, arr) => {
						maxid++;
						row.id = '\'' + maxid + '\'';
						
						if(row.finished === 1) row.calendarId = "Finished";
						else row.calendarId = "Reserved";
						
						if(req.session.adminInfo.author === 1) row.title = `${row.starttime}시 ${row.stuname} 학생 ${row.typename}`;
						else row.title = `${row.starttime}시 ${row.stuname} 학생 ${row.typename} - ${row.empname} 선생님`;

						if(row.starttime / 10 >= 1) {
							row.start = row.date + "T" + row.starttime + ":00:00";
							row.end = row.date + "T" + (row.starttime + 1) + ":00:00";
						}
						else {
							row.start = row.date + "T" + "0" + row.starttime + ":00:00";
							row.end = row.date + "T" + (row.starttime + 1) + ":00:00";
						}
					});
					rows = rows.filter(row => row.date != null);
					res.json({reserved: rows});	
				}
			});
		}
	});
});

// 관리자 계정에 따라 자신의 스케줄을 가져옴.
router.post("/readMySchedule", isAdminLoggedIn, function(req, res, next) {
	const sql_readMySchedule = "SELECT scheduleno, Schedule.empid, calendarId, title, category, " +
		  "start, end, location, empname FROM Schedule JOIN Counselor ON " +
		  "Schedule.empid = Counselor.empid WHERE Schedule.empid = ?";
	
	const sql_readAllCounselorSchedule_forWorkstu = "SELECT scheduleno, Schedule.empid, calendarId, " +
		  "title, category, start, end, location, empname FROM Schedule " +
		  "JOIN Counselor ON Schedule.empid = Counselor.empid";
	
	let empid = req.session.adminInfo.empid;
	
	if(req.session.adminInfo.author === 2) {
		connection.execute(sql_readAllCounselorSchedule_forWorkstu, [empid], (err, rows) => {
			if(rows.length > 0) {
				rows.forEach((row, index) => {
					if(row.hasOwnProperty("empname")) row.title = row.title + " - " + row.empname + " 선생님"; 
				});
				res.json({schedules: rows});	
			}
		});
	}
	else {
		connection.execute(sql_readMySchedule, [empid], (err, rows) => {
			if(rows.length > 0) res.json({schedules: rows});
		});
	}
});

// 자신의 스케줄을 변경하는 부분
router.post("/updateSchedule", isAdminLoggedIn, function(req, res, next) {
	const datetime_format = "YYYY-MM-DD HH:mm:ss";
	
	let sql_updateSchedule = "UPDATE Schedule SET ";

	let data = JSON.parse(req.body.sendAjax);
	
	let empid = req.session.adminInfo.empid;
	
	if(data.changes.hasOwnProperty("start")) data.changes.start = moment(new Date(data.changes.start._date)).format(datetime_format);
	if(data.changes.hasOwnProperty("end")) data.changes.end = moment(new Date(data.changes.end._date)).format(datetime_format);

	let keys = Object.keys(data.changes);
	let values = Object.values(data.changes);

	keys.forEach((item, index) => {
		sql_updateSchedule += (item.toString() +  " = ?,");
	});

	sql_updateSchedule = sql_updateSchedule.slice(0, -1); // 마지막, 지움

	sql_updateSchedule += ` WHERE scheduleno = ${data.id} AND empid = '${empid}'`;

	connection.execute(sql_updateSchedule, values, (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else {
			res.json({state: "ok"});
			logger.schedule.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 스케줄을 수정.`);
		}
	});	
});

// 스케줄 삭제
router.post("/deleteSchedule", isAdminLoggedIn, function(req, res, next) {
	let data = JSON.parse(req.body.sendAjax);
	let session_empid = req.session.adminInfo.empid;
	
	const sql_deleteSchedule = "DELETE FROM Schedule WHERE scheduleno = ?";
	
	connection.execute(sql_deleteSchedule, [data.id], (err) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else {
			res.json({state: "ok"});
			logger.schedule.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 스케줄을 삭제.`);
		}
	});
});

// 스케줄을 새로 생성하는 부분
router.post("/createSchedule", isAdminLoggedIn, function(req, res, next) {
	const sql_createSchedule = "INSERT INTO Schedule(empid, calendarId, title, category, start, end, location) VALUES (?, ?, ?, ?, ?, ?, ?)";
	const sql_getAlreadyScheduled = "SELECT HOUR(start) as start, HOUR(end) as end FROM Schedule WHERE DATE(start) = ? AND empid = ?";
	
	const datetime_format = "YYYY-MM-DD HH:mm:ss";
	const date_format = "YYYY-MM-DD";
	
	let scheduled_hour = [];
	let createad_hour = [];
	
	let data = JSON.parse(req.body.sendAjax);
	let empid = req.session.adminInfo.empid;
	
	let start = moment(new Date(data.start)).format(datetime_format);
	let end = moment(new Date(data.end)).format(datetime_format);
	
	
	let startIndex = moment(new Date(data.start)).format(date_format);
	let endIndex = moment(new Date(data.end)).format(date_format);
	
	
	let location = "";
	
	let session_empid = req.session.adminInfo.empid;
	
	if(data.location != undefined) location = data.location;
	
	if(startIndex != endIndex) res.json({state: "diff"});
	else {
		connection.execute(sql_getAlreadyScheduled, [startIndex, session_empid], (err, row) => {
			if(err) {
				logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
				next(err);
			}
			else{
				if(row.length > 0) {
					for(let rownum = 0; rownum < row.length; rownum++){
						for(let time = row[rownum].start; time <= row[rownum].end; time++) {
							if(scheduled_hour.lastIndexOf(time) == -1){
								scheduled_hour.push(time); // 이건 기존 스케줄 표에서 가져온 스케줄
							}
						}
					}
					
					let created_start = new Date(start).getHours();
					let created_end = new Date(end).getHours();
					
					// 이건 입력한 스케줄
					for(let time = created_start; time <= created_end; time++) {
						createad_hour.push(time);
					}
					
					if(createad_hour.length == 1) res.json({state : "inputerrtime"});
					else {
						let isDuplicateArray = createad_hour.filter((item) => scheduled_hour.includes(item));
					
						if(isDuplicateArray.length > 1) res.json({state: "duplicate"});
						else {
							connection.execute(sql_createSchedule, [empid, data.calendarId, data.title, data.category, start, end, location], (err) => {
								if(err) {
									logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
									next(err);
								}
								else {
									res.json({state: "ok"});
									logger.schedule.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 스케줄을 생성.`);
								}
							});
						}
					}
				}
				else {
					connection.execute(sql_createSchedule, [empid, data.calendarId, data.title, data.category, start, end, location], (err) => {
						if(err) {
							logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
							next(err);
						}
						else {
							res.json({state: "ok"});
							logger.schedule.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 스케줄을 생성.`);
						}
					});
				}
			}
		});
	}
});

router.post("/accessReservation", isAdminLoggedIn, function(req, res, next) { //POST /admin/accessReservation
	const setAccessReservationData = "UPDATE Reservation SET status = 1, finished = ?, empid = ? WHERE serialno = ?";
	const isPsyTest = "SELECT typeno FROM Reservation WHERE serialno = ?";
	
	let serialno = req.body.serialno;
	let empid = req.session.adminInfo.empid;
	
	connection.execute(isPsyTest, [serialno], (err, row) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else {
			let psyTestno = 0;
			
			if(row[0].typeno === null) psyTestno = 1;
			
			connection.execute(setAccessReservationData, [psyTestno, empid, serialno], (err, rows) => {
				if(err) {
					logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
					next(err);
				}
				else {
					ReservationAcceptPush(serialno);
					res.json({getReservation: rows});
					logger.reservation.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${serialno}번 예약을 확정.`);
				}
			});
		}
	});
});

router.post("/cancelReservation", isAdminLoggedIn, function(req, res, next) { //POST /admin/cancelReservation
	const onlyDeleteReservation = "DELETE FROM Reservation WHERE serialno = ?";
	const selectStuNum = "SELECT stuno FROM Reservation WHERE serialno = ?";
	let serialno = req.body.serialno;
	
	connection.execute(selectStuNum, [serialno], (err1, rows1) => {
		if(err1) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err1}`);
			next(err1);
		}
		else {
			if(rows1.length > 0) {
				let stuno = rows1[0].stuno;
				
				NoticeReservationCancelPush(stuno);
				
				connection.execute(onlyDeleteReservation, [serialno], (err2, rows2) => {
					if(err2) {
						logger.error.info(`[${moment().format(logTimeFormat)}] ${err2}`);
						next(err2);
					}
					else {
						res.json({state: "ok"});
						logger.reservation.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${serialno}번 예약을 취소.`);
					}
				});
			}
		}
	});
});

router.post("/getMentalApplyForm", isAdminLoggedIn, function(req, res, next) { //POST /admin/getMentalApplyForm
	const query = "SELECT a.serialno, a.stuno, a.stuname, a.gender, a.birth, a.email, a.date, " +
				  "GROUP_CONCAT(b.ask SEPARATOR '|') AS 'asks', GROUP_CONCAT(c.choiceanswer SEPARATOR '|') AS 'answers', " +
				  "(SELECT GROUP_CONCAT(testname) FROM PsyTestList list, " +
				  "(SELECT testno FROM PsyTest WHERE serialno = ?) psy WHERE psy.testno = list.testno) AS 'testnames' " +
				  "FROM SimpleApplyForm a, AskList b, AnswerLog c " +
				  "WHERE a.serialno = ? and a.serialno = c.serialno and c.askno = b.askno";
	
	let serialno = req.body.serialno;
	
	connection.execute(query, [serialno, serialno], (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else res.json(rows[0]);
	});
});

router.post("/getConsultApplyForm", isAdminLoggedIn, function(req, res, next) { //POST /admin/getMentalApplyForm
	const query = "SELECT a.serialno, a.stuno, a.stuname, a.gender, a.birth, a.email, a.date, " +
				  "GROUP_CONCAT(b.ask SEPARATOR '|') AS 'asks', " +
				  "GROUP_CONCAT(c.choiceanswer SEPARATOR '|') AS 'answers', " +
				  "selfcheck.checknames, selfcheck.scores " +
				  "FROM SimpleApplyForm a, AskList b, AnswerLog c, " +
				  "(SELECT GROUP_CONCAT(list.checkname SEPARATOR '|') AS 'checknames', " +
				  "GROUP_CONCAT(self.score SEPARATOR '|') AS 'scores' " +
				  "FROM SelfCheckList list, SelfCheck self " +
				  "WHERE self.serialno = ? and self.checkno = list.checkno) selfcheck " +
				  "WHERE a.serialno = ? and a.serialno = c.serialno and c.askno = b.askno";
	
	let serialno = req.body.serialno;
	
	connection.execute(query, [serialno, serialno], (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else res.json(rows[0]);
	});
});

router.get("/chat", isAccessDenied, (req, res, next) => {
	res.render('adminChattingForm', {
		empid: req.session.adminInfo.empid,
		empname: req.session.adminInfo.empname
	});
});

router.get("/schedule", isAdminLoggedIn, function(req, res, next) { //GET /admin/adminTest
	res.render('adminCalendar');
});

router.get("/settings", isAccessDenied, function(req, res, next) {
	const sql_selectCounselor="select empid, empname, positionno from Counselor where Counselor.use = 'Y'";
	connection.execute(sql_selectCounselor, (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else res.render('adminSetting', {result: rows});
	});
});

router.post('/uploadFile', isAdminLoggedIn, upload.single('file'), function(req, res, next) {
	res.json({
		"location": "/" + req.file.path.toString(),
	});
});

router.get('/logout', isAdminLoggedIn, function(req, res) { //GET /user/logout
    req.session.destroy();
	res.clearCookie('isAutoLogin');
    res.redirect('/');
});

router.get('/question', isAdminLoggedIn, function(req, res) {
	const sql_selectQuestion='SELECT DISTINCT t1.*, t2.stuname, t2.phonenum FROM QuestionBoard t1, User t2 WHERE t1.stuno = t2.stuno AND  answer IS NULL ORDER BY t1.no ASC';
	let selectList = [];
	
	connection.execute(sql_selectQuestion, (err, rows) => {
		if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else {
			selectList = rows;
			res.render('adminQuestion', {selectList: selectList});
		}
	});
});

router.get('/questionAnswer/:page/', isAdminLoggedIn, function(req, res) {
	const questionAnswerSql = 'SELECT t1.no, t1.title, t1.empname, t1.date, t2.stuname FROM QuestionBoard t1, User t2 WHERE t1.stuno = t2.stuno AND t1.empname IS NOT NULL ORDER BY t1.no DESC';
	const page = req.params.page;
	connection.execute(questionAnswerSql, (err, rows) => {
		if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else res.render('adminAnswer', {answerList: rows, page: page, length: rows.length - 1, page_num: 10, check: 'no'});
	});
});

router.get('/questionAnswer/:page/:type/:search', isAdminLoggedIn, function(req, res) {
	var answerSearchSql = '';
	
	let page = req.params.page;
	let type = req.params.type;
	let search = req.params.search;
	
	let check = 'yes';
	
	if(type == 1) { // 제목
		answerSearchSql = "SELECT t1.no, t1.title, t1.empname, t1.date, t2.stuname " +
			"FROM QuestionBoard t1, User t2 " +
			"WHERE t1.stuno = t2.stuno AND t1.empname IS NOT NULL AND title LIKE '%" + search + "%' ORDER BY t1.no DESC";
	}
	else if(type == 2) { // 학생명
		answerSearchSql = "SELECT t1.no, t1.title, t1.empname, t1.date, t2.stuname " +
			"FROM QuestionBoard t1, User t2 " +
			"WHERE t1.stuno = t2.stuno AND t1.empname IS NOT NULL AND stuname LIKE '%" + search + "%' ORDER BY t1.no DESC";
	}
	else if(type == 3) { // 상담사명
		answerSearchSql = "SELECT t1.no, t1.title, t1.empname, t1.date, t2.stuname " +
			"FROM QuestionBoard t1, User t2 " +
			"WHERE t1.stuno = t2.stuno AND t1.empname IS NOT NULL AND empname LIKE '%" + search + "%' ORDER BY t1.no DESC";
	}
	else {
		answerSearchSql = "SELECT t1.no, t1.title, t1.empname, t1.date, t2.stuname " +
			"FROM QuestionBoard t1, User t2 WHERE t1.stuno = t2.stuno AND t1.empname IS NOT NULL ORDER BY t1.no DESC";
		page = 1;
		check = 'no';
	}
	
	connection.execute(answerSearchSql, (err, rows) => {
		if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else {
			if(check == 'yes') res.render('adminAnswer', {answerList: rows, page: page, length: rows.length - 1, page_num: 10, check: 'yes', type: type, search: search});
			else res.render('adminAnswer', {answerList: rows, page: page, length: rows.length - 1, page_num: 10, check: 'no'});
		}
	});
});

router.get('/psychologicalType', isAdminLoggedIn, function(req, res) {
	const psychologicalTypeSql = "SELECT * FROM PsyTestList a WHERE a.use = 'Y'";
	connection.execute(psychologicalTypeSql, (err, rows) => {
		if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else res.render('adminPsychologicalType', {testList: rows});
	});
});

router.post('/psychologicalType/:type', isAdminLoggedIn, function(req, res) {
	let type = parseInt(req.params.type);
	
	if(type == 1) {
		let recvData = req.body.testno;
		let updatePsyTestTypeSql = "UPDATE PsyTestList a SET a.use = 'N' WHERE testno = ?";
		
		connection.execute(updatePsyTestTypeSql, [recvData], (err, rows) => {
			if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			else {
				res.send({check: 'success'});
				logger.form.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${recvData}번 심리검사 유형을 삭제.`);
			}
		});
	}
	else if(type == 2) {
		let recvData = req.body;
		let recvNum = recvData.no;
		let updatePsyTestType = "UPDATE PsyTestList SET testname = '" + recvData.context + "', description = '" + recvData.text + "' WHERE testno = ?";
		
		connection.execute(updatePsyTestType, [recvNum], (err, rows) => {
			if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			else logger.form.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${recvNum}번 심리검사 유형을 수정.`);
		});
	}
	else {
		let recvData = req.body;
		let InsertPsyTestType = "INSERT INTO PsyTestList (testname, description) VALUES ('" + recvData.context + "','" + recvData.text + "')";
		
		connection.execute(InsertPsyTestType, (err, rows) => {
			if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			else {
				res.send({check: 'success'});
				logger.form.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${rows.insertId}번 심리검사 유형을 생성.`);
			}
		});
	}
});

router.get('/answerCheck/:no', isAdminLoggedIn, function(req, res) {
	const selectQuestion = 'SELECT t1.*, t2.stuname, t2.phonenum FROM QuestionBoard t1, User t2 WHERE t1.stuno = t2.stuno AND t1.no = ?';
	
	connection.execute(selectQuestion, [req.params.no], (err, rows) => {
		if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else res.render('adminAnswerCheck', {answerCheckList: rows, answerNo: req.params.no});
	});
});

router.post('/answerCheck/:no', isAdminLoggedIn, function(req, res) {
	var updateAnswer = "UPDATE QuestionBoard SET answer = ?, empname = ?, answerdate = ? WHERE no = ?";
	
	connection.execute(updateAnswer, [req.body.content, req.session.adminInfo.empname, moment().format("YYYYMMDD"), req.params.no], (err, rows) => {
		if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else {
			res.json({check: 'success'});
			logger.question.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${req.params.no}번 문의 답변 수정.`);
		}
	});
});

router.get('/myReservation', isAdminLoggedIn, function(req, res, next) {
	const empid = req.session.adminInfo.empid;
	
	const sql_findNotFinishedMyReservation ="SELECT User.stuname as stuname, User.phonenum as phonenum, " +
		  "reserv.serialno as no, reserv.starttime as starttime, reserv.date as date, " + 
		  "consult.typename as typename, reserv.stuno as stuno " + 
		  "FROM User JOIN Reservation reserv ON User.stuno = reserv.stuno JOIN ConsultType consult ON reserv.typeno = consult.typeno " + 
		  "WHERE finished = 0 and empid = ? and status = 1 ORDER BY no";
	
	connection.execute(sql_findNotFinishedMyReservation, [empid], (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else res.render('adminMyReservation', {myId: empid, myReservation: rows});
	});
});

router.post('/finishedReservation', isAdminLoggedIn, function(req, res, next) {
	const serialno = req.body.serialno;
	const empid = req.session.adminInfo.empid;
	
	const sql_updateFinishReservation = "UPDATE Reservation SET finished = 1 WHERE serialno = ? and empid = ?";
	
	connection.execute(sql_updateFinishReservation, [serialno, empid], (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else {
			SatisfactionPush(serialno);
			res.json({state: 'ok'});
			logger.reservation.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${serialno}번 예약을 종결.`);
		}
	})
});

router.post('/saveQuestion', isAdminLoggedIn, function(req, res, next) {
	const sendData = req.body.sendData;
	const sendNumber = req.body.sendNumber;
	
	const updateQuestion = 'UPDATE QuestionBoard SET empname = ?, answerdate = ?, answer = ? WHERE no = ?';
	
	const selectAnswer = 'SELECT answer FROM QuestionBoard WHERE no = ?';
	
	connection.execute(selectAnswer, [sendNumber], (err, result) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else {
			if(result[0].answer === null){
				connection.execute(updateQuestion, [req.session.adminInfo.empname, moment().format("YYYYMMDD"), sendData, sendNumber], (err, rows) => {
					if(err) {
						logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
						next(err);
					}
					else {
						AnswerPush(sendNumber);
						res.json({state: 'ok'});
						logger.question.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${sendNumber}번 문의 답변 등록.`);
					}
				});
			}
			else res.json({state: 'overlap'});
		}
	});
});

router.get("/board/:type", isAdminLoggedIn, function(req, res, next) {
	const sql_findType = "select no from HomeBoard where no = ?";
	const sql_readBoard = "select * from HomeBoard where no = ?";
	const sql_findFormTypes = "select typename from AskType";
	
	let types = [];
	let type = 0;
	const paramType = decodeURIComponent(req.params.type);
	
	connection.execute(sql_findFormTypes, (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else types=rows;
	});
	
	connection.execute(sql_readBoard, [paramType], (err, rows) => {
		if(err){
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else {
			if(rows.length == 0) next(err);
			else {
				const strType = paramType === '1' ? '공지사항' : '이용안내';
				
				if(rows[0].content === '' || rows[0].content == null) {
					rows[0].content = '';
					res.render('adminEditForm', {result: rows[0].content, type: [paramType, strType], types: types});
				}
				else res.render('adminEditForm', {result: rows[0].content, type: [paramType,strType], types: types});
			}
		}
	})
});

router.post("/saveBoard/:type", isAdminLoggedIn, function(req, res, next) {
	const sendAjax = req.body.sendAjax;
	const paramType = decodeURIComponent(req.params.type);
	const boardType = paramType === 1 ? '공지사항' : '이용안내';
	
	const updateBoard = "update HomeBoard set empid = ?, date = CURDATE(), content = ? where no = ?";
	
	const empId = req.session.adminInfo.empid;
	
	const secureXSSContent = sanitizeHtml(sendAjax, {
		allowedTags: sanitizeHtml.defaults.allowedTags.concat(['img']),
		allowedAttributes: { // 기존 값 a: ['href'], img: ['src']
			a: ['href'],
			img: ['src', 'width', 'height'] 
		}
	});
	
	connection.execute(updateBoard, [empId, secureXSSContent, paramType], (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else {
			res.json({state: 'ok'});
			logger.form.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${boardType}을(를) 수정.`);
		}
	});
});

router.get("/form/:type", isAdminLoggedIn, function(req, res, next) {
    const selectAskType = "select * from AskType where typeno = ?";
	
    const selectAskList = "select *, (select GROUP_CONCAT(choice) from ChoiceList where askno = a.askno order by choiceno) as choice from AskList a where typeno = ? AND a.use = 'Y'";
	
	const paramType = decodeURIComponent(req.params.type);
	
	connection.execute(selectAskType, [paramType], (err1, rows1) => {
		if(err1) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err1}`);
			next(err1);
		}
		else {
			if(rows1.length !== 0) {
				if(paramType === '1' || paramType === '2' || paramType === '3') {
					connection.execute(selectAskList, [paramType], (err2, rows2) => {
						if(err2) {
							logger.error.info(`[${moment().format(logTimeFormat)}] ${err2}`);
							next(err2);
						}
						else res.render('adminSimpleApplyForm', {type: rows1[0], result: rows2});
					});
				}
			}
		}
	});
});

router.post('/saveForm/:type', isAdminLoggedIn, function(req, res, next) {
	
    const saveData = JSON.parse(req.body.saveData);
	
	const paramType = parseInt(req.params.type);
	
	const selectAskList = "SELECT askno FROM AskList WHERE askno = ?";
	
	const insertAskList = "INSERT INTO AskList(typeno, choicetypeno, ask, AskList.use) VALUES(?, ?, ?, 'Y')";
	
	const deleteChoiceList = "DELETE FROM ChoiceList WHERE askno = ?";
	
	const insertChoiceList = "INSERT INTO ChoiceList(askno, typeno, choice) VALUES ?";
	
	let type_name = "";
	
	if(paramType === 1) type_name = "상담예약";
	else if(paramType === 2) type_name = "심리검사";
	else if(paramType === 3) type_name = "만족도조사";
	
	saveData.forEach(function(value, index) {
		let values = [];
		
		const askno = parseInt(value.id.split('card_id_')[1]);
		
		connection.execute(selectAskList, [askno], (err1, result1) => {
			if(err1) {
				logger.error.info(`1[${moment().format(logTimeFormat)}] ${err1}`);
				next(err1);
			}
			else {
				if(result1.length === 0) {
					connection.execute(insertAskList, [paramType, parseInt(value.type), value.question], (err2, result2) => {
						if(err2) {
							logger.error.info(`2[${moment().format(logTimeFormat)}] ${err2}`);
							next(err2);
						}
						else {
							if(parseInt(value.type) !== 3) {
								value.choices.forEach(val => {
									values.push([result2.insertId, paramType, val]);
								});
								
								connection.query(insertChoiceList, [values], (err3) => {
									if(err3) {
										logger.error.info(`3[${moment().format(logTimeFormat)}] ${err3}`);
										next(err3);
									}
									else if(index === saveData.length - 1) {
										res.json({state: 'ok'});
										logger.form.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${type_name} 질문을 수정.`);
									}
								});
							}
							else if(parseInt(value.type) === 3 && index === saveData.length - 1) {
								res.json({state: 'ok'});
								logger.form.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${type_name} 질문을 수정.`);
							}
						}
					});
				}
				else { // 중복
					if(parseInt(value.type) !== 3) {
						connection.execute(deleteChoiceList, [result1[0].askno], (err2) => {
							if(err2) {
								logger.error.info(`4[${moment().format(logTimeFormat)}] ${err2}`);
								next(err2);
							}
							else {
								value.choices.forEach(val => {
									values.push([result1[0].askno, paramType, val]);
								});
								
								connection.query(insertChoiceList, [values], (err3) => {
									if(err3) {
										logger.error.info(`5[${moment().format(logTimeFormat)}] ${err3}`);
										next(err3);
									}
									else if(index === saveData.length - 1) {
										res.json({state: 'ok'});
										logger.form.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${type_name} 질문을 수정.`);
									}
								});
							}
						});
					}
					else if(parseInt(value.type) === 3 && index === saveData.length - 1) {
						res.json({state: 'ok'});
						logger.form.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${type_name} 질문을 수정.`);
					}
				}
			}
		});
	});
});

router.post('/noUseAsk', isAdminLoggedIn, function(req, res, next) {
	let askno = req.body.askno;
	let type_name = req.body.typename;
    const updateAskListUse = "UPDATE AskList SET AskList.use = 'N' WHERE askno = ?";
	
    connection.execute(updateAskListUse, [askno], (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else logger.form.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${askno}번 ${type_name} 질문을 삭제.`);
	});
});

router.get('/recovery/:id', isAccessDenied, function(req, res, next) {
	const updateAccountUse = "update Counselor set Counselor.use = 'Y' where empid = ? and Counselor.use = 'N'";
	
	connection.execute(updateAccountUse, [req.params.id], (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else res.send("<script>alert('정상적으로 복구되었습니다.'); window.location.href = '/admin/signUp';</script>");
	});
});

router.get('/signUp', isAccessDenied, function(req, res, next) {
	res.render('adminSignUp');
});

router.post('/signUp', isAccessDenied, (req, res, next) => {
	const sql_addCounselor = "insert into Counselor(empid,emppwd,empname,positionno) values(?, ?, ?, ?)";
	const sql_checkEmpId = "select empid, Counselor.use isUse from Counselor where empid = ?";
	
	const empId = req.body.id.trim();
	const empPwd = req.body.password.trim();
	const isEmp = req.body.isEmp ? true : false;
	const empName = req.body.name.trim();
	
	connection.execute(sql_checkEmpId, [empId], (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else{
			if(rows.length === 0) {
				bcrypt.hash(empPwd, 12, function(err, hashPwd) {
					if(err) {
						logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
						next(err);
					}
					else {
						if(isEmp) {
							connection.execute(sql_addCounselor, [empId, hashPwd, empName, 1], (err, rows) => {
								if(err) {
									logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
									next(err);
								}
							});
							res.redirect('/admin');
						}
						else {
							connection.execute(sql_addCounselor, [empId, hashPwd, empName, 2], (err, rows) => {
								if(err) {
									logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
									next(err);
								}
							});
							res.redirect('/admin');
						}
					}
				});
				logger.account.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${empName}(${empId})님을 등록.`);
			}
			else {
				if(rows[0].isUse === 'Y') res.send("<script>alert('이미 존재하는 아이디입니다.'); window.location.href = '/admin/signUp';</script>");
				else {
					res.send(`
						<script>
							let isRecovery = confirm("삭제된 계정입니다, 복구하시겠습니까?");
							if(isRecovery == true) {
							  window.location.href = '/admin/recovery/${empId}';
							}
							else if(isRecovery == false) {
							  window.location.href = '/admin/signUp';
							}
						</script>
					`);
				}
			}
		}
	});
});

router.get('/selfCheckForm', isAdminLoggedIn, (req, res, next) => {
	const selectSelfCheckList = "SELECT * FROM SelfCheckList WHERE SelfCheckList.use = 'Y'";
	
	connection.execute(selectSelfCheckList, (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else res.render('adminSelfCheckForm', {result: rows});
	});
});

router.post('/noUseSelfCheck', isAdminLoggedIn, (req, res, next) => {
	let checkno = req.body.checkno;
	const updateSelfCheckListUse = "UPDATE SelfCheckList SET SelfCheckList.use = 'N' WHERE checkno = ?";
	
	connection.execute(updateSelfCheckListUse, [checkno], (err) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else logger.form.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${checkno}번 자가진단 질문을 삭제.`);
	});
});

router.post('/saveSelfCheckList', isAdminLoggedIn, (req, res, next) => {
	const saveData = JSON.parse(req.body.saveData);
	
	const insertSelfCheckList = "INSERT INTO SelfCheckList(checkname) VALUES ?";
	
	let values = [];
	
	saveData.forEach(value => {
		if(value !== "") values.push([value]);
	});
		
	if(values.length === 0) res.json({state: 'ok'});
	else {
		connection.query(insertSelfCheckList, [values], (err) => {
			if(err) {
				logger.error.info(`5[${moment().format(logTimeFormat)}] ${err}`);
				next(err);
			}
			else {
				res.json({state: 'ok'});
				logger.form.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 자가진단 질문을 수정.`);
			}
		});
	}
});

router.post('/updateCounselor', isAccessDenied, (req, res, next) => {
	const updateId = req.body.empid;
	const updateName = req.body.updateEmpName;
	const updatePosition = req.body.position;
	
	const sql_updateCounselor = "update Counselor set empname = ?, positionno = ? where empid = ?";
	
	connection.execute(sql_updateCounselor, [updateName, updatePosition, updateId], (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else {
			res.send("<script>window.location.href = '/admin/settings';</script>");
			logger.account.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${updateName}(${updateId})님을 수정.`);
		}
	});
});

router.post('/deleteCounselor', isAccessDenied, (req, res, next) => {
	const delEmpId = req.body.deleteId;
	const delEmpName = req.body.deleteName;
	
	const updateAccountUse = "update Counselor set Counselor.use = 'N' where empid = ?";
	
	connection.execute(updateAccountUse, [delEmpId], (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else {
			res.json('ok');
			logger.account.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${delEmpName}(${delEmpId})님을 삭제.`);
		}
	});
});

router.get('/changePassword', isAdminLoggedIn, (req, res, next) => {
	res.render('adminChangePwd');
});

router.post('/updatePassword', isAdminLoggedIn, (req, res, next) => {
	const sql_checkPassword = "select emppwd from Counselor where empid = ?";
	const sql_updatePassword = "update Counselor set emppwd = ? where empid = ?";
	
	const empid = req.session.adminInfo.empid;
	const empCurrentPwd = req.body.currentPw.trim();
	const empUpdatePwd = req.body.updatePw.trim();
	
	connection.execute(sql_checkPassword, [empid], (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else {
			bcrypt.compare(empCurrentPwd, rows[0].emppwd).then(function(result) {
				if(result){
					bcrypt.hash(empUpdatePwd, 12, function(err, hashPwd) {
						if(err) {
							logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
							next(err);
						}
						else {
							connection.execute(sql_updatePassword, [hashPwd, empid], (err, rows) => {
								if(err) {
									logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
									next(err);
								}
							});
							res.send("<script>alert('패스워드가 정상적으로 변경되었습니다. \n재 로그인을 부탁드립니다.'); window.location.href = '/admin/logout';</script>");
						}
					});
				}
				else res.send("<script>alert('현재 패스워드가 일치하지 않습니다.'); window.location.href = '/admin/changePassword';</script>");
			});
		}
	});
});

router.post('/updateReservation', isAdminLoggedIn, (req, res, next) => {
	let updateNo = req.body.serialno;
	let updateType = req.body.type;
	let updateDate = req.body.date;
	let updateTime = req.body.time;
	
	const updateReservation = "UPDATE Reservation SET typeno = ?, date = ?, starttime = ? WHERE serialno = ?";
	
	connection.execute(updateReservation, [updateType, updateDate, updateTime, updateNo], (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else {
			res.json('success');
			logger.reservation.info(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empname}(${req.session.adminInfo.empid})님이 ${updateNo}번 예약을 수정.`);
		}
	});
});

router.get('/getMyReservationHistory', isAdminLoggedIn, (req, res, next) => {
	if(req.session.fileSave === 'yes') req.session.fileSave = 'no';
	else {
		res.send("<script>alert('잘못된 접근입니다.'); history.back();</script>");
		return;
	}
	
	let empid = req.session.adminInfo.empid;
	
	const workbook = new excel.Workbook();
	const PsyTestWorksheet = workbook.addWorksheet("심리검사 내역");
	const ReservationWorksheet = workbook.addWorksheet("상담 내역");
	
	const sql_selectPsyTestLog="SELECT simple.stuno, simple.stuname, user.major, simple.gender, simple.birth, simple.email, simple.date, GROUP_CONCAT(psyTList.testname) AS testname " + 
		  "FROM SimpleApplyForm simple JOIN PsyTest psyT ON simple.serialno = psyT.serialno JOIN PsyTestList psyTList ON psyT.testno = psyTList.testno " + 
		  "JOIN User user ON simple.stuno = user.stuno GROUP BY simple.serialno ORDER BY simple.date;";
	
	const sql_selectReservationLog="SELECT simple.date, reserv.stuno, simple.stuname, simple.gender, user.major, user.email, " +
		  "simple.birth, contype.typename, Counselor.empname, reserv.date AS reservdate, reserv.starttime, reserv.finished " +
		  "FROM Reservation reserv JOIN SimpleApplyForm simple ON reserv.serialno = simple.serialno JOIN ConsultType contype " +
		  "ON reserv.typeno = contype.typeno JOIN User user ON reserv.stuno = user.stuno, Counselor " +
		  "WHERE NOT reserv.typeno IS NULL AND reserv.status = 1 AND Counselor.empid = reserv.empid AND reserv.empid = ? ORDER BY simple.date, reservdate, reserv.starttime;";
	
	const fileName=`유한대학교 학생상담센터 내 예약 내역.xlsx`;
	
	PsyTestWorksheet.columns = [
		{header: '신청 날짜', key: 'date', width: 15},
		{header: '학번', key: 'stuno', width: 15},
		{header: '학과', key: 'major', width : 20},
		{header: '학생', key: 'stuname', width: 10},
		{header: '성별', key: 'gender', width: 5},
		{header: '생년월일', key: 'birth', width: 15},
		{header: '이메일', key: 'email', width: 20},
		{header: '심리검사 목록', key: 'testname', width: 30}
	];
	
	ReservationWorksheet.columns = [
		{header: '신청 날짜', key: 'date', width: 15},
		{header: '학번', key: 'stuno', width: 15},
		{header: '학과', key: 'major', width : 20},
		{header: '학생', key: 'stuname', width: 10},
		{header: '성별', key: 'gender', width: 5},
		{header: '생년월일', key: 'birth', width: 15},
		{header: '이메일', key: 'email', width: 20},
		{header: '예약일', key: "reservdate", width: 15},
		{header: '예약시간', key: "starttime", width: 10},
		{header: '상담사', key: "empname", width: 10},
		{header: '유형', key: "typename", width: 10},
		{header: '상담 완료 여부', key: 'finished', width: 15},
	];
	
	let rangeColumn1 = ['A1','B1','C1','D1','E1','F1','G1','H1'];
	
	rangeColumn1.forEach((item, index) => {
		PsyTestWorksheet.getCell(item).fill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb:  'FFFFFF00'}
		};
	});
	
	let rangeColumn2 = ['A1','B1','C1','D1','E1','F1','G1','H1','I1','J1','K1','L1'];
	
	rangeColumn2.forEach((item, index) => {
		ReservationWorksheet.getCell(item).fill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb:  'FFFFFF00'}
		};
	});

	connection.execute(sql_selectReservationLog, [empid], (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
			ReservationWorksheet.addRows(rows);
		}
		else{
			if(rows.length !== 0) {
				rows.forEach((row, index) => {
					if(row.finished === 1) row.finished = "완료";
					else row.finished = "미완료";
				});
			}
			
			ReservationWorksheet.addRows(rows);
			
			connection.execute(sql_selectPsyTestLog, (err, rows) => {
				if(err) {
					logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
					next(err);
				}
				else {
					PsyTestWorksheet.addRows(rows);
					workbook.xlsx.writeFile(fileName).then(() => {
						res.download(path.join(__dirname, "/../" + fileName), fileName, function(err) {
							if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
							else {
								fs.unlink(fileName, function() {
									
								});
							}
						});
					});
				}
			});
		}
	});
});

router.get('/getSatisfactionResult', isAdminLoggedIn, (req, res, next) => {
	if(req.session.fileSave === 'yes') req.session.fileSave = 'no';
	else {
		res.send("<script>alert('잘못된 접근입니다.'); history.back();</script>");
		return;
	}
	
	const workbook = new excel.Workbook();
	const satisfactionWorkSheet = workbook.addWorksheet("만족도조사 결과");
	
	const sql_getSatisfationResult = "SELECT Reservation.stuno, Counselor.empname, SimpleApplyForm.stuname, " +
		  "SimpleApplyForm.gender, SimpleApplyForm.birth, SimpleApplyForm.email, " +
		  "User.major, Reservation.date, DATE(Reservation.researchdatetime) AS researchdatetime, ConsultType.typename, " +
		  "Reservation.serialno, Reservation.starttime, AskList.ask, AnswerLog.choiceanswer " + 
		  "FROM Reservation JOIN SimpleApplyForm ON Reservation.serialno = SimpleApplyForm.serialno LEFT JOIN ConsultType ON " + 
		  "Reservation.typeno = ConsultType.typeno LEFT JOIN Counselor ON " + 
		  "Reservation.empid = Counselor.empid JOIN AnswerLog ON Reservation.serialno = AnswerLog.serialno JOIN AskList ON AnswerLog.askno = AskList.askno " + 
		  "JOIN User ON Reservation.stuno = User.stuno " + 
		  "WHERE AskList.typeno = 3 GROUP BY Reservation.stuno, Counselor.empname, SimpleApplyForm.stuname, SimpleApplyForm.birth, SimpleApplyForm.email, Reservation.date, " + 
		  "ConsultType.typename, AnswerLog.serialno, AskList.ask ORDER BY Reservation.researchdatetime, Reservation.date, Reservation.starttime;";
	

	const fileName = `유한대학교 학생상담센터 만족도조사 내역.xlsx`;
	satisfactionWorkSheet.columns = [
		{header: '작성일', key: "researchdatetime", width: 20},
		{header: '학번', key: "stuno", width: 15},
		{header: '학과', key: "major", width: 20},
		{header: '학생', key: "stuname", width: 10},
		{header: '성별', key: 'gender', width: 5},
		{header: '생년월일', key: "birth", width: 15},
		{header: '이메일', key: "email", width: 20},
		{header: '예약일', key: "date", width: 15},
		{header: '예약시간', key: "starttime", width: 10},
		{header: '상담사', key: "empname", width: 10},
		{header: '유형', key: "typename", width: 10},
		{header: '질문', key: "ask", width: 25},
		{header: '답변', key: "choiceanswer", width: 25}
	];
	
	let rangeColumn = ['A1','B1','C1','D1','E1','F1','G1','H1','I1','J1','K1','L1','M1'];
	
	rangeColumn.forEach((item, index) => {
		satisfactionWorkSheet.getCell(item).fill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb:  'FFFFFF00'}
		};
	});
	
	connection.execute(sql_getSatisfationResult, (err, rows) => {
		if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
		else{
			if(rows.length === 0) res.send("<script>alert('접수된 내역이 없습니다.'); window.location.href = '/admin/';</script>");
			else {
				let oldSerialno = 0;
				
				rows.forEach((row, index) => {
					if(oldSerialno !== row.serialno) {
						if(row.typename === null){
							row.typename = "심리검사";
							row.date = "-";
						}
						
						oldSerialno = row.serialno;
						delete row.serialno;
						
						satisfactionWorkSheet.addRow(row);
					}
					else {
						row.researchdatetime = "";
						row.stuno = "";
						row.major = "";
						row.empname = "";
						row.stuname = "";
						row.birth = "";
						row.email = "";
						row.date = "";
						row.typename = "";
						
						delete row.serialno;
						
						satisfactionWorkSheet.addRow(row);
					}
				});
				
				workbook.xlsx.writeFile(fileName).then(() => {
					res.download(path.join(__dirname, "/../" + fileName), fileName, function(err) {
						if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
						else {
							fs.unlink(fileName, function() {
								
							});
						}
					});
				});
			}
		}
	});
});

router.get('/getAllReservationHistory', isAdminLoggedIn, (req, res, next) => {
	if(req.session.fileSave === 'yes') req.session.fileSave = 'no';
	else {
		res.send("<script>alert('잘못된 접근입니다.'); history.back();</script>");
		return;
	}
	
	let empid = req.session.adminInfo.empid;
	
	const workbook = new excel.Workbook();
	const PsyTestWorksheet = workbook.addWorksheet("심리검사 내역");
	const ReservationWorksheet = workbook.addWorksheet("상담 내역");

	const sql_selectPsyTestLog="SELECT simple.stuno, simple.stuname, user.major, simple.gender, simple.birth, simple.email, simple.date, GROUP_CONCAT(psyTList.testname) AS testname " + 
		  "FROM SimpleApplyForm simple JOIN PsyTest psyT ON simple.serialno = psyT.serialno JOIN PsyTestList psyTList ON psyT.testno = psyTList.testno " + 
		  "JOIN User user ON simple.stuno = user.stuno GROUP BY simple.serialno ORDER BY simple.date;";
	
	const sql_selectReservationLog="SELECT simple.date, reserv.stuno, simple.stuname, simple.gender, user.major, user.email, " +
		  "simple.birth, contype.typename, Counselor.empname, reserv.date AS reservdate, reserv.starttime, reserv.finished " +
		  "FROM Reservation reserv JOIN SimpleApplyForm simple ON reserv.serialno = simple.serialno JOIN ConsultType contype " +
		  "ON reserv.typeno = contype.typeno JOIN User user ON reserv.stuno = user.stuno, Counselor " +
		  "WHERE NOT reserv.typeno IS NULL AND reserv.status = 1 AND Counselor.empid = reserv.empid ORDER BY simple.date, reservdate, reserv.starttime;";
	
	const fileName=`유한대학교 학생상담센터 전체 예약 내역.xlsx`;
	
	PsyTestWorksheet.columns = [
		{header: '신청 날짜', key: 'date', width: 15},
		{header: '학번', key: 'stuno', width: 15},
		{header: '학과', key: 'major', width : 20},
		{header: '학생', key: 'stuname', width: 10},
		{header: '성별', key: 'gender', width: 5},
		{header: '생년월일', key: 'birth', width: 15},
		{header: '이메일', key: 'email', width: 20},
		{header: '심리검사 목록', key: 'testname', width: 30}
	];
	
	ReservationWorksheet.columns = [
		{header: '신청 날짜', key: 'date', width: 15},
		{header: '학번', key: 'stuno', width: 15},
		{header: '학과', key: 'major', width : 20},
		{header: '학생', key: 'stuname', width: 10},
		{header: '성별', key: 'gender', width: 5},
		{header: '생년월일', key: 'birth', width: 15},
		{header: '이메일', key: 'email', width: 20},
		{header: '예약일', key: "reservdate", width: 15},
		{header: '예약시간', key: "starttime", width: 10},
		{header: '상담사', key: "empname", width: 10},
		{header: '유형', key: "typename", width: 10},
		{header: '상담 완료 여부', key: 'finished', width: 15},
	];
	
	let rangeColumn1 = ['A1','B1','C1','D1','E1','F1','G1','H1'];
	
	rangeColumn1.forEach((item, index) => {
		PsyTestWorksheet.getCell(item).fill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb:  'FFFFFF00'}
		};
	});
	
	let rangeColumn2 = ['A1','B1','C1','D1','E1','F1','G1','H1','I1','J1','K1','L1'];
	
	rangeColumn2.forEach((item, index) => {
		ReservationWorksheet.getCell(item).fill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb:  'FFFFFF00'}
		};
	});

	connection.execute(sql_selectReservationLog, [empid], (err, rows) => {
		if(err){
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else{
			if(rows.length !== 0) {
				rows.forEach((row, index) => {
					if(row.finished === 1) row.finished = "완료";
					else row.finished = "미완료";
				});
			}
			
			ReservationWorksheet.addRows(rows);
			connection.execute(sql_selectPsyTestLog, (err, rows) => {
				if(err) {
					logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
					next(err);
				}
				else {
					PsyTestWorksheet.addRows(rows);
					workbook.xlsx.writeFile(fileName).then(() => {
						res.download(path.join(__dirname, "/../" + fileName), fileName, function(err) {
							if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
							else {
								fs.unlink(fileName, function() {
									
								});
							}
						});
					});
				}
			});
		}
	});
});

router.get('/getAllChatLog', isAccessDenied, (req, res, next) => {
	if(req.session.fileSave === 'yes') req.session.fileSave = 'no';
	else {
		res.send("<script>alert('잘못된 접근입니다.'); history.back();</script>");
		return;
	}
	
	let empid = req.session.adminInfo.empid;
	
	const sql_selectAllChatLog = "SELECT r.stuno, u.stuname, u.major, u.email, s.birth, s.gender, c.chatlog, c.chatdate, cs.empname " +
		  "FROM Reservation r, ConsultLog c, User u, Counselor cs, SimpleApplyForm s " +
		  "WHERE r.serialno = c.serialno AND u.stuno = r.stuno AND r.empid = cs.empid AND s.serialno = r.serialno " +
		  "ORDER BY c.chatdate;";
	
	const workbook = new excel.Workbook();
	const ChatLogWorksheet = workbook.addWorksheet("전체 채팅 내역");
	const fileName = `유한대학교 학생상담센터 전체 채팅 내역.xlsx`;
	
	ChatLogWorksheet.columns = [
		{header: '최종 상담 일자', key: 'chatdate', width: 15},
		{header: '학번', key: 'stuno', width: 15},
		{header: '학과', key: 'major', width: 20},
		{header: '학생', key: 'stuname', width: 10},
		{header: '성별', key: 'gender', width: 5},
		{header: '생년월일', key: "birth", width: 15},
		{header: '이메일', key: "email", width: 20},
		{header: '상담사', key: 'empname', width: 10},
		{header: '내용', key: 'chatlog', width: 80}
	];
	
	let rangeColumn = ['A1','B1','C1','D1','E1','F1','G1','H1','I1'];
	
	rangeColumn.forEach((item, index) => {
		ChatLogWorksheet.getCell(item).fill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb:  'FFFFFF00'}
		};
	});
	
	connection.execute(sql_selectAllChatLog, (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else {
			ChatLogWorksheet.addRows(rows);
			workbook.xlsx.writeFile(fileName).then(() => {
				res.download(path.join(__dirname, "/../" + fileName), fileName, function(err) {
					if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`); 
					else {
						fs.unlink(fileName, function() {
							
						});
					}
				});
			});
		}
	});
});

router.get('/getUserChatLog/:serialNo', isAccessDenied, (req, res, next) => {
	let empid = req.session.adminInfo.empid;
	const serialNo = decodeURIComponent(req.params.serialNo);
	const stuName = req.query.name;
	const stuNo = req.query.code;
	
	const sql_selectAllChatLog="select * from ConsultLog where serialno = ?";
	
	const workbook = new excel.Workbook();
	const ChatLogWorksheet = workbook.addWorksheet("채팅내역");
	const fileName = `${stuName}(${stuNo})_${moment().format('YYYYMMDD')}_채팅내역.xlsx`;
	
	ChatLogWorksheet.columns = [
		{header: `내용`, key: 'chatlog', width: 80},
	];
	
	let rangeColumn = ['A1'];
	
	rangeColumn.forEach((item, index) => {
		ChatLogWorksheet.getCell(item).fill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb:  'FFFFFF00'}
		};
	});
	
	connection.execute(sql_selectAllChatLog, [serialNo], (err, rows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else {
			ChatLogWorksheet.addRows(rows);
			workbook.xlsx.writeFile(fileName).then(() => {
				res.download(path.join(__dirname, "/../" + fileName), fileName, function(err) {
					if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
					else {
						fs.unlink(fileName, function() {
							
						});
					}
				});
			});
		}
	});
});

router.get('/getSimpleApplyFormPDF/:serialNo', isAdminLoggedIn, (req, res, next) => {
	if(req.session.fileSave === 'yes') req.session.fileSave = 'no';
	else {
		res.send("<script>alert('잘못된 접근입니다.'); history.back();</script>");
		return;
	}
	
	const serialNo = decodeURIComponent(req.params.serialNo);
	
	const sql_selectConsultApply = "SELECT a.serialno, a.stuno, User.major, a.stuname, User.phonenum, a.gender, a.birth, a.email, a.date, " +
				  "GROUP_CONCAT(b.ask SEPARATOR '|') AS 'asks', " +
				  "GROUP_CONCAT(c.choiceanswer SEPARATOR '|') AS 'answers', " +
				  "selfcheck.checknames, selfcheck.scores " +
				  "FROM SimpleApplyForm a, AskList b, AnswerLog c, User,  " +
				  "(SELECT GROUP_CONCAT(list.checkname SEPARATOR '|') AS 'checknames', " +
				  "GROUP_CONCAT(self.score SEPARATOR '|') AS 'scores' " +
				  "FROM SelfCheckList list, SelfCheck self " +
				  "WHERE self.serialno = ? and self.checkno = list.checkno) selfcheck " +
				  "WHERE a.serialno = ? and a.serialno = c.serialno and c.askno = b.askno and User.stuno = a.stuno";
	
	const sql_getApplyType = "SELECT Reservation.serialno, ConsultType.typename FROM Reservation LEFT JOIN ConsultType ON Reservation.typeno = ConsultType.typeno WHERE Reservation.serialno = ?";
	
	const sql_getPsyList = "SELECT GROUP_CONCAT(PsyTestList.testname SEPARATOR ', ') AS testnames FROM PsyTest JOIN PsyTestList ON PsyTest.testno = PsyTestList.testno WHERE PsyTest.serialno = ?";
	
	
	connection.execute(sql_getApplyType, [serialNo], (err, typeRows) => {
		if(err) {
			logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			next(err);
		}
		else {
			let applyType = typeRows[0].typename === null ? "심리검사" :  typeRows[0].typename;
			
			connection.execute(sql_getPsyList, [serialNo], (err, psyRows) => {
				if(err) {
					logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
					next(err);
				}
				else {
					connection.execute(sql_selectConsultApply, [serialNo, serialNo], (err, ConsultRows) => {
						if(err) {
							logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
							next(err);
						}
						else {
							let asks = ConsultRows[0].asks === null ? [] : ConsultRows[0].asks.split("|");
							let answers = ConsultRows[0].answers === null ? [] : ConsultRows[0].answers.split("|");
							let checknames = ConsultRows[0].checknames === null ? [] : ConsultRows[0].checknames.split("|");
							let scores = ConsultRows[0].scores === null ? [] : ConsultRows[0].scores.split("|");
							
							for(let i = 0; i < scores.length; i++) {
								switch (parseInt(scores[i])) {
									case 1 :
										scores[i] = "매우 나쁨";
										break;
									case 2 :
										scores[i] = "나쁨";
										break;
									case 3 :
										scores[i] = "보통";
										break;
									case 4 :
										scores[i] = "좋음";
										break;
									case 5 :
										scores[i] = "매우 좋음";
										break;
									default:
										break;
								}
							}

							let fileName = `${ConsultRows[0].serialno}.pdf`;
							
							const doc = new pdfDocument({compress: false});
							
							let pdfFile = path.join(__dirname, `/../${ConsultRows[0].serialno}.pdf`);
							var pdfStream = fs.createWriteStream(pdfFile);
							
							doc.font(path.join(__dirname, '/../public/res/font/NANUMGOTHIC.TTF'));

							doc
								.fontSize(20)
								.text('간단 신청서', {align: 'center'}) // x, y 좌표
								.moveDown(1.5);

							doc.moveTo(70,110)
								.lineTo(540,110)
								.stroke();

							doc
								.fontSize(12)
								.text(`신청 일자: ${ConsultRows[0].date}`, {align: 'right'})
								.moveDown(0.8);
							
							doc
								.fontSize(12)
								.text(`상담 유형: ${applyType}`, {align: 'right'})
								.moveDown(2);

							doc
								.fontSize(15)
								.text('인적사항', {align: 'left'})
								.moveDown(0.8);

							doc
								.fontSize(10)
								.text(`학번: ${ConsultRows[0].stuno}`, {align: 'left'})
								.moveDown(0.5);
							doc
								.fontSize(10)
								.text(`학과: ${ConsultRows[0].major}`, {align: 'left'})
								.moveDown(0.5);

							doc
								.fontSize(10)
								.text(`이름: ${ConsultRows[0].stuname}`, {align: 'left'})
								.moveDown(0.5);
							doc
								.fontSize(10)
								.text(`성별: ${ConsultRows[0].gender}`, {align: 'left'})
								.moveDown(0.5);
							doc
								.fontSize(10)
								.text(`생년월일: ${ConsultRows[0].birth}`, {align: 'left'})
								.moveDown(0.5);
							doc
								.fontSize(10)
								.text(`휴대폰 번호: ${ConsultRows[0].phonenum}`, {align: 'left'})
								.moveDown(0.5);

							doc
								.fontSize(10)
								.text(`이메일 주소: ${ConsultRows[0].email}`, {align : 'left'})
								.moveDown(2);

							asks.forEach(function (v, i) {
								doc
									.fontSize(10)
									.text(`질문. ${asks[i]}`, {align: 'left'})
									.moveDown(0.5);

								doc
									.fontSize(8)
									.text(answers[i], {align: 'left'})
									.moveDown();

								if(i === asks.length - 1) doc.moveDown(2);
							});

							if(applyType == "심리검사") {
								doc
									.fontSize(15)
									.text('신청 심리검사', {align: 'left'})
									.moveDown(0.5);
								
								doc
									.fontSize(10)
									.text(psyRows[0].testnames, {align: 'left'})
									.moveDown(0.5);
							}
							else {
								doc
									.fontSize(15)
									.text('자가진단 질문', {align: 'left'})
									.moveDown(0.8);
							}

							checknames.forEach(function(v, i) {
								doc
									.fontSize(10)
									.text(`질문. ${checknames[i]}`, {align: 'left'})
									.moveDown(0.5);

								doc
									.fontSize(8)
									.text(scores[i], {align: 'left'})
									.moveDown();

								if(i === checknames.length - 1) doc.moveDown(2);
							});

							doc.pipe(pdfStream);
							doc.end();
							
							let pdfFileName = `${ConsultRows[0].stuname}(${ConsultRows[0].stuno})_${moment(ConsultRows[0].date).format('YYYYMMDD')}_간단 신청서.pdf`;
							
							pdfStream.addListener('finish', function() {
								res.download(pdfFile, pdfFileName, function(err) {
									if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
									else {
										fs.unlink(pdfFile, function() {
											
										});
									}
								});
							});
						}
					});
				}
			});
		}
	});
});

module.exports = router;