const db = require('./database.js')();
const connection = db.init();
db.open(connection, "schedule");

const schedule = require('node-schedule');

const moment = require('moment');
require('moment-timezone'); 
moment.tz.setDefault("Asia/Seoul");

const ErrorLogger = require('./ErrorLogger.js');
const logTimeFormat = "YYYY-MM-DD HH:mm:ss";

// 채팅 내역 한달 뒤 삭제
exports.deleteOneMonth = () => { 
	let deleteRule = new schedule.RecurrenceRule();
	deleteRule.dayOfWeek = [0, new schedule.Range(0, 6)];
	deleteRule.hour = 00;
	deleteRule.minute = 00;
	
	const sql_deleteConsultLogAfterOneMonth = "delete from ConsultLog where chatdate <= ?";
	
	schedule.scheduleJob(deleteRule, function() {
		connection.execute(sql_deleteConsultLogAfterOneMonth, [moment().subtract(1, 'months').format("YYYY-MM-DD")], (err, rows) => { // 채팅 내역
			if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
		})
	});
}

// 상담 및 심리검사 신청서, 모든 예약 및 만족도 조사 5년 뒤 삭제
exports.deleteFiveYear = () => {
	let deleteRule = new schedule.RecurrenceRule();
	deleteRule.dayOfWeek = [0, new schedule.Range(0, 6)];
	deleteRule.hour = 00;
	deleteRule.minute = 00;
	
	const sql_deleteSimpleApplyForm = "DELETE FROM SimpleApplyForm WHERE date <= ?";
	
	//console.log(moment().subtract(5, 'years').format('YYYY-MM-DD')); 날짜 테스트
	schedule.scheduleJob(deleteRule, function() {
		connection.execute(sql_deleteSimpleApplyForm, [moment().subtract(5, 'years').format("YYYY-MM-DD")], (err, rows) => {
			if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
		});
	});
}