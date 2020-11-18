const express = require('express');
const router = express.Router();

const db = require('../public/res/js/database.js')();
const connection = db.init();
db.open(connection, "admin");

const fs = require('fs');
const path=require('path');
const multer=require('multer');

const bcrypt=require('bcrypt');

const {reservationAcceptPush,answerPush} = require('./fcm'); 
const {isAdminLoggedIn} = require('./middlewares');  

const moment = require("moment");
require('moment-timezone'); 
moment.tz.setDefault("Asia/Seoul");
try{
	fs.accessSync('uploads');
}catch(error){
	console.log('uploads 폴더를 생성합니다!');
	fs.mkdirSync('uploads');
}

const upload=multer({
	storage:multer.diskStorage({
		destination(req,file,done){
			done(null,'uploads');
		},
		filename(req,file,done){
			const ext=path.extname(file.originalname);
			const basename=path.basename(file.originalname,ext);
			done(null,basename+ext); // 이후 이름을 변경할 경우 해당 부분을 수정
		}
	}),
	limits:{fileSize:20*1024*1024}, // 20MB
});


router.get("/",isAdminLoggedIn,function(req,res,next){ //GET /admin
	const getReservationData = "SELECT reserv.serialno as no, reserv.stuno as stuno, consult.typename as typename, reserv.starttime as starttime  FROM Reservation reserv LEFT JOIN ConsultType consult ON reserv.typeno = consult.typeno WHERE reserv.status = 0";
	
	// const sql_findTypes="select type from EditTest";
	// let types=[];

	connection.execute(getReservationData, (err,rows) => {
		
		if(err) {
			console.error(err);
			next(err);
		}else{
			res.render('admin', {getReservation: rows});	
		}
	});
});


router.post("/readReservedSchedule", isAdminLoggedIn, function(req, res, next){

	
	const sql_readReservedSchedule = "SELECT user.stuno as stuno, user.stuname as stuname, reserv.date as date, reserv.empid, reserv.starttime as starttime FROM Reservation reserv, User user WHERE reserv.empid = ? AND reserv.stuno = user.stuno";
	const sql_maxIdInSchedule = "SELECT MAX(scheduleno) as maxIdValue FROM Schedule";
	const date_format = "YYYY-MM-DD HH:mm:ss";
	
	let maxid = 0;
	let empid = req.session.adminInfo.empid;
	
	connection.execute(sql_maxIdInSchedule, (err, rows) => {
		if(err) console.error(err);
		else{
			maxid = rows[0].maxIdValue;
			
			connection.execute(sql_readReservedSchedule, [empid], (err, rows) => {
				if(err){
					console.error(err);

				}else{

					rows.forEach((row, index, arr) => {
						
						maxid++;
						row.id = '\'' + maxid + '\'';
						row.calendarId = "Reserved";
						row.title = `${row.stuno} ${row.stuname} 학생 예약`;	

						// let reservedDate = new Date(row.date + " " + row.starttime + ":00:00");
						
					
						/*
						row.start = moment(reservedDate).format(date_format);
						row.end = (moment(reservedDate).add(1,'hours')).format(date_format);
						*/
						
						row.start = row.date + "T" + row.starttime + ":00:00";
						row.end = row.date + "T" + (row.starttime + 1) + ":00:00";
						
						
			
					});
					
					rows = rows.filter(row => row.date != null);
					
					console.info(rows);
					res.json({reserved : rows});	
				}
		
			});
		}
	});
});


// 관리자 계정에 따라 자신의 스케줄을 가져옴.
router.post("/readMySchedule", isAdminLoggedIn,function(req, res, next){
	const sql_readMySchedule = "SELECT * FROM Schedule WHERE empid = ?";
	/*
		
	*/
	let empid =  req.session.adminInfo.empid;
	
	connection.execute(sql_readMySchedule, [empid], (err, rows) => {
		if(rows.length > 0){
			res.json({schedules : rows});	
		}
	});
});

// 자신의 스케줄을 변경하는 부분
router.post("/updateSchedule", isAdminLoggedIn,function(req, res, next){
	const datetime_format = "YYYY-MM-DD HH:mm:ss";
	let sql_updateSchedule = "UPDATE Schedule SET ";
	
	let data = JSON.parse(req.body.sendAjax);
	
	let empid = req.session.adminInfo.empid;
	
	let sql_alreadyReserved = "SELECT serialno FROM Reservation WHERE date = (SELECT DATE(start) FROM Schedule WHERE scheduleno = ?)";

	console.info(data.schedule);
	
	if(data.schedule.start._date.split('T')[0] != data.schedule.end._date.split('T')[0]){
		res.json({state : "can't update : diff date"});
		
	}else{
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
				console.info("updated");

				console.info(data.changes.start);



			}

			if(data.changes.hasOwnProperty("end")){
				data.changes.end = moment(new Date(data.changes.end._date)).format(datetime_format);
			}

			let keys = Object.keys(data.changes);
			let values = Object.values(data.changes);

			console.info(values);
			const key_index = keys.indexOf("state");

			if(key_index > -1){
				keys.splice(key_index, 1);
				values.splice(key_index, 1);
			}
			keys.forEach((item, index) => {

				sql_updateSchedule += (item.toString() +  " = ?,");
			});


			sql_updateSchedule = sql_updateSchedule.slice(0,-1); // 마지막 , 지움

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
		
	}
		
});


// 스케줄 삭제
router.post("/deleteSchedule",isAdminLoggedIn, function(req, res, next){
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
				connection.execute(sql_isCanDelete, [reservedStart], (err, usedSchedule_rows) => {   // 예약 스케줄에 해당 날짜가 있으면// 예약 스케줄에 해당 날짜가 있으면// 예약 스케줄에 해당 날짜가 있으면
					if(err){
						console.error(err);
						next(err);
					}else{
						if(usedSchedule_rows.length > 0){ // 이미 예약을 수락한 학생의 스케줄이 있으면
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
			/*
			else{ // 상담사님이 입력한 스케줄이 아니면
				res.json({state : "can't delete : is not counselor's included schedule"});
			}
			*/
			
		}
	});
	
	
});

// 스케줄을 새로 생성하는 부분
router.post("/createSchedule", isAdminLoggedIn,function(req, res, next){
	const sql_createSchedule = "INSERT INTO Schedule(empid, calendarId, title, category, start, end, location) VALUES (?, ?, ?, ?, ?, ?, ?)";
	const sql_getAlreadyScheduled = "SELECT HOUR(start) as start, HOUR(end) as end FROM Schedule WHERE DATE(start) = ?";
	const datetime_format = "YYYY-MM-DD HH:mm:ss";
	const date_format = "YYYY-MM-DD";
	let scheduled_hour = [];
	let createad_hour = [];
	let data = JSON.parse(req.body.sendAjax);
	
	console.info(data);
	let empid = req.session.adminInfo.empid;
	
	let start = moment(new Date(data.start)).format(datetime_format);
	let end = moment(new Date(data.end)).format(datetime_format);
	let startIndex = moment(new Date(data.start)).format(date_format);
	let endIndex = moment(new Date(data.end)).format(date_format);
	let location = "";
	let isDuplicate;
	if(data.location !== undefined) location = data.location;

	
	console.info(startIndex);
	console.info(endIndex);
	if(startIndex !== endIndex){
		res.json({state : "isDiffDate"});
		return;
	}
	
	console.info(empid, data.calendarId, data.title, data.category, start, end, location);
	
	connection.execute(sql_getAlreadyScheduled, [startIndex], (err, row) => {
		if(err) console.error(err);
		else{
			
			if(row.length > 0){
				for(let time = row[0].start; time <= row[0].end; time++){
					scheduled_hour.push(time);
				}			


				let created_start = new Date(start).getHours();
				let created_end = new Date(end).getHours();

				for(let time = created_start; time <= created_end; time++){
					createad_hour.push(time);
				}
				console.info(scheduled_hour);
				console.info(createad_hour);


				createad_hour.forEach((item, index) => {
					isDuplicate = scheduled_hour.includes(item);

					if(isDuplicate === true){

						return;
					}
				});


				res.json({state : isDuplicate});
			}
			
			
			
		}
		
		
	});
	
	connection.execute(sql_createSchedule, [empid, data.calendarId, data.title, data.category, start, end, location], (err, rows) => {
		if(err){
			console.error(err);
			next(err);
		}
		
		res.json({state : "ok"});
	});
});

router.post("/accessReservation",isAdminLoggedIn, function(req,res,next) { //POST /admin/accessReservation
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
			console.info(row);
			if(row[0].typeno === null){ // 심리검사이면
				psyTestno = 1;
			}
			
			console.info(psyTestno);
			connection.execute(setAccessReservationData, [psyTestno, empid, serialno], (err,rows) => {
				if(err) {
					console.error(err);
					next(err);
				}else{
					reservationAcceptPush(serialno);
					res.json({getReservation: rows});
				}
			});
		}
	});
	
});

router.post("/cancelReservation",isAdminLoggedIn, function(req,res,next) { //POST /admin/cancelReservation
	const setCancelReservationData = "DELETE FROM Reservation WHERE serialno = ?";
	let serialno = req.body.sendAjax;
	
	connection.execute(setCancelReservationData, [serialno], (err,rows) => {
		if(err) {
			console.error(err);
			next(err);
		}else{
			// reservationAcceptPush(serialno);
			res.json({state : "ok"});
		}
	});
});

router.post("/getMentalApplyForm", function(req,res, next) { //POST /admin/getMentalApplyForm
	const query = "SELECT a.stuno, a.stuname, a.gender, a.birth, a.email, a.date, " +
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

router.post("/getConsultApplyForm", function(req,res, next) { //POST /admin/getMentalApplyForm
	const query = "SELECT a.stuno, a.stuname, a.gender, a.birth, a.email, a.date, " +
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

router.get("/getTestRows",(req,res,next)=>{
	const sql_selectData = "select *,(select GROUP_CONCAT(choice) from ChoiceList where askno=a.askno) as choice from AskList a where typeno=1";
	connection.execute(sql_selectData,(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			console.log(rows);
		}
	})
})


router.get("/chat",isAdminLoggedIn, (req, res,next) => {
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

router.post("/addType",isAdminLoggedIn,function(req, res, next){
	// type을 저장하는 부분
	const sql_selectName = "SELECT * FROM FormTypeInfo WHERE typename = ?";
	const sql_creType = "INSERT INTO FormTypeInfo(typename) VALUES(?)";
	const newTypename = req.body.add_type;
	
	connection.execute(sql_selectName, [newTypename], (err, rows) => {
		console.info('냥',rows);
		if(rows.length != 0){
			console.info("err : 이미 있는 타입 !");
			res.json('used Type');
			
		}else{
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

router.get("/schedule",isAdminLoggedIn,function(req,res,next){ //GET /admin/adminTest
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


router.get("/settings",function(req,res,next){
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



router.post('/uploadFile',isAdminLoggedIn,upload.single('image'),function(req,res){
	res.json({
		"success":1,
		"file":{
			"url":"/"+req.file.path.toString(),
		},
	});
});

router.get('/appTest',isAdminLoggedIn,function(req,res,next){ // 공지사항 출력결과 확인 테스트
	const sql_selectEditData = "SELECT * FROM EditTest";
	connection.execute(sql_selectEditData,(err,rows)=>{
		if(err){
			next(err);
			console.error(err);
		}
		res.render('applicationTest',{data:rows});
	});
})
// router.post('/removeFormItem',isAdminLoggedIn,function(req,res,next){
	
// 	const deleteType=req.body.formItem;
// 	const sql_deleteFormItem="DELETE from FormTypeInfo where typename = ?";
// 	connection.execute(sql_deleteFormItem,[deleteType],(err,rows)=>{
// 		if(err){
// 			next(err);
// 			console.error(err);
// 		}
// 		res.json('ok');
// 	});
// });
// router.post('/updateFormItem',isAdminLoggedIn,function(req,res,next){
// 	const updateObject=JSON.parse(req.body.formItem);
// 	const sql_updateFormItem="Update FormTypeInfo set typename=? where typename=?";
// 	connection.execute(sql_updateFormItem,[updateObject.item,updateObject.pastItem],(err,rows)=>{
// 		if(err){
// 			console.error(err);
// 			next(err);
// 		}
// 		res.json('ok');
// 	})
// })
router.get('/logout',isAdminLoggedIn, function(req, res) { //GET /user/logout
    req.session.destroy();
	res.clearCookie('isAutoLogin');
    res.redirect('/');
});
router.get('/question',isAdminLoggedIn,function(req,res){
	const sql_selectQuestion='SELECT * from QuestionBoard where answer IS NULL';
	const sql_selectMyQuestion='SELECT * from QuestionBoard where empname=? and answer IS NULL';
	// const sql_findTypes="select type from EditTest";
	let selectList=[];
	let myList=[];
	let types=[];
	// connection.execute(sql_findTypes,(err,rows)=>{
	// 	if(err){
	// 		console.error(err);	
	// 	}
	// 	if(rows.length==0){
	// 	}else{
	// 		types=rows;
	// 	}
	// });
	connection.execute(sql_selectQuestion,(err,rows)=>{
		if(err){
			console.error(err);
		}else{
			selectList=rows;
		}
	});
	connection.execute(sql_selectMyQuestion,['emp100001'],(err,rows)=>{
		if(err){
			console.error(err);
		}else{
			myList=rows;
			res.render('adminQuestion',{selectList:selectList,myList:myList});
		}
	});
});

router.get('/myReservation',isAdminLoggedIn,function(req,res,next){
	const empid = req.session.adminInfo.empid;
	
	const sql_findNotFinishedMyReservation ="select reserv.serialno as no, reserv.starttime as starttime, consult.typename as typename, reserv.stuno as stuno from Reservation reserv, ConsultType consult where finished = 0 and empid = ? and status = 1 and reserv.typeno = consult.typeno";
	// let types=[];
	// connection.execute(sql_findTypes,(err,rows)=>{
	// 	if(err){
	// 		console.error(err);
	// 		next(err);
	// 	}
	// 	if(rows.length==0){
	// 		next(err);
	// 	}else{
	// 		types=rows;
	// 	}
	// });
	connection.execute(sql_findNotFinishedMyReservation,[empid],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			res.render('adminMyReservation',{myReservation:rows});
		}
	})
});

router.post('/finishedReservation',isAdminLoggedIn,function(req,res,next){
	const sendAjax = req.body.sendAjax;
	const empid = req.session.adminInfo.empid;
	
	const sql_updateFinishReservation = "UPDATE Reservation SET finished=1 WHERE serialno = ? and empid = ?";
	
	connection.execute(sql_updateFinishReservation,[sendAjax, empid ],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			res.json({state:'ok'});
		}
	})
})


router.post('/saveQuestion',isAdminLoggedIn,function(req,res,next){
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
})
router.get('/getExcel',isAdminLoggedIn,function(req,res,next){ //간단 신청서(전부)(AnswerLog *), 개인 정보제공 동의(학번과 동의 여부)(Reservation stuno,agree)
	
});

router.get("/board/:type",function(req,res,next){
	const sql_findType="select no from HomeBoard where no = ?";
	const sql_readBoard="select * from HomeBoard where no = ?";
	const sql_findFormTypes="select typename from AskType";
	let types=[];
	let type=0;
	const paramType=decodeURIComponent(req.params.type);
	
	// connection.execute(sql_findType,[paramType],(err,rows)=>{
	// 	if(err){
	// 		console.error(err);
	// 		next(err);
	// 	}else{
	// 		if(rows.length==undefined){
	// 			next(err);
	// 		}else{
	// 			type=rows[0].no;
	// 		}
	// 	}
	// });
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
				if(rows[0].content==='' || rows[0].content == null){
					rows[0].content=[];
					res.render('editForm',{result:rows[0].content,type:paramType,types:types});
				}else{
					res.render('editForm',{result:JSON.parse(rows[0].content),type:paramType,types:types});
				}
			}
		}
	})
});

router.post("/saveBoard/:type",function(req,res,next){
	const sendAjax=req.body.sendAjax;
	const paramType=decodeURIComponent(req.params.type);
	const sql_saveBoard = "update HomeBoard set empid=?,date=CURDATE(),content=? where no=?";
	const testEmp='emp100001';
	connection.execute(sql_saveBoard,[testEmp,sendAjax,req.params.type],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			res.json({state:'ok'});
		}
	});
});




router.get("/form/:type",function(req,res,next){
	const sql_checkMaxAskCount = "select MAX(askno) as maxAskNo from AskList where typeno=?";
    const sql_findFormTypes="select typeno from AskType";
    const sql_checkType = "select typeno from AskType where typeno=?";
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
            type=rows[0].typeno;
        }
    });
		// connection.execute(sql_findFormTypes,(err,rows)=>{
		// if(err){
		// 	console.error(err);
		// 	next(err);
		// }else{
		// 	types=rows;
		// }
		// });

    if(paramType === '1' || paramType === '2' || paramType==='3'){ //3 문항
        connection.execute(sql_findThreeConceptForm,[paramType],(err,rows)=>{
            if(err){
                console.error(err);
                next(err);
            }
            res.render('simpleApplyForm',{result:rows,type:type,max:max});
        });
    }
    // if(req.params.type === '3'){ // 5 문항
    //     connection.execute(sql_findFiveConceptForm,(err,rows)=>{
    //         if(err){
    //             console.error(err);
    //             next(err);
    //         }else{
    //             res.render('surveyForm',{result:rows,type:type,max:max});
    //         }
    //     })
    // }
});
router.post('/saveForm/:type',function(req,res,next){ //ajax로 Save버튼을 누를 경우
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
				}else{
					console.log('Use->No Use Count',Number(max+1));
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
			}else{
				//에러 표시
			}
			
			connection.execute(sql_insertThreeOrFiveConceptAsk,[(max+i)+1,req.params.type,tempType,v.question],(err,rows)=>{
				console.log('addCount',max+i+1)
				if(err){
					console.error(err);
					next(err);
				}else{
					if(v.askList===undefined){

					}else{
						v.askList.forEach(function(b,j){
							connection.execute(sql_insertThreeConceptChoice,[(max+i)+1,tempType,b.ask],(err,rows)=>{
								console.log('count',(max+i)+1);
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
		// if(req.params.type === '3'){ //FiveConcept 5문항
		// 	sendObject.forEach(function(v,i){
		// 		let tempAskNo = v.id.split('card_id_')[1];
		// 		let tempType=0;
		// 		if(v.type === 'radio'){
		// 			tempType = 1;
		// 		}else if(v.type === 'check'){
		// 			tempType = 2;
		// 		}else if(v.type==='normal'){
		// 			tempType = 3;
		// 		}else{
		// 			// const error=new Error()
		// 			next();
		// 		}
		// 		connection.execute(sql_noUseThreeOrFiveConceptAsk,[tempAskNo],(err,rows)=>{
		// 			if(err){
		// 				console.error(err);
		// 				next(err);
		// 			}
		// 		});
		// 		connection.execute(sql_insertThreeOrFiveConceptAsk,[(max+i),req.params.type,tempType,v.question],(err,rows)=>{
		// 			if(err){
		// 				console.error(err);
		// 				next(err);
		// 			}
		// 		});
		// 	});
			
		// }
	

});


router.post('/noUseAsk',function(req,res,next){ //ajax로 질문삭제 버튼을 누를 경우
	let data = req.body.noUse;
    const sql_noUseAsk = "update AskList set AskList.use = 'N' where askno = ?";
    connection.execute(sql_noUseAsk,[data],(err,rows)=>{
        if(err){
            console.error(err);
            next(err);
        }
    })
});

router.get('/signUp',function(req,res,next){
	res.render('adminSignUp');
});

router.post('/signUp',(req,res,next)=>{
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
	})
})
router.get('/selfCheckForm',(req,res,next)=>{
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
	})
});
router.post('/noUseSelfCheck',(req,res,next)=>{
	let data = req.body.noUse;
	const sql_noUseSelfCheck = "update SelfChekList set SelfChekList.use = 'N' where checkno = ?";
	
	connection.execute(sql_noUseSelfCheck,[data],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}
	});
});
router.post('/saveSelfCheckList',(req,res,next)=>{
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
			connection.execute(sql_noUseSelfCheck,[Number(max+1)],(err,rows)=>{ //된거 같아용!!!!
				if(err){
					console.error(err);
					next(err);
				}else{
					console.log('Use->No Use SelfCheck Count',Number(max+1));
				}
			});
        }
    });
	sendObject.forEach(function(v,i){
		connection.execute(sql_insertSelfCheck,[v.ask],(err,rows)=>{
			if(err){
				console.error(err);
				next(err);
			}else{
			}
		});
	});
	res.json({state:'ok'});
		
});
router.post('/updateCounselor',(req,res,next)=>{
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
router.post('/deleteCounselor',(req,res,next)=>{
	const delEmpId=req.body.deleteId;
	const sql_deleteCounselor="delete from Counselor where empid = ?";
	connection.execute(sql_deleteCounselor,[delEmpId],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			res.json('ok');
		}
	})
})
router.get('/changePassword',isAdminLoggedIn,(req,res,next)=>{
	res.render('adminChangePwd');
});
router.post('/updatePassword',isAdminLoggedIn,(req,res,next)=>{
	const sql_checkPassword="select emppwd from Counselor where empid = ?";
	const sql_updatePassword="update Counselor set emppwd = ? where empid = ?";
	const empid = req.session.adminInfo.empid;
	const empCurrentPwd=req.body.currentPw.trim();
	const empUpdatePwd=req.body.updatePw.trim();
	
	
	
	connection.execute(sql_checkPassword,[empid],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			bcrypt.compare(empCurrentPwd,rows[0].emppwd).then(function(result){
				if(result){ //같다!
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
					// 비밀번호가 다르다.
				}
			});
		}
	});

	
})
module.exports = router;