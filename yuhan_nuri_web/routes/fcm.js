const db = require('../public/res/js/database.js')();
const connection = db.init();

db.open(connection,'fcm');

const sql_whoispost = "SELECT User.token FROM Reservation, User WHERE Reservation.date = ? AND User.stuno = Reservation.stuno AND Reservation.status = 1";
const sql_AcceptedToken= "SELECT token FROM User WHERE stuno = (select stuno FROM Reservation WHERE serialno = ?)"; 
const sql_notifyAnswer = "SELECT token FROM User WHERE stuno = (select stuno FROM QuestionBoard WHERE no =?)";
const sql_satisfaction = "SELECT token FROM User WHERE stuno = (select stuno FROM Reservation WHERE serialno = ?)";	
const fcm_admin = require('firebase-admin');

var serviceAccount = require('../serviceAccountCredentials.json');
fcm_admin.initializeApp({
	credential: fcm_admin.credential.cert(serviceAccount),
});

const schedule = require('node-schedule');

var everule = new schedule.RecurrenceRule();
everule.dayOfWeek = [0, new schedule.Range(0,6)];
everule.hour= 18;
everule.minute= 00;

var todayRule = new schedule.RecurrenceRule();
todayRule.dayOfWeek = [0, new schedule.Range(0,6)];
todayRule.hour= 08;
todayRule.minute= 00;

const moment = require('moment');
require('moment-timezone'); 
moment.tz.setDefault("Asia/Seoul");

exports.consultTomorrowPush = ()=> {
	schedule.scheduleJob(everule, function(){
		connection.execute(sql_whoispost, [moment().add(1, 'd').format("YYYY-MM-DD")], (err, rows) => {
			if(err){
				console.error(err);
				// next(err);
			}
			else{
				for(var i=0; i<rows.length; i++){	
					const fcm_target_token = rows[i].token;
					const fcm_message = {
						token: fcm_target_token,
						notification: {
							title: '유한누리', 
							body: '상담 하루 전입니다.',
						},
						data: {
							click_action: 'FLUTTER_NOTIFICATION_CLICK',
							page: 'mypage'
						}
					};
					fcm_admin.messaging().send(fcm_message)
						.then(function(response){
					})
						.catch(function(error){
						console.error(error);
					});
				}
			}
		});
	});
}
	
exports.reservationAcceptPush = (reservationNumber) => {
	connection.execute(sql_AcceptedToken, [reservationNumber], (err, rows) => {
		if(err){
			console.error(err);
			// next(err); 
		}
		else{
			const fcm_target_token = rows[0].token;
			const fcm_message = {
				token: fcm_target_token,
				notification: {
					title: '유한누리', 
					body: '요청하신 예약이 수락되었습니다.',
				},
				data: {
					click_action: 'FLUTTER_NOTIFICATION_CLICK',
					page: 'mypage'
				}
			};
			fcm_admin.messaging().send(fcm_message)
				.then(function(response){
			})
				.catch(function(error){
				console.error(error);
			});
		}
	}); 
}
	
exports.consultTodayPush = ()=> {
	schedule.scheduleJob(todayRule, function(){
		connection.execute(sql_whoispost, [moment().format("YYYY-MM-DD")], (err, rows) => {
			if(err){
				console.error(err);
				// next(err);
			}
			else{
				for(var i=0; i<rows.length; i++){	
					const fcm_target_token = rows[i].token;
					const fcm_message = {
						token: fcm_target_token,
						notification: {
							title: '유한누리', 
							body: '오늘 상담 예약이 있습니다.' ,
						},
						data: {
							data: {
								click_action: 'FLUTTER_NOTIFICATION_CLICK',
								page: 'mypage'
							}
						}
					};
					fcm_admin.messaging().send(fcm_message)
						.then(function(response){
					})
						.catch(function(error){
						console.error(error);
					});
				}
			}
		});
	});
}

exports.answerPush = (tokenno)=>{
	connection.execute(sql_notifyAnswer, [tokenno], (err, rows) => {	
		if(err){
			console.error(err);
			// next(err);
		}
		else{
			const fcm_target_token = rows[0].token;
			const fcm_message = {
				token : fcm_target_token,
				notification : {
		 			title: '유한누리', 
					body: '문의하신 글에 답변이 작성되었습니다.',
				},
				data : {
					click_action: 'FLUTTER_NOTIFICATION_CLICK',
					page : 'question'
				}
			};
			fcm_admin.messaging().send(fcm_message)
				.then(function(response){
			})
				.catch(function(error){
				console.error(error);
			});	
		}
	});
};

exports.satisfactionPush = (satisfactionNo)=>{
	connection.execute(sql_satisfaction, [satisfactionNo], (err, rows) => {
		if(err){
			console.error(err);
			// next(err);
		}
		else{
			const fcm_target_token = rows[0].token;
			const fcm_message = {
				token: fcm_target_token,
				notification: {
		 			title: '유한누리', 
					body: '만족도 조사에 참여해 주세요.',
				},
				data: {
					click_action: 'FLUTTER_NOTIFICATION_CLICK',
					page: 'satisfaction'
				}
			};
			fcm_admin.messaging().send(fcm_message)
				.then(function(response){
			 })
				.catch(function(error){
				console.error(error);
			});	
		}
	});
};
	