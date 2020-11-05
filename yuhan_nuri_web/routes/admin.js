const express = require('express');
const router = express.Router();

const db = require('../public/res/js/database.js')();
const connection = db.init();
db.open(connection, "admin");

const fs = require('fs');
const path=require('path');
const multer=require('multer');

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

//isAdminLoggedIn은 로그인 정보가 있는지 판단하고 없으면 로직을 처리하지 않고 로그인을 해달라는 문구가 있는 페이지로 전달합니다. -성준

router.get("/",isAdminLoggedIn,function(req,res,next){ //GET /admin
	const getReservationData = "SELECT * FROM Reservation WHERE status = 0";
	
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
	});
	connection.execute(getReservationData, (err,rows) => {
		if(err) {
			console.error(err);
			next(err);
		}
		res.render('admin', {getReservation: rows,types:types});
	});
});


router.post("/readReservedSchedule", isAdminLoggedIn, function(req, res, next){
	const sql_readReservedSchedule = "SELECT DISTINCT us.stuno, us.stuname, s.empno, us.start, s.category, s.location FROM Schedule s, UsedSchedule us WHERE s.id = us.id AND empno = ?";
	const sql_maxIdInSchedule = "SELECT MAX(id) as maxIdValue FROM Schedule";
	const date_format = "YYYY-MM-DD HH:mm:ss";
	
	let maxid = 0;
	let empno = req.session.adminInfo.empno;
	
	connection.execute(sql_maxIdInSchedule, (err, rows) => {
		if(err) console.error(err);
		else{
			maxid = rows[0].maxIdValue;
			
			connection.execute(sql_readReservedSchedule, [empno], (err, rows) => {
				if(err){
					console.error(err);

				}else{

					rows.forEach((row, index) => {
						maxid++;
						row.id = maxid;
						row.calendarId = "Reserved";
						row.title = `${row.stuno} ${row.stuname} 학생 예약`;	
						row.end = (moment(row.start).add(1,'hours')).format(date_format);
					});
					
					// console.info(rows);
					res.json({reserved : rows});	
				}
		
			});
		}
	});
	
	
	
});



// 관리자 계정에 따라 자신의 스케줄을 가져옴.
router.post("/readMySchedule", isAdminLoggedIn,function(req, res, next){
	const sql_readMySchedule = "SELECT * FROM Schedule WHERE empno = ?";
	/*
		
	*/
	let empno =  req.session.adminInfo.empno;
	
	connection.execute(sql_readMySchedule, [empno], (err, rows) => {
		
		res.json({schedules : rows});
	});
});

// 자신의 스케줄을 변경하는 부분
router.post("/updateSchedule", isAdminLoggedIn,function(req, res, next){
	const datetime_format = "YYYY-MM-DD HH:mm:ss";
	let sql_updateSchedule = "UPDATE Schedule SET ";
	
	let data = JSON.parse(req.body.sendAjax);
	
	let empno = req.session.adminInfo.empno;
	
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
	
	sql_updateSchedule += ` WHERE id = ${data.id}`;
	
	connection.execute(sql_updateSchedule, values, (err, rows) => {
		if(err){
			console.error(err);
			res.json({state : "error"});
			next(err);
		}else{
			res.json({state : "ok"});
		}
		
	});
	
});


// 스케줄 삭제

router.post("/deleteSchedule",isAdminLoggedIn, function(req, res, next){
	let data = JSON.parse(req.body.sendAjax);
	
	// 예약, 회의, 휴가의 경우 스케줄 삭제가 가능
	// 이외 스케줄 삭제가 불가능, DB에 없는 스케줄 ID 값이기 때문
	
	const sql_isCanDelete = "SELECT * FROM UsedSchedule WHERE id = ?";
	const sql_deleteSchedule = "DELETE FROM Schedule WHERE id = ?";
	const sql_isOnSchedule = "SELECT calendarId FROM Schedule WHERE id = ?";
	
	console.info(data);
	
	connection.execute(sql_isOnSchedule, [data.id], (err, schedule_rows) => {
		if(err) {
			console.error(err);
			next(err);
		}else{
			if(schedule_rows.length > 0) { // 상담사님이 입력한 스케줄이면	
				connection.execute(sql_isCanDelete, [data.id], (err, usedSchedule_rows) => {
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
			}else{ // 상담사님이 입력한 스케줄이 아니면
				res.json({state : "can't delete : is not counselor's included schedule"});
			}
		}
	});
	
	

	
		
});

// 스케줄을 새로 생성하는 부분
router.post("/createSchedule", isAdminLoggedIn,function(req, res, next){
	const sql_createSchedule = "INSERT INTO Schedule(empno, calendarId, title, category, start, end, location) VALUES (?, ?, ?, ?, ?, ?, ?)";
	const sql_getAlreadyScheduled = "SELECT HOUR(start) as start, HOUR(end) as end FROM Schedule WHERE DATE(start) = ?";
	const datetime_format = "YYYY-MM-DD HH:mm:ss";
	const date_format = "YYYY-MM-DD";
	let scheduled_hour = [];
	let createad_hour = [];
	let data = JSON.parse(req.body.sendAjax);
	
	console.info(data);
	let empno = req.session.adminInfo.empno;
	
	let start = moment(new Date(data.start)).format(datetime_format);
	let end = moment(new Date(data.end)).format(datetime_format);
	let startIndex = moment(new Date(data.start)).format(date_format);
	let location = "";
	let isDuplicate;
	if(data.location !== undefined) location = data.location; // 특정 장소를 입력하면 입력한 장소 값이 여기로 들어감

	console.info(empno, data.calendarId, data.title, data.category, start, end, location); // 
	
	/*
	let endIndex = moment(new Date(data.end)).format(date_format);
	
	
	if(calendarId === "Reservation" && startIndex !== endIndex){ // 예약 가능 일정을 추가하는데 만약 날짜가 다를 경우 에러
		res.json({state : "error : date different"});
	}
	*/
	/*
	// 이미 동일한 타입으로 스케줄을 예약하였는지를 판단하는 코드
	connection.execute(sql_getAlreadyScheduled, [startIndex], (err, row) => {
		if(err) console.error(err);
		else{
			if(row.length > 0){
				
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
		
		
	});
	*/
	
	
	
	
	connection.execute(sql_createSchedule, [empno, data.calendarId, data.title, data.category, start, end, location], (err, rows) => {
		if(err){
			console.error(err);
			next(err);
		}
		
		res.json({state : "ok"});
	});
});

router.post("/accessReservation",isAdminLoggedIn, function(req,res,next) { //POST /admin/accessReservation
	const getAccessReservationData = "UPDATE Reservation SET status=1, empno = ? WHERE no = ?";
	let data = req.body.sendAjax;
	let empno = req.session.adminInfo.empno;
	

	const getReservationData = "SELECT User.stuno, User.stuname, Reservation.date, Reservation.starttime FROM User, Reservation WHERE no = ? AND User.stuno = Reservation.stuno"; // 특정 일련번호에 대한 하나의 값만 들어옴
	const sql_insertUsedScheduleData = "INSERT INTO UsedSchedule(stuno, stuname, id, start) VALUES (?, ?, ?, ?)";
	const sql_selectId = "SELECT id, start  FROM Schedule WHERE empno = ? AND DATE(start) = ?";
	let usedScheduleData = [];
	let reservedStart = "";
	connection.execute(getReservationData, [data], (err, rows) => {
		if(err){
			console.error(err);
			next(err);
		}else{
			usedScheduleData = rows;
			reservedStart = usedScheduleData[0].date + " " +usedScheduleData[0].starttime + ":00:00";
			connection.execute(sql_selectId, [empno, usedScheduleData[0].date], (err, rows) => {
				if(err)
				{
					console.error(err);
					next(err);
				}else{
					console.info(rows[0]);
					connection.execute(sql_insertUsedScheduleData, [usedScheduleData[0].stuno, usedScheduleData[0].stuname, rows[0].id, reservedStart], (err, rows) => {
						if(err) {
							console.error(err);
							next(err);
						}
					});
				}
			});
		}
	});
	
	connection.execute(getAccessReservationData, [empno, data], (err,rows) => {
		if(err) {
			console.error(err);
			next(err);
		}
		
		res.json({getReservation: rows});
		
	});
});

router.get("/form/:type", function(req,res,next){ 
	
	const paramType=decodeURIComponent(req.params.type);
	const sql_findType="select type from EditTest where type = ?";
	const sql_findTypes="select type from EditTest";
	const sql_readCardData="select content from EditTest where type=?";
	let type="";
	let types=[];
	
	connection.execute(sql_findType,[paramType],(err,rows)=>{ //해당 type의 유무 확인
		if(err){
			console.error(err);
			next(err);
		}
		if(rows.length == 0){ //rows [] 
			next(err);
		}else{
			type=rows[0].type;
		}
	});
	
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
	});
	
	connection.execute(sql_readCardData,[paramType],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}
		switch(type){
			case '공지사항': 
			case '이용안내':
			case 'FAQ':
				if(rows[0].content===''){
					rows[0].content=[];
					res.render('editForm', {result:rows[0].content,type:type,types:types} );
				}else {
					res.render('editForm', {result:JSON.parse(rows[0].content),type:type,types:types} );
				}
				break;
			case '자가진단':
				if(rows[0].content===''){
					rows[0].content=[];
					res.render('surveyForm',{result:rows[0].content,type:type,types:types});
				}else{
					res.render('surveyForm',{result:JSON.parse(rows[0].content),type:type,types:types});
				}
				break;
			case '상담예약신청':
			case '심리검사신청':
			case '만족도조사':
				if(rows[0].content===''){
					rows[0].content=[];
					res.render('simpleApplyForm',{result:rows[0].content,type:type,types:types});
				}else{
					res.render('simpleApplyForm',{result:JSON.parse(rows[0].content),type:type,types:types});
				}
				break;
			default:
				next(err);
		}
	});
});

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
			empno: req.session.adminInfo.empno,
			empname: req.session.adminInfo.empname
		});
		
	});
});

router.post("/saveForm/:type",(req, res, next) => {  
	
	function getParseOrPure(type){ 
	if(type === '공지사항' || '이용안내' || 'FAQ'){
			return req.body.sendAjax;
		}else{
			return JSON.parse(req.body.sendAjax);
		}
	}
	
	const sendAjax=getParseOrPure(req.params.type);
	console.log(sendAjax);
	
	
	// let writer = req.session.adminInfo.empno;
	let writer = "emp100001";
	const sql_updateFormData = "UPDATE EditTest SET content = ?, empno = ? WHERE type = ?";

	
	connection.execute(sql_updateFormData, [req.body.sendAjax,writer,req.params.type ], (err, rows) => {
		if(err){
			console.error(err);
			res.json({state : "error"});
			next(err);
		}
		console.info("데이터베이스 입력 완료");
		res.json({state:'ok'});
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


router.get("/settings",isAdminLoggedIn,function(req,res,next){
	const sql_findTypes="select type from EditTest";
	let types=[];
	connection.execute(sql_findTypes,(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}
		types=rows;
		res.render('adminSetting',{types:types});
	});
});



router.post('/uploadFile',upload.single('image'),function(req,res){
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
router.get('/logout', function(req, res) { //GET /user/logout
    req.session.destroy();
	res.clearCookie('isAutoLogin');
    res.redirect('/');
});
router.get('/question',isAdminLoggedIn,function(req,res){
	const sql_selectQuestion='SELECT * from QuestionBoard';
	const sql_selectMyQuestion='SELECT * from QuestionBoard where empno=?'; 
	const sql_findTypes="select type from EditTest";
	let selectList=[];
	let myList=[];
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
	});
	connection.execute(sql_selectQuestion,(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			selectList=rows;
		}
	});
	connection.execute(sql_selectMyQuestion,['emp100001'],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			myList=rows;
			res.render('adminQuestion',{selectList:selectList,myList:myList,types:types});
		}
	});
});
router.post('/saveQuestion',isAdminLoggedIn,function(req,res,next){
	const sendData=req.body.sendData;
	const sendNumber=req.body.sendNumber;
	const sql_selectOverlappedAnswer='select * from QuestionBoard where no=?';
	const sql_updateAnswer='update QuestionBoard set empno=?,answerdate=?,answer=? where no=?';
	let nowMoment = moment().format("YYYYMMDD");
	let isOverraped=true;
	connection.execute(sql_selectOverlappedAnswer,[sendNumber],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			if(rows[0].empno===null && rows[0].answerdata===undefined && rows[0].answer===null){
					isOverraped=false;
			}
		}
	});
	
	
	if(isOverraped){
		res.json({state:'overlapped'});
	}else{
		connection.execute(sql_updateAnswer,[req.session.adminInfo.empno,nowMoment,sendData,sendNumber],(err,rows)=>{
			if(err){
				console.error(err);
				next(err);
			}else{
				res.json({state:'ok'});
			}
		});
	}
	
});
router.get('/myReservation',function(req,res,next){
	let empno=req.session.adminInfo.empno;
	const sql_findTypes="select type from EditTest";
	const sql_selectMyReservation="select * from Reservation where status=1 and empno=?";
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
	});
	connection.execute(sql_selectMyReservation,[empno],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			res.render('adminMyReservation',{myReservation:rows,types:types});
		}
	})
});
router.post("/finishedReservation",isAdminLoggedIn, function(req,res,next) { //POST /admin/finishedReservation
	const sql_updateFinished = "UPDATE Reservation SET finished=1 WHERE empno = ? AND no = ? AND finisehd = 0";
	let data = req.body.sendAjax;
	let empno = req.session.adminInfo.empno;
	connection.execute(sql_updateFinished,[empno,data],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}else{
			res.json({state:'ok'});
		}
	})
});





var reservationAcceptPush = function() {
	connection.execute(sql_AcceptedToken, [req.body.title], (err, rows) => {
		if(err){
				console.error(err);
				next(err);
		}
		else
		{
			console.log(rows[0]);
			const fcm_target_token = rows[0].token;
		
			const fcm_message = {
				token : fcm_target_token,
				notification : {
		 			title: 'yuhan1', 
					body: '요청하신 예약이 수락되었습니다.',
					//
				},
				data : {
					click_action: 'FLUTTER_NOTIFICATION_CLICK',
				}
			}
			
			fcm_admin.messaging().send(fcm_message)
			.then(function(response){
				console.log('fcm보내기 성공');
			 }).catch(function(error){
				console.log(error);
			});
		}
	}); 
};


module.exports = router;
