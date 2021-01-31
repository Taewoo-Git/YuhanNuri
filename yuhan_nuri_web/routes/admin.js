const express = require('express');
const router = express.Router();

const db = require('../public/res/js/database.js')();
const connection = db.init();
db.open(connection, "admin");

const sanitizeHtml=require('sanitize-html');
const bcrypt=require('bcrypt');

const fs = require('fs');
const path = require('path');
const multer = require('multer');

const schedule = require('node-schedule');
const pdfDocument = require('pdfkit');

const {reservationAcceptPush,answerPush,satisfactionPush} = require('./fcm'); 
const {isAllAdminLoggedIn,isOnlyAdminLoggedIn} = require('./middlewares');  

const excel = require('exceljs');

const moment = require("moment");
require('moment-timezone'); 
moment.tz.setDefault("Asia/Seoul");

let deleteRule = new schedule.RecurrenceRule();
deleteRule.dayOfWeek = [0, new schedule.Range(0,6)];
deleteRule.hour= 00;
deleteRule.minute= 00;

const logger = require('../public/res/js/logger.js');
const logTimeFormat = "YYYY-MM-DD HH:mm:ss";

router.use(function(req, res, next) {
     res.locals.adminInfo = req.session.adminInfo;
     next();
});

try{
	// upload 폴더가 없을 경우 생성
	fs.readdirSync('uploads');
} catch (error) {
	fs.mkdirSync('uploads');
}
const upload = multer({
	storage: multer.diskStorage({
		destination(req, file, cb) {
			cb(null,'uploads/');
		},
		filename(req,file,cb) {
			const ext = path.extname(file.originalname);
			cb(null,path.basename(file.originalname,ext) + Date.now() + ext);
		},
	}),
	limits: {fileSize : 5 * 1024 * 1024}, // 5MB
})

router.get("/",isAllAdminLoggedIn,function(req,res,next){ //GET /admin
	const getReservationData = "SELECT User.stuname as stuname, User.phonenum as phonenum, reserv.serialno as no, " +
		  "reserv.stuno as stuno, consult.typename as typename, reserv.starttime as starttime, reserv.date as date " +  
		  "FROM User JOIN Reservation reserv ON User.stuno = reserv.stuno LEFT JOIN ConsultType consult ON reserv.typeno = consult.typeno " +
		  "WHERE reserv.status = 0 AND (reserv.empid = ? OR reserv.empid IS NULL) ORDER BY no;";
	
	const getReservationData_forWorkstu = "SELECT User.stuname as stuname, User.phonenum as phonenum, reserv.serialno as no, " +
		  "reserv.stuno as stuno, consult.typename as typename, reserv.starttime as starttime, reserv.date as date " +  
		  "FROM User JOIN Reservation reserv ON User.stuno = reserv.stuno LEFT JOIN ConsultType consult ON reserv.typeno = consult.typeno " +
		  "WHERE reserv.status = 0 ORDER BY no;";
	
	let author = req.session.adminInfo.author;
	let empid = req.session.adminInfo.empid;
	
	if(author === 1){
		connection.execute(getReservationData, [empid], (err,rows) => {
		
			if(err) {
				console.error(err);
				next(err);
			}else{
				res.render('admin', {getReservation: rows});	
			}
		});
	}
	else{
		connection.execute(getReservationData_forWorkstu, (err,rows) => {
		
			if(err) {
				console.error(err);
				next(err);
			}else{
				res.render('admin', {getReservation: rows});	
			}
		});
	}
	
});

router.post("/readReservedSchedule", isAllAdminLoggedIn, function(req, res, next){	
	const sql_readReservedSchedule = "SELECT consulttype.typename as typename, user.stuno as stuno, user.stuname as stuname, reserv.date as date, reserv.finished as finished, reserv.empid, " +
		  "reserv.starttime as starttime, reserv.date as date " +
		  "FROM Reservation reserv JOIN User user ON reserv.stuno = user.stuno JOIN ConsultType consulttype ON reserv.typeno = consulttype.typeno " +
		  "WHERE reserv.empid = ? AND reserv.status = 1";
	
	
	const sql_readReservedSchedule_forWorkstu = "SELECT consulttype.typename as typename, user.stuno as stuno, user.stuname as stuname, reserv.date as date, reserv.finished as finished, reserv.empid, " +
		  "reserv.starttime as starttime, reserv.date as date, Counselor.empname as empname " +
		  "FROM Reservation reserv JOIN User user ON reserv.stuno = user.stuno JOIN ConsultType consulttype ON reserv.typeno = consulttype.typeno JOIN Counselor ON reserv.empid = Counselor.empid " +
		  "WHERE reserv.status = 1";
	
	let sql_getReservedSchedule = "";
	
	// 수락이 된 것만 스케줄에 표시가 됨
	const sql_maxIdInSchedule = "SELECT MAX(scheduleno) as maxIdValue FROM Schedule";
	const date_format = "YYYY-MM-DD HH:mm:ss";
	
	let maxid = 0;
	let empid = req.session.adminInfo.empid;
	
	connection.execute(sql_maxIdInSchedule, (err, rows) => {
		if(err) console.error(err);
		else{
			if(rows.length > 0){
				maxid = rows[0].maxIdValue;
			}
			
			if(req.session.adminInfo.author === 1){
				sql_getReservedSchedule = sql_readReservedSchedule;
			}else{
				sql_getReservedSchedule = sql_readReservedSchedule_forWorkstu;
			}
			
			connection.execute(sql_getReservedSchedule, [empid], (err, rows) => {
				if(err) console.error(err);
				else{
					rows.forEach((row, index, arr) => {
						maxid++;
						row.id = '\'' + maxid + '\'';
						if(row.finished === 1){
							row.calendarId = "Finished";
						}else{
							row.calendarId = "Reserved";
						}
						
						if(req.session.adminInfo.author === 1){
							row.title = `${row.starttime}시 ${row.stuname} 학생 ${row.typename}`;
						}
						else{
							row.title = `${row.starttime}시 ${row.stuname} 학생 ${row.typename} - ${row.empname} 선생님`;
						}

						if(row.starttime / 10 >= 1){
							row.start = row.date + "T" + row.starttime + ":00:00";
							row.end = row.date + "T" + (row.starttime + 1) + ":00:00";
						}else{
							row.start = row.date + "T" + "0" + row.starttime + ":00:00";
							row.end = row.date + "T" + (row.starttime + 1) + ":00:00";
						}

					});
					rows = rows.filter(row => row.date != null);

					res.json({reserved : rows});	
				}
			});
			
		}
	});
});

// 관리자 계정에 따라 자신의 스케줄을 가져옴.
router.post("/readMySchedule", isAllAdminLoggedIn,function(req, res, next){
	const sql_readMySchedule = "SELECT scheduleno, Schedule.empid, calendarId, title, category, start, end, location, empname FROM Schedule JOIN Counselor ON" + 
	" Schedule.empid = Counselor.empid WHERE Schedule.empid = ?";
	const sql_readAllCounselorSchedule_forWorkstu = "SELECT scheduleno, Schedule.empid, calendarId, title, category, start, end, location, empname FROM Schedule JOIN Counselor ON Schedule.empid = Counselor.empid";
	
	let empid =  req.session.adminInfo.empid;
	
	if(req.session.adminInfo.author === 2){
		connection.execute(sql_readAllCounselorSchedule_forWorkstu, [empid], (err, rows) => {
			if(rows.length > 0){
				rows.forEach((row, index) => {
					if(row.hasOwnProperty("empname")){
						row.title = row.title + " - " + row.empname + " 선생님";
					}
				});
				res.json({schedules : rows});	
			}
		});
	}else{
		connection.execute(sql_readMySchedule, [empid], (err, rows) => {
			if(rows.length > 0){
				res.json({schedules : rows});	
			}
		});
	}
	
});

// 자신의 스케줄을 변경하는 부분
router.post("/updateSchedule", isAllAdminLoggedIn,function(req, res, next){
	const datetime_format = "YYYY-MM-DD HH:mm:ss";
	let sql_updateSchedule = "UPDATE Schedule SET ";
	let sql_alreadyReserved = "SELECT serialno FROM Reservation WHERE date = (SELECT DATE(start) FROM Schedule WHERE scheduleno = ?)";
	
	let data = JSON.parse(req.body.sendAjax);
	
	let empid = req.session.adminInfo.empid;
		
	connection.execute(sql_alreadyReserved, [data.id], (err, rows) => {
		if(err){
			console.error(err);
			next(err);
		}else{
			if(rows.length > 0){
				res.json({state : "can't update"});
			}else{
				if(data.changes.hasOwnProperty("start")){
					data.changes.start = moment(new Date(data.changes.start._date)).format(datetime_format);
				}
				if(data.changes.hasOwnProperty("end")){
					data.changes.end = moment(new Date(data.changes.end._date)).format(datetime_format);
				}

				let keys = Object.keys(data.changes);
				let values = Object.values(data.changes);
				
				keys.forEach((item, index) => {
					sql_updateSchedule += (item.toString() +  " = ?,");
				});
				
				sql_updateSchedule = sql_updateSchedule.slice(0,-1); // 마지막, 지움

				sql_updateSchedule += ` WHERE scheduleno = ${data.id} AND empid = '${empid}'`;
				
				connection.execute(sql_updateSchedule, values, (err, rows) => {
					if(err){
						console.error(err);
						next(err);
					}else{
						res.json({state : "ok"});
					}
				});	
			}
		}
	});
});

// 스케줄 삭제
router.post("/deleteSchedule",isAllAdminLoggedIn, function(req, res, next){
	let data = JSON.parse(req.body.sendAjax);
	let session_empid = req.session.adminInfo.empid;
	// 예약, 회의, 휴가의 경우 스케줄 삭제가 가능
	// 이외 스케줄 삭제가 불가능, DB에 없는 스케줄 ID 값이기 때문
	
	const sql_isCanDelete = "SELECT * FROM Reservation WHERE date = ? AND empid = ?";
	const sql_deleteSchedule = "DELETE FROM Schedule WHERE scheduleno = ?";
	const sql_isOnSchedule = "SELECT DATE(start) as start FROM Schedule WHERE scheduleno = ?";
	
	connection.execute(sql_isOnSchedule, [data.id], (err, schedule_rows) => {
		if(err) {
			console.error(err);
			next(err);
		}else{
			if(schedule_rows.length > 0) { // 상담사님이 입력한 스케줄이면	
				let reservedStart = schedule_rows[0].start;
				
				// 예약 스케줄에 해당 날짜가 있으면
				connection.execute(sql_isCanDelete, [reservedStart, session_empid], (err, usedSchedule_rows) => {   
					if(err){
						console.error(err);
						next(err);
					}else{
						if(usedSchedule_rows.length > 0){ // 이미 예약이 있는 스케줄이 있을경우
							res.json({state : "can't delete : already Accept"});
						}else{
							connection.execute(sql_deleteSchedule, [data.id], (err) => {
								if(err) {
									console.error(err);
									next(err);
								}else{
									res.json({state : "ok"});
								}
							});
						}
					}
				});
			}
		}
	});
});

// 스케줄을 새로 생성하는 부분
router.post("/createSchedule", isAllAdminLoggedIn,function(req, res, next){
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
	
	if(startIndex != endIndex){
		res.json({state : "isDiffDate"});
	}else{
		
		connection.execute(sql_getAlreadyScheduled, [startIndex, session_empid], (err, row) => {
			if(err){
				console.error(err);
				next(err);
			}else{

				if(row.length > 0){
					for(let time = row[0].start; time <= row[0].end; time++){
						scheduled_hour.push(time); // 이건 기존 스케줄 표에서 가져온 스케줄
					}
					
					let created_start = new Date(start).getHours();
					let created_end = new Date(end).getHours();
					
					// 이건 입력한 스케줄
					for(let time = created_start; time <= created_end; time++){
						createad_hour.push(time);
					}
					
					let isDuplicateArray = createad_hour.filter((item) => scheduled_hour.includes(item));
					
					if(isDuplicateArray.length > 0){
						res.json({state : "Duplicate Schedule"});
					}
					else{
						connection.execute(sql_createSchedule, [empid, data.calendarId, data.title, data.category, start, end, location], (err) => {
							if(err){
								console.error(err);
								next(err);
							}else{
								res.json({state : "ok"});
							}
						});
					}
				}
				else{
					connection.execute(sql_createSchedule, [empid, data.calendarId, data.title, data.category, start, end, location], (err) => {
						if(err){
							console.error(err);
							next(err);
						}else{
							res.json({state : "ok"});
						}
					});
				}
			}
		});
	}
});

router.post("/accessReservation",isAllAdminLoggedIn, function(req,res,next) { //POST /admin/accessReservation
	const setAccessReservationData = "UPDATE Reservation SET status = 1, finished = ?, empid = ? WHERE serialno = ?";
	const isPsyTest = "SELECT typeno FROM Reservation WHERE serialno = ?";
	let serialno = req.body.sendAjax;
	let empid = req.session.adminInfo.empid;
	
	connection.execute(isPsyTest, [serialno], (err, row) => {
		if(err){
			console.error(err);
			next(err);
		}else{
			let psyTestno = 0;
			if(row[0].typeno === null){ // 심리검사이면
				psyTestno = 1;
			}
			connection.execute(setAccessReservationData, [psyTestno, empid, serialno], (err,rows) => {
				if(err) {
					console.error(err);
					next(err);
				}
				else{
					reservationAcceptPush(serialno);
					res.json({getReservation: rows});
				}
			});
		}
	});
});

router.post("/cancelReservation",isAllAdminLoggedIn, function(req,res,next) { //POST /admin/cancelReservation
	const setCancelReservationData = "DELETE FROM Reservation WHERE serialno = ?";
	let serialno = req.body.sendAjax;
	
	connection.execute(setCancelReservationData, [serialno], (err,rows) => {
		if(err) {
			console.error(err);
			next(err);
		}else{
			res.json({state : "ok"});
		}
	});
});

router.post("/getMentalApplyForm", isAllAdminLoggedIn,function(req,res, next) { //POST /admin/getMentalApplyForm
	const query = "SELECT a.serialno, a.stuno, a.stuname, a.gender, a.birth, a.email, a.date, " +
				  "GROUP_CONCAT(b.ask SEPARATOR '|') AS 'asks', GROUP_CONCAT(c.choiceanswer SEPARATOR '|') AS 'answers', " +
				  "(SELECT GROUP_CONCAT(testname) FROM PsyTestList list, " +
				  "(SELECT testno FROM PsyTest WHERE serialno=?) psy WHERE psy.testno = list.testno) AS 'testnames' " +
				  "FROM SimpleApplyForm a, AskList b, AnswerLog c " +
				  "WHERE a.serialno=? and a.serialno=c.serialno and c.askno=b.askno;";
	
	let serialno = req.body.serialno;
	
	connection.execute(query, [serialno, serialno], (err, rows) => {
		if(err) {
			console.error(err);
			next(err);
		}
		else{
			res.json(rows[0]);
		}
	});
});

router.post("/getConsultApplyForm", isAllAdminLoggedIn, function(req,res, next) { //POST /admin/getMentalApplyForm
	const query = "SELECT a.serialno, a.stuno, a.stuname, a.gender, a.birth, a.email, a.date, " +
				  "GROUP_CONCAT(b.ask SEPARATOR '|') AS 'asks', " +
				  "GROUP_CONCAT(c.choiceanswer SEPARATOR '|') AS 'answers', " +
				  "selfcheck.checknames, selfcheck.scores " +
				  "FROM SimpleApplyForm a, AskList b, AnswerLog c, " +
				  "(SELECT GROUP_CONCAT(list.checkname SEPARATOR '|') AS 'checknames', " +
				  "GROUP_CONCAT(self.score SEPARATOR '|') AS 'scores' " +
				  "FROM SelfCheckList list, SelfCheck self " +
				  "WHERE self.serialno=? and self.checkno=list.checkno) selfcheck " +
				  "WHERE a.serialno=? and a.serialno=c.serialno and c.askno=b.askno;";
	
	let serialno = req.body.serialno;
	
	connection.execute(query, [serialno, serialno], (err, rows) => {
		if(err) {
			console.error(err);
			next(err);
		}
		else{
			res.json(rows[0]);
		}
	});
});

router.get("/chat",isOnlyAdminLoggedIn, (req, res,next) => {
	res.render('chattingForm', {
		empid: req.session.adminInfo.empid,
		empname: req.session.adminInfo.empname
	});
});

router.post("/addType",isAllAdminLoggedIn,function(req, res, next){
	// type을 저장하는 부분
	const sql_selectName = "SELECT * FROM FormTypeInfo WHERE typename = ?";
	const sql_creType = "INSERT INTO FormTypeInfo(typename) VALUES(?)";
	const newTypename = req.body.add_type;
	
	connection.execute(sql_selectName, [newTypename], (err, rows) => {
		if(rows.length != 0){
			res.json('used Type');
		}
		else{
			connection.execute(sql_creType, [newTypename], (err) => {
				if(err){
					console.error(err);
					next(err);
				}
				res.json('sucess Create Type');
			});
			
		}
	});
});

router.get("/schedule",isAllAdminLoggedIn,function(req,res,next){ //GET /admin/adminTest
	res.render('adminCalendar');
});

router.get("/settings",isOnlyAdminLoggedIn,function(req,res,next){
	const sql_selectCounselor="select empid,empname,positionno from Counselor where Counselor.use = 'Y'";
	connection.execute(sql_selectCounselor,(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			res.render('adminSetting',{result:rows});
		}
	});
});


router.post('/uploadFile',isAllAdminLoggedIn,upload.single('file'),function(req,res,next){
	res.json({
		"location": "/"+req.file.path.toString(),
	});
});

router.get('/logout',isAllAdminLoggedIn, function(req, res) { //GET /user/logout
    req.session.destroy();
	res.clearCookie('isAutoLogin');
    res.redirect('/');
});

router.get('/question',isAllAdminLoggedIn,function(req,res){
	const sql_selectQuestion='SELECT DISTINCT t1.*, t2.stuname, t2.phonenum FROM QuestionBoard t1, User t2 WHERE t1.stuno = t2.stuno AND  answer IS NULL ORDER BY t1.no ASC;';
	let selectList=[];
	
	connection.execute(sql_selectQuestion,(err,rows)=>{
		if(err){
			console.error(err);
		}else{
			selectList=rows;
			res.render('adminQuestion',{selectList:selectList});
		}
	});
});

router.get('/questionAnswer/:page/',isAllAdminLoggedIn,function(req,res){
	const questionAnswerSql = 'SELECT t1.no, t1.title, t1.empname, t1.date, t2.stuname FROM QuestionBoard t1, User t2 WHERE t1.stuno = t2.stuno AND t1.empname IS NOT NULL;';
	const page = req.params.page;
	connection.execute(questionAnswerSql,(err,rows)=>{
		if(err){
			console.error(err);
		}else{
			res.render('adminAnswer',{answerList:rows, page:page, length:rows.length-1, page_num:10, check:'no'});
		}
	});
});
router.get('/questionAnswer/:page/:type/:search',isAllAdminLoggedIn,function(req,res){
	var answerSearchSql = '';
	let page = req.params.page;
	let type = req.params.type;
	let search = req.params.search;
	let check = 'yes';
	if(type == 1){
		answerSearchSql = "SELECT t1.no, t1.title, t1.empname, t1.date, t2.stuname FROM QuestionBoard t1, User t2 WHERE t1.stuno = t2.stuno AND t1.empname IS NOT NULL AND title LIKE '%"+search+"%'";
	}else if(type == 2){
		answerSearchSql = "SELECT t1.no, t1.title, t1.empname, t1.date, t2.stuname FROM QuestionBoard t1, User t2 WHERE t1.stuno = t2.stuno AND t1.empname IS NOT NULL AND stuname LIKE '%"+search+"%'";
	}else if(type == 3){
		answerSearchSql = "SELECT t1.no, t1.title, t1.empname, t1.date, t2.stuname FROM QuestionBoard t1, User t2 WHERE t1.stuno = t2.stuno AND t1.empname IS NOT NULL AND empname LIKE '%"+search+"%'";
	}else{
		answerSearchSql = "SELECT t1.no, t1.title, t1.empname, t1.date, t2.stuname FROM QuestionBoard t1, User t2 WHERE t1.stuno = t2.stuno AND t1.empname IS NOT NULL;";
		page = 1;
		check = 'no';
	}
	connection.execute(answerSearchSql,(err,rows)=>{
		if(err){
			console.error(err);
		}else{
			if(check == 'yes'){
				res.render('adminAnswer',{answerList:rows, page:page, length:rows.length-1, page_num:10, check:'yes', type:type, search:search});
			}else{
				res.render('adminAnswer',{answerList:rows, page:page, length:rows.length-1, page_num:10, check:'no'});
			}
		}
	});
});
router.get('/psychologicalType',isAllAdminLoggedIn,function(req,res){
	const psychologicalTypeSql = "SELECT * FROM PsyTestList a WHERE a.use = 'Y';";
	connection.execute(psychologicalTypeSql,(err,rows)=>{
		if(err){
			console.error(err);
		}else{
			res.render('adminPsychologicalType',{testList:rows});
		}
	});
});

router.post('/psychologicalType/:type',isAllAdminLoggedIn,function(req,res){
	let type = req.params.type;
	var updateTypeSql;
	var recvData;
	if(type == 1){
		updateTypeSql = "UPDATE PsyTestList a SET a.use = 'N' WHERE testno = ?;";
		recvData = req.body.ajaxData;
		connection.execute(updateTypeSql,[recvData],(err,rows)=>{
			if(err){
				console.error(err);
			}else{
				res.send({check:'success'});
			}
		});
	}else if(type == 2){
		recvData = JSON.parse(req.body.ajaxData);
		updateTypeSql = "UPDATE PsyTestList SET testname = '"+recvData.context+"', description = '"+recvData.text+"' WHERE testno = ?;";
		let recvNo = recvData.no;
		connection.execute(updateTypeSql,[recvNo],(err,rows)=>{
			if(err){
				console.error(err);
			}else{
			}
		});
	}else{
		recvData = JSON.parse(req.body.ajaxData);
		updateTypeSql = "INSERT INTO PsyTestList (testname, description) VALUES ('"+recvData.context+"','"+recvData.text+"')";
		connection.execute(updateTypeSql,(err,rows)=>{
			if(err){
				console.error(err);
			}else{
				res.send({check:'success'});
			}
		});
	}
});

router.get('/answerCheck/:no',isAllAdminLoggedIn,function(req,res){
	const answerCheckSql = 'SELECT t1.*, t2.stuname, t2.phonenum FROM QuestionBoard t1, User t2 WHERE t1.stuno = t2.stuno AND t1.no = ?;';
	const no = req.params.no;
	connection.execute(answerCheckSql,[no],(err,rows)=>{
		if(err){
			console.error(err);
		}else{
			res.render('adminAnswerCheck',{answerCheckList:rows, answerNo:no});
		}
	});
});

router.post('/answerCheck/:no',isAllAdminLoggedIn,function(req,res){
	var updateAnswerSql = "UPDATE QuestionBoard SET answer = ?, empname = ?, answerdate = ? WHERE no = ?;";
	connection.execute(updateAnswerSql,[req.body.content, req.session.adminInfo.empname, moment().format("YYYYMMDD"), req.params.no],(err,rows)=>{
		if(err){
			console.error(err);
		}else{
			res.json({check:'success'});
		}
	});
});

router.get('/myReservation',isAllAdminLoggedIn,function(req,res,next){
	const empid = req.session.adminInfo.empid;
	
	const sql_findNotFinishedMyReservation ="SELECT User.stuname as stuname, User.phonenum as phonenum, reserv.serialno as no, reserv.starttime as starttime, reserv.date as date, " + 
		  "consult.typename as typename, reserv.stuno as stuno " + 
		  "FROM User JOIN Reservation reserv ON User.stuno = reserv.stuno JOIN ConsultType consult ON reserv.typeno = consult.typeno " + 
		  "WHERE finished = 0 and empid = ? and status = 1 ORDER BY no;";
	
	connection.execute(sql_findNotFinishedMyReservation,[empid],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}
		else{
			res.render('adminMyReservation',{myId : empid, myReservation:rows});
		}
	})
});

router.post('/finishedReservation',isAllAdminLoggedIn,function(req,res,next){
	const sendAjax = req.body.sendAjax;
	const empid = req.session.adminInfo.empid;
	
	const sql_updateFinishReservation = "UPDATE Reservation SET finished=1 WHERE serialno = ? and empid = ?";
	
	connection.execute(sql_updateFinishReservation,[sendAjax, empid ],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			satisfactionPush(sendAjax);
			res.json({state:'ok'});
		}
	})
});

router.post('/saveQuestion',isAllAdminLoggedIn,function(req,res,next){
	const sendData=req.body.sendData;
	const sendNumber=req.body.sendNumber;
	const sql_updateAnswer='update QuestionBoard set empname=?,answerdate=?,answer=? where no=?';
	let nowMoment = moment().format("YYYYMMDD");

	connection.execute(sql_updateAnswer,[req.session.adminInfo.empname,nowMoment,sendData,sendNumber],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			answerPush(sendNumber);
			res.json({state:'ok'});
		}
	});
});

router.get("/board/:type",isAllAdminLoggedIn,function(req,res,next){
	const sql_findType="select no from HomeBoard where no = ?";
	const sql_readBoard="select * from HomeBoard where no = ?";
	const sql_findFormTypes="select typename from AskType";
	let types=[];
	let type=0;
	const paramType=decodeURIComponent(req.params.type);
	
	connection.execute(sql_findFormTypes,(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			types=rows;
		}
	})
	connection.execute(sql_readBoard,[paramType],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			if(rows.length==0){
				next(err);
			}else{
				const strType= paramType==='1' ? '공지사항' : '이용안내';
				if(rows[0].content==='' || rows[0].content == null){
					rows[0].content='';
					res.render('editForm',{result:rows[0].content,type:[paramType,strType],types:types});
				}else{
					res.render('editForm',{result:rows[0].content,type:[paramType,strType],types:types});
				}
			}
		}
	})
});

router.post("/saveBoard/:type",isAllAdminLoggedIn,function(req,res,next){
	const sendAjax=req.body.sendAjax;
	const paramType=decodeURIComponent(req.params.type);
	const sql_saveBoard = "update HomeBoard set empid=?,date=CURDATE(),content=? where no=?";
	const empId=req.session.adminInfo.empid;
	const secureXSSContent = sanitizeHtml(sendAjax,{
		allowedTags: sanitizeHtml.defaults.allowedTags.concat(['img']),
		allowedAttributes: { // 기존 기본 값 a : ['href'],img : ['src']
			a: ['href'],
			img:['src', 'width', 'height'] 
		}
	});
	connection.execute(sql_saveBoard,[empId,secureXSSContent,paramType],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			res.json({state:'ok'});
		}
	});
});

router.get("/form/:type",isAllAdminLoggedIn,function(req,res,next){
	const sql_checkMaxAskCount = "select MAX(askno) as maxAskNo from AskList where typeno=?";
    const sql_findFormTypes="select typeno from AskType";
    const sql_checkType = "select * from AskType where typeno=?";
    const sql_findFiveConceptForm = "select ask from AskList where typeno=3";
    const sql_findThreeConceptForm = "select *,(select GROUP_CONCAT(choice) from ChoiceList where askno=a.askno) as choice from AskList a where typeno=? AND a.use = 'Y'";
	let type="";
	let types=[];
	let max=0;
	const paramType=decodeURIComponent(req.params.type);
	
    //상담, 심리는 3문항 / 심리검사 5문항
	connection.execute(sql_checkMaxAskCount,[paramType],(err,rows)=>{
        if(err){
            console.error(err);
            next(err);
        }else{
            max=rows[0].maxAskNo;
        }
    });
    connection.execute(sql_checkType,[paramType],(err,rows)=>{
        if(err){
            console.error(err);
            next(err);
        }
        if(rows.length===0){
            next(err);
        }else{
            type=rows[0];
        }
    });

    if(paramType === '1' || paramType === '2' || paramType==='3'){ //3 문항
        connection.execute(sql_findThreeConceptForm,[paramType],(err,rows)=>{
            if(err){
                console.error(err);
                next(err);
            }
            res.render('simpleApplyForm',{result:rows,type:type,max:max});
        });
    }
});

router.post('/saveForm/:type',isAllAdminLoggedIn,function(req,res,next){ 
    const sendObject = JSON.parse(req.body.sendAjax);
	
	const paramType = req.params.type;
	
	const insertAskList = "INSERT INTO AskList(typeno, choicetypeno, ask) SELECT ?,?,? FROM dual " +
						  "WHERE NOT EXISTS(SELECT * FROM AskList WHERE typeno=? AND ask=? AND AskList.use='Y')";
	
	const insertChoiceList = "INSERT INTO ChoiceList(askno,typeno,choice) VALUES(?, ?, ?)" ;
	
	const selectAskList = "SELECT askno FROM AskList WHERE typeno=? AND ask=? AND AskList.use='Y'";
	
	const selectChoiceList = "SELECT choiceno, choice FROM ChoiceList WHERE askno=? AND typeno=?"
	
	const updateChoiceList = "UPDATE ChoiceList SET choice=? WHERE choice!=? AND choiceno=?";
	
	const deleteChoiceList = "DELETE FROM ChoiceList WHERE askno=? AND choiceno NOT IN (SELECT * FROM (SELECT choiceno FROM ChoiceList WHERE askno=? LIMIT ?) temp)";
		
	if(paramType === '1' || paramType === '2' || paramType==='3'){ 
		sendObject.forEach(function(v, i){
			let tempType = 0;
			
			if(v.type === 'radio'){
				tempType = 1;
			}else if(v.type === 'check'){
				tempType = 2;
			}else if(v.type === 'normal'){
				tempType = 3;
			}
			
			connection.execute(insertAskList,[paramType, tempType, v.question, paramType, v.question],(insertAskListErr, insertAskListRows)=>{
				if(insertAskListErr){
					console.error(insertAskListErr);
					next(insertAskListErr);
				}
				else if(insertAskListRows.insertId === 0){
					connection.execute(selectAskList,[paramType, v.question],(selectAskListErr, selectAskListRows)=>{
						if(selectAskListErr){
							console.error(selectAskListErr);
							next(selectAskListErr);
						}
						else{
							if(v.askList !== undefined){
								v.askList.forEach(function(b, j){
									connection.execute(selectChoiceList,[selectAskListRows[0].askno, paramType],(selectChoiceListErr, selectChoiceListRows)=>{
										if(selectChoiceListErr){
											console.error(selectChoiceListErr);
											next(selectChoiceListErr);
										}
										else if(selectChoiceListRows[j] == undefined){
											connection.execute(insertChoiceList,[selectAskListRows[0].askno, paramType, b.ask],(insertChoiceListErr, insertChoiceListRows)=>{
												if(insertChoiceListErr){
													console.error(insertChoiceListErr);
													next(insertChoiceListErr);
												}
											});
										}
										else{
											connection.execute(updateChoiceList,[b.ask, b.ask, selectChoiceListRows[j].choiceno],(updateChoiceListErr, updateChoiceListRows)=>{
												if(updateChoiceListErr){
													console.error(updateChoiceListErr);
													next(updateChoiceListErr);
												}
											});
										}
									});
								});
								
								connection.execute(deleteChoiceList,[selectAskListRows[0].askno, selectAskListRows[0].askno, v.askList.length],(deleteChoiceListtErr, deleteChoiceListRows)=>{
									if(deleteChoiceListtErr){
										console.error(deleteChoiceListtErr);
										next(deleteChoiceListtErr);
									}
								});
							}
							
							
						}
					});
				}
				else{
					if(v.askList !== undefined){
						v.askList.forEach(function(b, j){
							connection.execute(insertChoiceList,[insertAskListRows.insertId, paramType, b.ask],(insertChoiceListErr, insertChoiceListRows)=>{
								if(insertChoiceListErr){
									console.error(insertChoiceListErr);
									next(insertChoiceListErr);
								}
							});
						});
					}
				}
			});
		});
		res.json({state:'ok'});
	}
});

router.post('/noUseAsk',isAllAdminLoggedIn,function(req,res,next){
	let data = req.body.noUse;
    const sql_noUseAsk = "UPDATE AskList SET AskList.use = 'N' WHERE askno=(SELECT * FROM (SELECT askno FROM AskList WHERE askno=?) temp)";
	
    connection.execute(sql_noUseAsk,[data],(err,rows)=>{
        if(err){
            console.error(err);
            next(err);
        }
    });
});

router.get('/recovery/:id',isOnlyAdminLoggedIn,function(req,res,next){
	const updateAccountUse="update Counselor set Counselor.use = 'Y' where empid=? and Counselor.use = 'N'";
	
	connection.execute(updateAccountUse, [req.params.id], (err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}
		else {
			res.send("<script>alert('정상적으로 복구되었습니다.'); window.location.href = '/admin/signUp';</script>");
		}
	});
});

router.get('/signUp',isOnlyAdminLoggedIn,function(req,res,next){
	res.render('adminSignUp');
});

router.post('/signUp',isOnlyAdminLoggedIn,(req,res,next)=>{
	const sql_addCounselor="insert into Counselor(empid,emppwd,empname,positionno) values(?,?,?,?)";
	const sql_checkEmpId="select empid, Counselor.use isUse from Counselor where empid=?";
	const empId=req.body.id.trim();
	const empPwd=req.body.password.trim();
	const isEmp=req.body.isEmp ? true : false;
	const empName=req.body.name.trim();
	
	connection.execute(sql_checkEmpId,[empId],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			if(rows.length===0){
				bcrypt.hash(empPwd, 12, function(err, hashPwd) {
					if(err){
						console.error(err);
						next(err);
					}else{
						if(isEmp){
							connection.execute(sql_addCounselor,[empId,hashPwd,empName,1],(err,rows)=>{
								if(err){
									console.error(err);
									next(err);
								}
							});
							res.redirect('/admin');
						}else{
							connection.execute(sql_addCounselor,[empId,hashPwd,empName,2],(err,rows)=>{
								if(err){
									console.error(err);
									next(err);
								}
							});
							res.redirect('/admin');
						}
					}
				});
				logger.user(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empid} -> ${empId} 등록.`);
			}else{
				if(rows[0].isUse === 'Y') {
					res.send("<script>alert('이미 존재하는 아이디입니다.'); window.location.href = '/admin/signUp';</script>");
				}
				else {
					res.send(`
						<script>
							let isRecovery = confirm("삭제된 계정입니다, 복구하시겠습니까?");
							if(isRecovery == true){
							  window.location.href = '/admin/recovery/${empId}';
							}
							else if(isRecovery == false){
							  window.location.href = '/admin/signUp';
							}
						</script>
					`);
				}
			}
		}
	});
});

router.get('/selfCheckForm',isAllAdminLoggedIn,(req,res,next)=>{
	const sql_checkMaxSelfCheckCount = "select MAX(checkno) as maxCheckNo from SelfCheckList";
	const sql_selectSelfCheckList="select * from SelfCheckList where SelfCheckList.use='Y'";
	let max=0;
	
	connection.execute(sql_checkMaxSelfCheckCount,(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			if(rows[0].maxCheckNo != null){
				max=rows[0].maxCheckNo;
			}
		}
	});
	
	connection.execute(sql_selectSelfCheckList,(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			res.render('adminSelfCheckForm',{result:rows,max:max});
		}
	});
});

router.post('/noUseSelfCheck',isAllAdminLoggedIn,(req,res,next)=>{
	let data = req.body.noUse;
	const sql_noUseSelfCheck = "update SelfCheckList set SelfCheckList.use = 'N' where checkno = ?";
	
	connection.execute(sql_noUseSelfCheck,[data],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}
	});
});

router.post('/saveSelfCheckList',isAllAdminLoggedIn,(req,res,next)=>{
	const sendObject = JSON.parse(req.body.sendAjax);
	let max = 0;
	const sql_checkMaxSelfCheckCount = "select MAX(checkno) as maxCheckNo from SelfCheckList";
	const sql_insertSelfCheck = "INSERT INTO SelfCheckList(checkname, SelfCheckList.use) SELECT ?, 'Y' FROM DUAL " +
		  						"WHERE NOT EXISTS(SELECT * FROM SelfCheckList WHERE checkname = ? AND SelfCheckList.use='Y')";
	const sql_checkChanged = "SELECT checkname FROM SelfCheckList WHERE checkno = ?";
	const sql_noUseSelfCheck = "UPDATE SelfCheckList SET SelfCheckList.use = 'N' WHERE checkno = ?";
	
	connection.execute(sql_checkMaxSelfCheckCount,(err,rows)=>{
        if(err){
            console.error(err);
            next(err);
        }else{
			if(rows[0].maxCheckNo != null){
				max=rows[0].maxCheckNo;
			}
          	
        }
    });
	
	sendObject.forEach(function(v,i){
		
		// 아예 초기 입력 값이 공백이면 Insert 추가 안함
		if(v.ask == ""){
			return;
		}
		
		connection.execute(sql_insertSelfCheck,[v.ask, v.ask],(err,rows) => { 
			if(err){
				console.error(err);
				next(err);
			}
		});
	});
	
	res.json({state:'ok'});
});

router.post('/updateCounselor',isOnlyAdminLoggedIn,(req,res,next)=>{
	const updateId=req.body.empid;
	const updateName=req.body.updateEmpName;
	const updatePosition=req.body.position;
	const sql_updateCounselor="update Counselor set empname=?,positionno=? where empid=?";
	connection.execute(sql_updateCounselor,[updateName,updatePosition,updateId],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			res.send("<script>window.location.href = '/admin/settings';</script>");
			logger.user(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empid} -> ${updateId} 수정.`);
		}
	});
});

router.post('/deleteCounselor',isOnlyAdminLoggedIn,(req,res,next)=>{
	const delEmpId=req.body.deleteId;
	const updateAccountUse="update Counselor set Counselor.use = 'N' where empid=?";
	connection.execute(updateAccountUse,[delEmpId],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			res.json('ok');
			logger.user(`[${moment().format(logTimeFormat)}] ${req.session.adminInfo.empid} -> ${delEmpId} 삭제.`);
		}
	});
});

router.get('/changePassword',isAllAdminLoggedIn,(req,res,next)=>{
	res.render('adminChangePwd');
});

router.post('/updatePassword',isAllAdminLoggedIn,(req,res,next)=>{
	const sql_checkPassword="select emppwd from Counselor where empid = ?";
	const sql_updatePassword="update Counselor set emppwd = ? where empid = ?";
	const empid = req.session.adminInfo.empid;
	const empCurrentPwd=req.body.currentPw.trim();
	const empUpdatePwd=req.body.updatePw.trim();
	
	connection.execute(sql_checkPassword,[empid],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}
		else{
			bcrypt.compare(empCurrentPwd,rows[0].emppwd).then(function(result){
				if(result){
					bcrypt.hash(empUpdatePwd, 12, function(err, hashPwd) {
						if(err){
							console.error(err);
							next(err);
						}else{
							connection.execute(sql_updatePassword,[hashPwd,empid],(err,rows)=>{
								if(err){
									console.error(err);
									next(err);
								}
							});
							res.send("<script>alert('패스워드가 정상적으로 변경되었습니다. \n재 로그인을 부탁드립니다.'); window.location.href = '/admin/logout';</script>");
						}
					});
				}else{
					res.send("<script>alert('현재 패스워드가 일치하지 않습니다.'); window.location.href = '/admin/changePassword';</script>");
				}
				
			});
		}
	});
});

router.get('/getMyReservationHistory',isAllAdminLoggedIn,(req,res,next)=>{
	let empid = req.session.adminInfo.empid;
	
	const workbook = new excel.Workbook();
	const PsyTestWorksheet = workbook.addWorksheet("심리검사 내역");
	const ReservationWorksheet = workbook.addWorksheet("상담 내역");

	const sql_selectPsyTestLog="SELECT s.stuno,s.stuname,s.gender,s.birth,s.email,s.date,GROUP_CONCAT(ptl.testname) AS testname " +
		  "from PsyTest p,PsyTestList ptl,SimpleApplyForm s where s.serialno=p.serialno AND p.testno=ptl.testno GROUP BY s.serialno";
	
	const sql_selectReservationLog="SELECT reserv.stuno, reserv.typeno, simple.stuname, contype.typename,reserv.agree,reserv.finished, simple.date " +
		  "FROM Reservation reserv JOIN SimpleApplyForm simple ON reserv.serialno = simple.serialno JOIN ConsultType contype ON reserv.typeno = contype.typeno " +
		  "WHERE NOT reserv.typeno IS NULL AND reserv.empid=? AND reserv.status=1";
	
	const fileName=`유한대학교 학생상담센터 상담 내역.xlsx`;
	
	PsyTestWorksheet.columns=[
		{header:'학번',key:"stuno",width:10},
		{header:'이름',key:'stuname',width:10},
		{header:'성별',key:'gender',width:20},
		{header:'생년월일',key:'birth',width:50},
		{header:'이메일',key:'email',width:20},
		{header:'신청날짜',key:'date',width:20},
		{header:'신청목록',key:'testname',width:100}
	];
	
	ReservationWorksheet.columns=[
		{header:'학번',key:'stuno',width:10},
		{header:'이름',key:'stuname',width:15},
		{header:'상담종류',key:'typename',width:15},
		{header:'개인정보동의여부',key:'agree',width:10},
		{header:'상담완료여부',key:'finished',width:15},
		{header:'신청날짜',key:'date',width:20}
	];

	connection.execute(sql_selectReservationLog,[empid],(err,rows) => {
		if(err){
			console.error(err);
			next(err);
			ReservationWorksheet.addRows(rows);
		}else{
			if(rows.length===0){
				
			}else{
				rows.forEach((row, index) => {
					if(row.agree === 1){
						row.agree = "동의";
					}else{
						row.agree = "비동의";
					}
					if(row.finished === 1){
						row.finished = "완료";
					}else{
						row.finished = "미완료";
					}
				});
			}
			ReservationWorksheet.addRows(rows);
			connection.execute(sql_selectPsyTestLog, (err,rows) => {
				if(err){
					console.error(err);
					next(err);
				}else{
					PsyTestWorksheet.addRows(rows);
					workbook.xlsx.writeFile(fileName).then(() => {
						res.download(path.join(__dirname,"/../"+fileName), fileName, function(err) {
							  if (err) {
								console.error(err); 
							  }else{
								 fs.unlink(fileName, function(){
					  				});
							  }
						});
					});
				}
			});
		}
	});
});

router.get('/getSatisfactionResult', isAllAdminLoggedIn, (req, res, next) => {
	const workbook = new excel.Workbook();
	const satisfactionWorkSheet = workbook.addWorksheet("만족도조사 결과");
	
	const sql_getSatisfationResult = "SELECT Reservation.stuno, Counselor.empname, SimpleApplyForm.stuname, SimpleApplyForm.birth, SimpleApplyForm.email, Reservation.date, " + 
		  "Reservation.researchdatetime, ConsultType.typename, Reservation.serialno, AskList.ask, AnswerLog.choiceanswer " + 
		  "FROM Reservation JOIN SimpleApplyForm ON Reservation.serialno = SimpleApplyForm.serialno LEFT JOIN ConsultType ON Reservation.typeno = ConsultType.typeno LEFT JOIN Counselor ON " + 
		  "Reservation.empid = Counselor.empid JOIN AnswerLog ON Reservation.serialno = AnswerLog.serialno JOIN AskList ON AnswerLog.askno = AskList.askno " +
		  "WHERE AskList.typeno = 3 GROUP BY Reservation.stuno, Counselor.empname, SimpleApplyForm.stuname, SimpleApplyForm.birth, SimpleApplyForm.email, Reservation.date, " +
		  "ConsultType.typename, AnswerLog.serialno, AskList.ask ORDER BY Reservation.researchdatetime;";
	
	//const fileName = `유한대학교 학생상담센터 만족도 조사 내역 ${new Date().getFullYear()}_${new Date().getMonth() + 1}월.xlsx`;
	const fileName = `유한대학교 학생상담센터 만족도조사 내역.xlsx`;
	satisfactionWorkSheet.columns = [
		{header: '작성일', key: "researchdatetime", width : 20},
		{header: '학번', key:"stuno", width:10},
		{header: '상담사명', key:"empname", width:10},
		{header: '학생이름', key:"stuname", width:10},
		{header: '생년월일', key:"birth", width:10},
		{header: '이메일', key:"email", width:20},
		{header: '예약일', key:"date", width:10},
		{header: '상담유형', key:"typename", width:10},
		{header: '질문', key:"ask", width:30},
		{header: '답변', key:"choiceanswer", width:50}
	];
	let rangeColumn = ['A1','B1','C1','D1','E1','F1','G1','H1','I1','J1'];
	rangeColumn.forEach((item, index) => {
		satisfactionWorkSheet.getCell(item).fill = {
			type : 'pattern',
			pattern : 'solid',
			fgColor : {argb :  'FFFFFF00'}
		};	
	});
	
	
	connection.execute(sql_getSatisfationResult, (err, rows) =>{
		if(err) console.error(err);
		else{
			if(rows.length===0){
				res.send("<script>alert('접수된 내역이 없습니다.'); window.location.href = '/admin/';</script>");
			}else{
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
					res.download(path.join(__dirname,"/../"+fileName), fileName, function(err) {
						if (err) {
							console.log(err);
						}
						else {
							fs.unlink(fileName, function(){
								
							});
						}
					});
				});
			}
		}
	});
});

router.get('/getAllReservationHistory',isAllAdminLoggedIn,(req,res,next)=>{
	let empid = req.session.adminInfo.empid;
	
	const workbook = new excel.Workbook();
	const PsyTestWorksheet = workbook.addWorksheet("심리검사 내역");
	const ReservationWorksheet = workbook.addWorksheet("상담 내역");

	const sql_selectPsyTestLog="SELECT s.stuno,s.stuname,s.gender,s.birth,s.email,s.date,GROUP_CONCAT(ptl.testname) AS testname " +
		  "from PsyTest p,PsyTestList ptl,SimpleApplyForm s where s.serialno=p.serialno AND p.testno=ptl.testno GROUP BY s.serialno";
	const sql_selectReservationLog="SELECT  reserv.stuno, reserv.typeno, simple.stuname, contype.typename,reserv.agree,reserv.finished, simple.date " +
		  "FROM Reservation reserv JOIN SimpleApplyForm simple ON reserv.serialno = simple.serialno JOIN ConsultType contype ON reserv.typeno = contype.typeno " +
		  "WHERE NOT reserv.typeno IS NULL AND reserv.status=1";
	
	const fileName=`유한대학교 학생상담센터 전체 상담 내역.xlsx`;
	
	PsyTestWorksheet.columns=[
		{header:'학번',key:"stuno",width:10},
		{header:'이름',key:'stuname',width:10},
		{header:'성별',key:'gender',width:20},
		{header:'생년월일',key:'birth',width:50},
		{header:'이메일',key:'email',width:20},
		{header:'신청날짜',key:'date',width:20},
		{header:'신청목록',key:'testname',width:100}
	];
	ReservationWorksheet.columns=[
		{header:'학번',key:'stuno',width:10},
		{header:'이름',key:'stuname',width:15},
		{header:'상담종류',key:'typename',width:15},
		{header:'개인정보동의여부',key:'agree',width:10},
		{header:'상담완료여부',key:'finished',width:15},
		{header:'신청날짜',key:'date',width:20}
	];

	connection.execute(sql_selectReservationLog,[empid],(err,rows) => {
		if(err){
			console.error(err);
			next(err);
		}else{
			if(rows.length===0){
				
			}else{
				rows.forEach((row, index) => {
					if(row.agree === 1){
						row.agree = "동의";
					}else{
						row.agree = "비동의";
					}
					if(row.finished === 1){
						row.finished = "완료";
					}else{
						row.finished = "미완료";
					}
				});
			}
			ReservationWorksheet.addRows(rows);
			connection.execute(sql_selectPsyTestLog, (err,rows) => {
				if(err){
					console.error(err);
					next(err);
				}else{
					PsyTestWorksheet.addRows(rows);
					workbook.xlsx.writeFile(fileName).then(() => {
						res.download(path.join(__dirname,"/../"+fileName), fileName, function(err) {
						  if (err) {
							console.log(err); 
						  }else{
								fs.unlink(fileName, function(){
					  			});
						  }
						});
					});
				}
			});
		}
	});
});

router.get('/getAllChatLog',isOnlyAdminLoggedIn,(req,res,next)=>{
	let empid = req.session.adminInfo.empid;
	const sql_selectAllChatLog="select * from ConsultLog";
	const workbook = new excel.Workbook();
	const ChatLogWorksheet = workbook.addWorksheet("전체 채팅 내역");
	const fileName=`유한대학교 학생상담센터 전체 채팅 내역.xlsx`;
	ChatLogWorksheet.columns=[
		{header:'상담일련번호',key:'serialno',width:10},
		{header:'채팅 내역',key:'chatlog',width:100},
		{header:'상담 일자',key:'date',width:15},
	];
	connection.execute(sql_selectAllChatLog,(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			ChatLogWorksheet.addRows(rows);
			workbook.xlsx.writeFile(fileName).then(() => {
				res.download(path.join(__dirname,"/../"+fileName), fileName, function(err) {
					if (err) {
						console.error(err); 
					}else{
						fs.unlink(fileName, function(){
						  
					  	});
					}
				});
			});
		}
	});
});

router.get('/getUserChatLog/:serialNo',isOnlyAdminLoggedIn,(req,res,next)=>{
	let empid = req.session.adminInfo.empid;
	const serialNo=decodeURIComponent(req.params.serialNo);
	const stuName=req.query.name;
	const sql_selectAllChatLog="select * from ConsultLog where serialno=?";
	const workbook = new excel.Workbook();
	const ChatLogWorksheet = workbook.addWorksheet("채팅 내역");
	const fileName=`${stuName}_${moment().format('YYYYMMDD')}_채팅내역.xlsx`;
	ChatLogWorksheet.columns=[
		{header:'상담일련번호',key:'serialno',width:10},
		{header:'채팅 내역',key:'chatlog',width:100},
		{header:'상담 일자',key:'date',width:15},
	];
	connection.execute(sql_selectAllChatLog,[serialNo],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			ChatLogWorksheet.addRows(rows);
			workbook.xlsx.writeFile(fileName).then(() => {
				res.download(path.join(__dirname,"/../"+fileName), fileName, function(err) {
					  if (err) {
						console.error(err); 
					  }else{
						fs.unlink(fileName, function() {
						  
					  	});
					  }
				});
			});
		}
	});
});

router.get('/getSimpleApplyFormPDF/:serialNo',isAllAdminLoggedIn,(req,res,next)=>{
	const serialNo=decodeURIComponent(req.params.serialNo);
	const sql_selectConsultApply = "SELECT a.serialno, a.stuno, a.stuname, User.phonenum, a.gender, a.birth, a.email, a.date, " +
				  "GROUP_CONCAT(b.ask SEPARATOR '|') AS 'asks', " +
				  "GROUP_CONCAT(c.choiceanswer SEPARATOR '|') AS 'answers', " +
				  "selfcheck.checknames, selfcheck.scores " +
				  "FROM SimpleApplyForm a, AskList b, AnswerLog c, User,  " +
				  "(SELECT GROUP_CONCAT(list.checkname SEPARATOR '|') AS 'checknames', " +
				  "GROUP_CONCAT(self.score SEPARATOR '|') AS 'scores' " +
				  "FROM SelfCheckList list, SelfCheck self " +
				  "WHERE self.serialno=? and self.checkno=list.checkno) selfcheck " +
				  "WHERE a.serialno=? and a.serialno=c.serialno and c.askno=b.askno and User.stuno = a.stuno";
	
	const sql_getApplyType = "SELECT Reservation.serialno, ConsultType.typename FROM Reservation LEFT JOIN ConsultType ON Reservation.typeno = ConsultType.typeno WHERE Reservation.serialno = ?";
	
	const sql_getPsyList = "SELECT GROUP_CONCAT(PsyTestList.testname SEPARATOR ', ') AS testnames FROM PsyTest JOIN PsyTestList ON PsyTest.testno = PsyTestList.testno WHERE PsyTest.serialno = ?";
	
	
	connection.execute(sql_getApplyType, [serialNo], (err, typeRows) => {
		if(err){
			console.error(err);
			next(err);
		}else{
			let applyType = typeRows[0].typename === null ? "심리검사" :  typeRows[0].typename;
			
			
			connection.execute(sql_getPsyList, [serialNo], (err, psyRows) => {
				if(err){
					console.error(err);
					next(err);
				}else{
					connection.execute(sql_selectConsultApply,[serialNo,serialNo],(err,ConsultRows)=>{
						if(err){
							console.error(err);
							next(err);
						}else{

							let asks=ConsultRows[0].asks === null ? [] : ConsultRows[0].asks.split("|");


							let answers=ConsultRows[0].answers === null ? [] : ConsultRows[0].answers.split("|");

							let checknames=ConsultRows[0].checknames===null ? [] : ConsultRows[0].checknames.split("|");
							let scores=ConsultRows[0].scores===null ? [] : ConsultRows[0].scores.split("|");
							for(let i=0; i<scores.length; i++){
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
								}
							}



							let fileName=`${ConsultRows[0].serialno}.pdf`;
							const doc = new pdfDocument({compress:false});
							let pdfFile = path.join(__dirname, `/../${ConsultRows[0].serialno}.pdf`);
							var pdfStream = fs.createWriteStream(pdfFile);
							doc.font(path.join(__dirname,'/../public/res/font/NANUMGOTHIC.TTF'));

							doc
								.fontSize(20)
								.text('간단신청서', { align: 'center' }) // x, y 좌표
								.moveDown(1.5);


							doc.moveTo(70,110)
								.lineTo(540,110)
								.stroke();



							doc
								.fontSize(12)
								.text(`신청일자 : ${ConsultRows[0].date}`, { align : 'right'})
								.moveDown(0.8);
							doc
								.fontSize(12)
								.text(`상담 유형 : ${applyType}`, {align : 'right'})
								.moveDown(2);

							doc
								.fontSize(15)
								.text('인적사항', { align : 'left'})
								.moveDown(0.8);

							doc
								.fontSize(10)
								.text(`학번 : ${ConsultRows[0].stuno}`, { align: 'left' })
								.moveDown(0.5);

							doc
								.fontSize(10)
								.text(`이름 : ${ConsultRows[0].stuname}`, { align : 'left'})
								.moveDown(0.5);
							doc
								.fontSize(10)
								.text(`성별 : ${ConsultRows[0].gender}`, { align : 'left'})
								.moveDown(0.5);
							doc
								.fontSize(10)
								.text(`생년월일 : ${ConsultRows[0].birth}`, { align : 'left'})
								.moveDown(0.5);
							doc
								.fontSize(10)
								.text(`휴대폰번호 : ${ConsultRows[0].phonenum}`, {align : 'left'})
								.moveDown(0.5);

							doc
								.fontSize(10)
								.text(`이메일주소 : ${ConsultRows[0].email}`, {align : 'left'})
								.moveDown(2);



							
							
							asks.forEach(function (v, i) {
								


								doc
									.fontSize(10)
									.text(`질문. ${asks[i]}`, {align:'left'})
									.moveDown(0.5);

								doc
									.fontSize(8)
									.text(answers[i] ,{align:'left'})
									.moveDown();


								if(i === asks.length - 1){
									doc.moveDown(2);
								}
							});

							if(applyType == "심리검사"){
								doc
									.fontSize(15)
									.text('신청 심리검사', { align : 'left'})
									.moveDown(0.5);
								
								doc
									.fontSize(10)
									.text(psyRows[0].testnames, {align :'left'})
									.moveDown(0.5);
								
							}else{
								
								doc
									.fontSize(15)
									.text('자가진단 질문', { align : 'left'})
									.moveDown(0.8);
							}


							checknames.forEach(function(v, i){
								

								doc
									.fontSize(10)
									.text(`질문. ${checknames[i]}`,{align:'left'})
									.moveDown(0.5);

								doc
									.fontSize(8)
									.text(scores[i],{align:'left'})
									.moveDown();


								if(i === checknames.length - 1){
									doc.moveDown(2);
								}

							});

							doc.pipe(pdfStream);
							doc.end();
							
							let pdfFileName = `${ConsultRows[0].stuname}_${ConsultRows[0].stuno}_상담신청서.pdf`;
							
							pdfStream.addListener('finish', function() {
								res.download(pdfFile, pdfFileName, function(err) {
								  if (err) {
									console.error(err);
								  }else{
									  fs.unlink(pdfFile, function(){

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