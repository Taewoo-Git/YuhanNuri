const db = require('./database.js')();
const connection = db.init();
db.open(connection, "schedule");

const schedule = require('node-schedule');

const moment = require('moment');
require('moment-timezone'); 
moment.tz.setDefault("Asia/Seoul");

// 채팅 한달 뒤 삭제
exports.deleteOneMonth = ()=> { 
	let deleteRule = new schedule.RecurrenceRule();
	deleteRule.dayOfWeek = [0, new schedule.Range(0,6)];
	deleteRule.hour= 00;
	deleteRule.minute= 00;
	const sql_deleteQuestionAfterOneMonth="delete from QuestionBoard where answerdate<=?"; // 하루에 한번 현재 날짜에서 30일 이전의 문의 데이터를 지웁니다.
	const sql_deleteSimpleApplyFormAfterOneMonth="delete from SimpleApplyForm where date <= ?"; // 하루에 한번 현재 날짜에서 30일 이전의 상담 신청서 데이터를 지웁니다.
	const sql_deleteConsultLogAfterOneMonth = "delete from ConsultLog where date <= ?";
	
	schedule.scheduleJob(deleteRule, function(){ 
		// connection.execute(sql_deleteQuestionAfterOneMonth, [moment().subtract(1, 'months').format("YYYY-MM-DD")], (err, rows) => {
		// 	if(err){
		// 		console.error(err);
		// 		next(err);
		// 	} 
		// 	console.log('문의 데이터 삭제');
		// });
		
		connection.execute(sql_deleteSimpleApplyFormAfterOneMonth, [moment().subtract(1, 'months').format("YYYY-MM-DD")], (err, rows) => {
			if(err){
				console.error(err);
				next(err);
				
			}
			console.log('상담 신청서 데이터 삭제');
		});
		
		connection.execute(sql_deleteConsultLogAfterOneMonth,[moment().subtract(1,'months').format("YYYY-MM-DD")],(err,rows) => {
			if(err){
				console.error(err);
			}
			console.log('채팅 데이터 삭제');
		})
	});
	
}

// 상담 및 심리검사 신청서, 만족도 조사 5년 뒤 삭제
exports.deleteFiveYear = () => {
	let deleteRule = new schedule.RecurrenceRule();
	deleteRule.dayOfWeek = [0, new schedule.Range(0,6)];
	deleteRule.hour= 00;
	deleteRule.minute= 00;
	// 사용하지 않는 질문들(ask.use = N)을 삭제
	const sql_deleteSatisfaction = "DELETE FROM AskList AS ask,AnswerLog AS answer WHERE ask.askno = answer.askno AND ask.typeno = 3 AND where date <= ? AND ask.use = N"; 
	const sql_deleteSelfCheck = "DELETE FROM AskList AS ask,AnswerLog AS answer WHERE ask.askno = answer.askno AND ask.typeno = 2 AND where date <= ? AND ask.use = N"; 
	const sql_deleteReservation = "DELETE FROM AskList AS ask,AnswerLog AS answer WHERE ask.askno = answer.askno AND ask.typeno = 1 AND where date <= ? AND ask.use = N"; 
	
	// console.log(moment().subtract(5,'years').format('YYYY-MM-DD')); 날짜 테스트
	schedule.scheduleJob(deleteRule, function(){ 
		console.log('DELETE : 상담 및 심리검사 신청서, 만족도 조사 5년 누적');
		connection.execute(sql_deleteSatisfaction, [moment().subtract(5, 'years').format("YYYY-MM-DD")], (err, rows) => { //만족도 조사
			if(err){
				console.error(err);
				next(err);
			} 
		});
		connection.execute(sql_deleteSelfCheck, [moment().subtract(5, 'years').format("YYYY-MM-DD")], (err, rows) => { // 심리 검사
			if(err){
				console.error(err);
				next(err);
			} 
		});
		connection.execute(sql_deleteReservation, [moment().subtract(5, 'years').format("YYYY-MM-DD")], (err, rows) => { // 상담 예약
			if(err){
				console.error(err);
				next(err);
			} 
		});
	});
}