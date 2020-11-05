const express = require('express');
const router = express.Router();

const db = require('../public/res/js/database.js')();
const connection = db.init();

db.open(connection,'fcm');

const sql_whoispost = "SELECT User.token FROM Reservation, User WHERE Reservation.date = ? AND User.stuno = Reservation.stuno AND User.status = 1";
const sql_AcceptedToken= "SELECT token FROM User WHERE stuno = (select stuno FROM Reservation WHERE no = ?)";
const sql_notifyAnswer = "SELECT token FROM User WHERE stuno = (select stuno FROM QuestionBoard WHERE no =?)";
const sql_satisfaction = "SELECT token FROM User WHERE stuno = (select stuno FROM Reservation WHERE no = ?)";	

const fcm_admin = require('firebase-admin');
var serviceAccount = require('../serviceAccountCredentials.json');
fcm_admin.initializeApp({
	credential : fcm_admin.credential.cert(serviceAccount),
});

const schedule = require('node-schedule');
var rule = new schedule.RecurrenceRule();
rule.dayOfWeek = [0, new schedule.Range(0,6)];
rule.hour= 18;
rule.minute= 00;

var todayRule = new schedule.RecurrenceRule();
todayRule.dayOfWeek = [0, new schedule.Range(0,6)];
todayRule.hour= 08;
todayRule.minute= 00;


const moment = require('moment');
require('moment-timezone'); 
moment.tz.setDefault("Asia/Seoul");


router.get('/', function (req, res) { // GET /fcmEx/isdhsaiudhsauhdsaiuh
    res.render('fcmEx');
});



router.post('/', function (req,res,next){	
	
	
	// 1. 예약 하루전에 "하루전입니다." 발송 로직
	
	
// 	var consultTomorrowPush = function() {schedule.scheduleJob(rule, function(){
// 		connection.execute(sql_whoispost, [moment().add(1, 'd').format("YYYY-MM-DD")], (err, rows) => {
// 			if(err){
// 				console.error(err);
// 				next(err);
// 			}
// 			else
// 			{
// 				for(var i=0; i<rows.length; i++)
// 				{	
// 					const fcm_target_token = rows[i].token;
// 					console.log(fcm_target_token);
// 		 			const fcm_message = {
// 						token : fcm_target_token,
// 						notification : {
// 		 					title: '유한누리', 
// 							body: '상담 하루 전 입니다!' }
// 						};
					
// 					fcm_admin.messaging().send(fcm_message)
// 					.then(function(response){
// 			  			console.log('fcm보내기 성공');
// 			  		}).catch(function(error){
// 						console.log(error);
// 					});				
// 				}
// 			}
// 		});
	
// 	});
//  };
// 	// -----------------1번--------------------
// 
	
	
	
		// 1-1. 예약 당일 "당일입니다." 발송 로직
	
	
// 	var consultTodayPush = function() {schedule.scheduleJob(todayRule, function(){
// 		connection.execute(sql_whoispost, [moment().format("YYYY-MM-DD")], (err, rows) => {
// 			if(err){
// 				console.error(err);
// 				next(err);
// 			}
// 			else
// 			{
// 				for(var i=0; i<rows.length; i++)
// 				{	
// 					const fcm_target_token = rows[i].token;
// 					console.log(fcm_target_token);
// 		 			const fcm_message = {
// 						token : fcm_target_token,
// 						notification : {
// 		 					title: '유한누리', 
// 							body: '오늘 상담 예약이 있습니다 !!' }
// 						};
					
// 					fcm_admin.messaging().send(fcm_message)
// 					.then(function(response){
// 			  			console.log('fcm보내기 성공');
// 			  		}).catch(function(error){
// 						console.log(error);
// 					});				
// 				}
// 			}
// 		});
	
// 	}); 
// };
// 	// -----------------1번--------------------
// 
	
	// 2. 예약이 신청 -> 승인 -> 예약이완료되었습니다.
	//'예약의 no가져오는 방식'
	// var reservationAcceptPush = function(reservationtokenno) {connection.execute(sql_AcceptedToken, [reservationtokenno], (err, rows) => {
	// 	if(err){
	// 			console.error(err);
	// 			next(err);
	// 	}
	// 	else
	// 	{
	// 		console.log(rows[0]);
	// 		const fcm_target_token = rows[0].token;
		
	// 		const fcm_message = {
	// 			token : fcm_target_token,
	// 			notification : {
	// 	 			title: 'yuhan1', 
	// 				body: '요청하신 예약이 수락되었습니다.',
	// 				//
	// 			},
	// 			data : {
	// 				click_action: 'FLUTTER_NOTIFICATION_CLICK',
	// 			}
	// 		}
			
	// 		fcm_admin.messaging().send(fcm_message)
	// 		.then(function(response){
	// 			console.log('fcm보내기 성공');
	// 		 }).catch(function(error){
	// 			console.log(error);
	// 		});
	// 	}
	// }); 
// };
			

	
	//----------------2--------------------------
	
	// 3.관리자가 문의에 대한 답변을 달았을 때
	
	// var answerPush = function(tokenno) {connection.execute(sql_notifyAnswer , [tokenno], (err, rows) => {
		
		
	// 		if(err){
	// 			console.error(err);
	// 			next(err);
	// 	}
	// 	else
	// 	{
	// 		console.log(rows[0]);
	// 		const fcm_target_token = rows[0].token;
		
	// 		const fcm_message = {
	// 			token : fcm_target_token,
	// 			notification : {
	// 	 			title: '유한누리', 
	// 				body: '문의하신 글에 답변이 달렸습니다.' }
	// 		};
					
	// 		fcm_admin.messaging().send(fcm_message)
	// 		.then(function(response){
	// 			console.log('fcm보내기 성공');
	// 		 }).catch(function(error){
	// 			console.log(error);
	// 		});	
	// 	}
		
		
		
	// });
// };
	
	//-----------------3----------------
	
	
	
	// 3. 만족도조사 참여 메시지
	
// 	var satisfactionPush = function(satisfactionNo){ connection.execute(sql_satisfaction, [satisfactionNo], (err, rows) => {
// 			if(err){
// 				console.error(err);
// 				next(err);
// 		}
// 		else
// 		{
// 			console.log(rows[0]);
// 			const fcm_target_token = rows[0].token;
		
// 			const fcm_message = {
// 				token : fcm_target_token,
// 				notification : {
// 		 			title: '유한누리', 
// 					body: '만족도조사에 참여해주세요!' }
// 			};
					
// 			fcm_admin.messaging().send(fcm_message)
// 			.then(function(response){
// 				console.log('fcm보내기 성공');
// 			 }).catch(function(error){
// 				console.log(error);
// 			});	
// 		}
// 	});
// };
	
	
	
	res.render('fcmEx');
	
});



module.exports = router;