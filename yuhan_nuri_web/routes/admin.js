const express = require('express');
const router = express.Router();

const db = require('../public/res/js/database.js')();
const connection = db.init();
db.open(connection, "admin");

const sanitizeHtml=require('sanitize-html');
const bcrypt=require('bcrypt');

const fs = require('fs');
const path=require('path');

const schedule = require('node-schedule');
const pdfDocument = require('pdfkit');

const {reservationAcceptPush,answerPush,satisfactionPush} = require('./fcm'); 
const {isAllAdminLoggedIn,isOnlyAdminLoggedIn} = require('./middlewares');  

const excel = require('exceljs');

const moment = require("moment");
require('moment-timezone'); 
moment.tz.setDefault("Asia/Seoul");

try{
	fs.accessSync('uploads');
}catch(error){
	fs.mkdirSync('uploads');
}

let deleteRule = new schedule.RecurrenceRule();
deleteRule.dayOfWeek = [0, new schedule.Range(0,6)];
deleteRule.hour= 00;
deleteRule.minute= 00;

router.use(function(req, res, next) {
     res.locals.adminInfo = req.session.adminInfo;
     next();
});

exports.deleteOneMonth = ()=> { 
	let deleteRule = new schedule.RecurrenceRule();
	deleteRule.dayOfWeek = [0, new schedule.Range(0,6)];
	deleteRule.hour= 00;
	deleteRule.minute= 00;
	const sql_deleteQuestionAfterOneMonth="delete from QuestionBoard where answerdate<=?"; // 현재 날짜에서 30일 이전의 문의 데이터를 지웁니다.
	const sql_deleteSimpleApplyFormAfterOneMonth="delete from SimpleApplyForm where date <= ?"; // 현재 날짜에서 30일 이전의 상담 신청서 데이터를 지웁니다.
	const sql_test1 = "select * from QuestionBoard where answerdate <= ?";
	const sql_test2= "select * from SimpleApplyForm where date <= ?";
	let testRule='10 * * * * *'; // 10초에 한번 실행됩니다.
	schedule.scheduleJob(deleteRule, function(){ // 한 번 밖에 실행이 되지 않음
		connection.execute(sql_deleteQuestionAfterOneMonth, [moment().subtract(1, 'months').format("YYYY-MM-DD")], (err, rows) => {
			if(err){
				console.error(err);
				next(err);
			}
		});
		connection.execute(sql_deleteSimpleApplyFormAfterOneMonth, [moment().subtract(1, 'months').format("YYYY-MM-DD")], (err, rows) => {
			if(err){
				console.error(err);
				next(err);
			}
		});
	});
}

router.get("/",isAllAdminLoggedIn,function(req,res,next){ //GET /admin
	const getReservationData = "SELECT User.stuname as stuname, User.phonenum as phonenum, reserv.serialno as no, " +
		  "reserv.stuno as stuno, consult.typename as typename, reserv.starttime as starttime, reserv.date as date " +  
		  "FROM User JOIN Reservation reserv ON User.stuno = reserv.stuno LEFT JOIN ConsultType consult ON reserv.typeno = consult.typeno " +
		  "WHERE reserv.status = 0 AND (reserv.empid = ? OR reserv.empid IS NULL) ORDER BY no;";
	
	let empid = req.session.adminInfo.empid;
	
	connection.execute(getReservationData, [empid], (err,rows) => {
		
		if(err) {
			console.error(err);
			next(err);
		}else{
			res.render('admin', {getReservation: rows});	
		}
	});
});

router.post("/readReservedSchedule", isAllAdminLoggedIn, function(req, res, next){	
	const sql_readReservedSchedule = "SELECT consulttype.typename as typename, user.stuno as stuno, user.stuname as stuname, reserv.date as date, reserv.finished as finished, reserv.empid, " +
		  "reserv.starttime as starttime, reserv.date as date " +
		  "FROM Reservation reserv JOIN User user ON reserv.stuno = user.stuno JOIN ConsultType consulttype ON reserv.typeno = consulttype.typeno " +
		  "WHERE reserv.empid = ? AND reserv.status = 1";
	
	// 수락이 된 것만 스케줄에 표시가 됨
	const sql_maxIdInSchedule = "SELECT MAX(scheduleno) as maxIdValue FROM Schedule";
	const date_format = "YYYY-MM-DD HH:mm:ss";
	
	let maxid = 0;
	let empid = req.session.adminInfo.empid;
	
	
	
	connection.execute(sql_maxIdInSchedule, (err, rows) => {
		if(err) console.error(err);
		else{
			maxid = rows[0].maxIdValue;
			connection.execute(sql_readReservedSchedule, [empid], (err, rows) => {
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
						row.title = `${row.starttime}시 ${row.stuname} 학생 ${row.typename}`;
						
						row.start = row.date + "T" + row.starttime + ":00:00";
						row.end = row.date + "T" + (row.starttime + 1) + ":00:00";
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
	const sql_readMySchedule = "SELECT * FROM Schedule WHERE empid = ?";
	let empid =  req.session.adminInfo.empid;
	
	connection.execute(sql_readMySchedule, [empid], (err, rows) => {
		if(rows.length > 0){
			res.json({schedules : rows});	
		}
	});
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
				res.json({state : "can't update"}); // 이미
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
	
	// 예약, 회의, 휴가의 경우 스케줄 삭제가 가능
	// 이외 스케줄 삭제가 불가능, DB에 없는 스케줄 ID 값이기 때문
	
	const sql_isCanDelete = "SELECT * FROM Reservation WHERE date = ?";
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
				connection.execute(sql_isCanDelete, [reservedStart], (err, usedSchedule_rows) => {   
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
	const sql_getAlreadyScheduled = "SELECT HOUR(start) as start, HOUR(end) as end FROM Schedule WHERE DATE(start) = ?";
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
	
	if(data.location != undefined) location = data.location;
	
	if(startIndex != endIndex){
		res.json({state : "isDiffDate"});
	}else{
		console.info("sql data");
		console.info(empid, data.calendarId, data.title, data.category, start, end, location);
	
		connection.execute(sql_getAlreadyScheduled, [startIndex], (err, row) => {
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
	const sql_findTypes="select type from EditTest";
	let types=[];
	connection.execute(sql_findTypes,(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}
		if(rows.length==0){
			next(err);
		}else{
			types=rows;
		}
		res.render('chattingForm', {
			types: types,
			empid: req.session.adminInfo.empid,
			empname: req.session.adminInfo.empname
		});
		
	});
});

router.post("/addType",isAllAdminLoggedIn,function(req, res, next){
	// type을 저장하는 부분
	const sql_selectName = "SELECT * FROM FormTypeInfo WHERE typename = ?";
	const sql_creType = "INSERT INTO FormTypeInfo(typename) VALUES(?)";
	const newTypename = req.body.add_type;
	
	connection.execute(sql_selectName, [newTypename], (err, rows) => {
		console.info('냥',rows);
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
	const sql_findTypes="select type from EditTest";
	let types=[];
	connection.execute(sql_findTypes,(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}
		if(rows.length==0){
			next(err);
		}else{
			types=rows;
		}
		res.render('adminCalendar',{types:types});
	});
});


router.get("/settings",isOnlyAdminLoggedIn,function(req,res,next){
	const sql_selectCounselor="select empid,empname,positionno from Counselor";
	connection.execute(sql_selectCounselor,(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			res.render('adminSetting',{result:rows});
		}
	});
});



router.post('/uploadFile',isAllAdminLoggedIn,function(req,res){
	res.json({
		"success":1,
		"file":{
			"url":"/"+req.file.path.toString(),
		},
	});
});

router.get('/appTest',isAllAdminLoggedIn,function(req,res,next){ // 공지사항 출력결과 확인 테스트
	const sql_selectEditData = "SELECT * FROM EditTest";
	connection.execute(sql_selectEditData,(err,rows)=>{
		if(err){
			next(err);
			console.error(err);
		}
		res.render('applicationTest',{data:rows});
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
	const testEmp='emp100001';
	
	const secureXSSContent = sanitizeHtml(sendAjax);
	connection.execute(sql_saveBoard,[testEmp,secureXSSContent,paramType],(err,rows)=>{
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
    const sql_checkType = "select typename from AskType where typeno=?";
    const sql_findFiveConceptForm = "select ask from AskList where typeno=3";
    const sql_findThreeConceptForm = "select *,(select GROUP_CONCAT(choice) from ChoiceList where askno=a.askno) as choice from AskList a where typeno=? AND a.use = 'Y'";
	let type="";
	let types=[];
	let max=0;
	const paramType=decodeURIComponent(req.params.type);
	
    //상담,심리는 3문항 심리검사 5문항
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
            type=rows[0].typename;
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

router.post('/saveForm/:type',isAllAdminLoggedIn,function(req,res,next){ //ajax로 Save버튼을 누를 경우
    const sendObject = JSON.parse(req.body.sendAjax);
    let max;
    const sql_checkMaxAskCount = "select MAX(askno) as maxAskNo from AskList";
    const sql_insertThreeOrFiveConceptAsk = "insert into AskList(askno,typeno,choicetypeno,ask,AskList.use) values(?,?,?,?,'Y')";
    const sql_noUseThreeOrFiveConceptAsk = "update AskList set AskList.use = 'N' where askno < ? and typeno = ?";
    const sql_insertThreeConceptChoice = "insert into ChoiceList(askno,typeno,choice) values(?,?,?)";

    connection.execute(sql_checkMaxAskCount,(err,rows)=>{
        if(err){
            console.error(err);
            next(err);
        }else{
            max=rows[0].maxAskNo;
			connection.execute(sql_noUseThreeOrFiveConceptAsk,[Number(max+1),req.params.type],(err,rows)=>{ //된거 같아용!!!!
				if(err){
					console.error(err);
					next(err);
				}
			});
        }
    });
	
	if(req.params.type === '1' || req.params.type === '2' || req.params.type==='3'){ // 3문항
		sendObject.forEach(function(v,i){
			let tempAskNo = v.id.split('card_id_')[1];
			let tempType=0;
			
			if(v.type === 'radio'){
				tempType = 1;
			}else if(v.type === 'check'){
				tempType = 2;
			}else if(v.type==='normal'){
				tempType = 3;
			}
			
			connection.execute(sql_insertThreeOrFiveConceptAsk,[(max+i)+1,req.params.type,tempType,v.question],(err,rows)=>{
				if(err){
					console.error(err);
					next(err);
				}else{
					if(v.askList===undefined){

					}else{
						v.askList.forEach(function(b,j){
							connection.execute(sql_insertThreeConceptChoice,[(max+i)+1,tempType,b.ask],(err,rows)=>{
								if(err){
									console.error(err);
									next(err);
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


router.post('/noUseAsk',isAllAdminLoggedIn,function(req,res,next){ //ajax로 질문삭제 버튼을 누를 경우
	let data = req.body.noUse;
    const sql_noUseAsk = "update AskList set AskList.use = 'N' where askno = ?";
    connection.execute(sql_noUseAsk,[data],(err,rows)=>{
        if(err){
            console.error(err);
            next(err);
        }
    })
});

router.get('/signUp',isOnlyAdminLoggedIn,function(req,res,next){
	res.render('adminSignUp');
});

router.post('/signUp',isOnlyAdminLoggedIn,(req,res,next)=>{
	const sql_addCounselor="insert into Counselor(empid,emppwd,empname,positionno) values(?,?,?,?)";
	const sql_checkEmpId="select empid from Counselor where empid=?";
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
						if(isEmp){ // 교직원 1
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
			}else{
				res.send("<script>alert('이미 있는 아이디입니다!'); window.location.href = '/admin/signUp';</script>");
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
			max=rows[0].maxCheckNo;
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
	const sql_noUseSelfCheck = "update SelfChekList set SelfChekList.use = 'N' where checkno = ?";
	
	connection.execute(sql_noUseSelfCheck,[data],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}
	});
});

router.post('/saveSelfCheckList',isAllAdminLoggedIn,(req,res,next)=>{
	const sendObject = JSON.parse(req.body.sendAjax);
	let max;
	const sql_checkMaxSelfCheckCount = "select MAX(checkno) as maxCheckNo from SelfCheckList";
	const sql_noUseSelfCheck = "update SelfCheckList set SelfCheckList.use = 'N' where checkno < ?";
	const sql_insertSelfCheck = "insert into SelfCheckList(checkname,SelfCheckList.use) values(?,'Y')";

	connection.execute(sql_checkMaxSelfCheckCount,(err,rows)=>{
        if(err){
            console.error(err);
            next(err);
        }else{
            max=rows[0].maxCheckNo;
			connection.execute(sql_noUseSelfCheck,[Number(max+1)],(err,rows)=>{
				if(err){
					console.error(err);
					next(err);
				}
			});
        }
    });
	
	sendObject.forEach(function(v,i){
		connection.execute(sql_insertSelfCheck,[v.ask],(err,rows)=>{
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
		}
	});
});

router.post('/deleteCounselor',isOnlyAdminLoggedIn,(req,res,next)=>{
	const delEmpId=req.body.deleteId;
	const sql_deleteCounselor="delete from Counselor where empid = ?";
	connection.execute(sql_deleteCounselor,[delEmpId],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			res.json('ok');
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
							res.send("<script>alert('비밀번호가 변경되었습니다! 다시 로그인 해주세요!'); window.location.href = '/admin/logout';</script>");
						}
					});
				}else{
					res.send("<script>alert('현재 비밀번호와 다릅니다!'); window.location.href = '/admin/changePassword';</script>");
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
	
	const fileName=`유한대학교 상담 심리 센터 상담 내역 ${new Date().getFullYear()}_${new Date().getMonth()+1}월.xlsx`;
	
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
	const fileName=`유한대학교 상담 심리 센터 전체 상담 내역 ${new Date().getFullYear()}_${new Date().getMonth()+1}월.xlsx`;
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
	const fileName=`유한대학교 상담 심리 센터 전체 채팅 내역 ${new Date().getFullYear()}_${new Date().getMonth()+1}월.xlsx`;
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
	const sql_selectAllChatLog="select * from ConsultLog where serialno=?";
	const workbook = new excel.Workbook();
	const ChatLogWorksheet = workbook.addWorksheet("채팅 내역");
	const fileName=`유한대학교 상담 심리 센터 채팅 내역 ${new Date().getFullYear()}_${new Date().getMonth()+1}월_${serialNo}.xlsx`;
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
						fs.unlink(fileName, function(){
						  
					  	});
					  }
				});
			});
		}
	});
});

router.get('/getSimpleApplyFormPDF/:serialNo',isAllAdminLoggedIn,(req,res,next)=>{
	const serialNo=decodeURIComponent(req.params.serialNo);
	const sql_selectMental = "SELECT a.serialno, a.stuno, a.stuname, a.gender, a.birth, a.email, a.date, " +
				  "GROUP_CONCAT(b.ask SEPARATOR '|') AS 'asks', GROUP_CONCAT(c.choiceanswer SEPARATOR '|') AS 'answers', " +
				  "(SELECT GROUP_CONCAT(testname) FROM PsyTestList list, " +
				  "(SELECT testno FROM PsyTest WHERE serialno=?) psy WHERE psy.testno = list.testno) AS 'testnames' " +
				  "FROM SimpleApplyForm a, AskList b, AnswerLog c " +
				  "WHERE a.serialno=? and a.serialno=c.serialno and c.askno=b.askno;";
	const sql_selectConsultApply = "SELECT a.serialno, a.stuno, a.stuname, a.gender, a.birth, a.email, a.date, " +
				  "GROUP_CONCAT(b.ask SEPARATOR '|') AS 'asks', " +
				  "GROUP_CONCAT(c.choiceanswer SEPARATOR '|') AS 'answers', " +
				  "selfcheck.checknames, selfcheck.scores " +
				  "FROM SimpleApplyForm a, AskList b, AnswerLog c, " +
				  "(SELECT GROUP_CONCAT(list.checkname SEPARATOR '|') AS 'checknames', " +
				  "GROUP_CONCAT(self.score SEPARATOR '|') AS 'scores' " +
				  "FROM SelfCheckList list, SelfCheck self " +
				  "WHERE self.serialno=? and self.checkno=list.checkno) selfcheck " +
				  "WHERE a.serialno=? and a.serialno=c.serialno and c.askno=b.askno;";
	
	connection.execute(sql_selectConsultApply,[serialNo,serialNo],(err,ConsultRows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			let asks=ConsultRows[0].asks.split("|");
			let answers=ConsultRows[0].answers.split("|");
			let cheknames=ConsultRows[0].checknames.split("|");
			let scores=ConsultRows[0].scores.split("|");
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
			let AllAsks=asks.concat(cheknames);
			let AllAnswers=answers.concat(scores);

			let fileName=`${ConsultRows[0].serialno}.pdf`;
			const doc = new pdfDocument({compress:false});
			let pdfFile = path.join(__dirname, `/../${ConsultRows[0].serialno}.pdf`);
			var pdfStream = fs.createWriteStream(pdfFile);
			doc.font(path.join(__dirname,'/../public/res/font/NANUMGOTHIC.TTF'));

			doc
				.fontSize(15)
				.text('간단신청서', { align: 'center' }); // x, y 좌표
			doc
				.fontSize(10)
				.text(`${ConsultRows[0].stuno}_${ConsultRows[0].stuname}`, { align: 'right' });
			let pointX=100;
			let pointY=150;
			AllAsks.forEach(function (v, i) {
				if((i+1)%10===0){
					doc.addPage()
				}
				if(pointY>=600){
					pointY-=500;
				}
				pointY+=50;
				doc
					.fontSize(10)
					.text(`Q${i+1} ${AllAsks[i]} \n`, pointX, pointY,{align:'left'});
				doc
					.fontSize(8)
					.text('\n\n'+AllAnswers[i] + '\n', pointX, pointY),{align:'left'};
			});
			doc.pipe(pdfStream);
			doc.end();
			pdfStream.addListener('finish', function() {
				res.download(pdfFile, `${ConsultRows[0].serialno}.pdf`, function(err) {
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
});

module.exports = router;