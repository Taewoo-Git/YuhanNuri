const socket = require('socket.io');

const db = require('./database.js')();
const connection = db.init();

db.open(connection,'socket');

const moment = require('moment');
require('moment-timezone');
moment.tz.setDefault("Asia/Seoul");

const ErrorLogger = require('./logger_error.js');
const logTimeFormat = "YYYY-MM-DD HH:mm:ss";

module.exports = (server) => {	
	const io = socket(server, {
		cookie: false
	});
	
	let reaction = io.of('/reaction');
	
	reaction.on('connection', function(socket) {
		socket.on('cancel', function(serialno) {
			reaction.emit('cancel', serialno);
		});
		
		socket.on('confirm', function(serialno) {
			reaction.emit('confirm', serialno);
		});
	});
	
	io.of('/reservation').on('connection', function(socket) {
		socket.on('initPrivacy', function() {
			socket.emit('initPrivacy');
		});
		
		socket.on('initComplete', function(recvData) {
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
			
			if(recvData.type == 1) {
				connection.execute(selectSimpleApplyForm, [], (err, result) => {
					if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
					else {
						let serialno = 0;
						
						if(result.length == 0) serialno = 1;
						else if(result.length > 0) serialno = result[0].serialno + 1;
						
						let simpleApplyFormData = [
							serialno,
							recvData.stuCode,
							recvData.stuName,
							recvData.stuGender,
							recvData.stuBirth,
							recvData.stuEmail
						];
						
						connection.execute(insertSimpleApplyFormConsult, simpleApplyFormData, (insertSimpleApplyFormErr) => {
							if(insertSimpleApplyFormErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${insertSimpleApplyFormErr}`);
							else {
								let reservationDate = [
									serialno,
									recvData.stuCode,
									recvData.empid,
									recvData.reservationCode,
									recvData.date,
									recvData.time
								];
								connection.execute(insertReservationConsult, reservationDate, (insertReservationErr) => {
									if(insertReservationErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${insertReservationErr}`);
									else {
										for(let i = 0; i < recvData.stuAnswer.length; i++) {
											connection.execute(insertAnswerLogConsult, [serialno, recvData.stuAnswer[i].question, recvData.stuAnswer[i].answer], (insertAnswerLogErr) => {
												if(insertAnswerLogErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${insertAnswerLogErr}`);
											});
										}
										
										if(recvData.selfcheckCode !== "") {
											for(let i = 0; i < recvData.selfcheckCode.split(',').length; i++) {
												connection.execute(insertSelfCheck, [serialno, recvData.selfcheckCode.split(',')[i], recvData.selfcheckNum.split(',')[i]], (insertSelfCheckErr) => {
													if(insertSelfCheckErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${insertSelfCheckErr}`);
												});
											}
										}
										socket.emit('initComplete');
									}
								});
							}
						});
					}
				});
			}
			else if(recvData.type == 2) {
				connection.execute(selectSimpleApplyForm, [], (err, result) => {
					if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
					else {
						let serialno = 0;
						
						if(result.length == 0) serialno = 1;
						else if(result.length > 0) serialno = result[0].serialno + 1;
						
						let simpleApplyFormData = [
							serialno,
							recvData.stuCode,
							recvData.stuName,
							recvData.stuGender,
							recvData.stuBirth,
							recvData.stuEmail
						];
						
						connection.execute(insertSimpleApplyFormMental, simpleApplyFormData, (insertSimpleApplyFormErr) => {
							if(insertSimpleApplyFormErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${insertSimpleApplyFormErr}`);
							else {
								connection.execute(insertReservationMental, [serialno, recvData.stuCode], (insertReservationErr) => {
									if(insertReservationErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${insertReservationErr}`);
									else {
										for(let i = 0; i < recvData.stuAnswer.length; i++) {
											connection.execute(insertAnswerLogMental, [serialno, recvData.stuAnswer[i].question, recvData.stuAnswer[i].answer], (insertAnswerLogErr) => {
												if(insertAnswerLogErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${insertAnswerLogErr}`);
											});
										}
										
										for(let i = 0; i < recvData.psyTestList.split(',').length; i++) {
											connection.execute(insertPsyTest, [serialno, recvData.psyTestList.split(',')[i]], (insertPsyTestErr) => {
												if(insertPsyTestErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${insertPsyTestErr}`);
											});
										}
										
										socket.emit('initComplete');
									}
								});
							}
						});
					}
				});
			}
		});
		
		socket.on('initReservation', function() {
			let selectCounselor = "SELECT empname, empid FROM Counselor WHERE positionno = 1 AND Counselor.use = 'Y'";

			connection.execute(selectCounselor, [], (err, rows) => {
				if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
				else socket.emit('initReservation', rows);
			});
		});
		
		socket.on('selectCounselor', function(empid) {
			let selectCounselor = "SELECT DISTINCT(DATE(start)) AS possible FROM Schedule WHERE empid = ? AND DATE(start) > CURDATE() AND calendarId = 'Reservation'";

			connection.execute(selectCounselor, [empid], (err, rows) => {
				if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
				else socket.emit('selectCounselor', rows);
			});
		});
		
		socket.on('selectDateTime', function(requestTime) {
			const getCanCounselTime = "SELECT scheduleno, HOUR(start) as start, HOUR(end) as end FROM Schedule WHERE calendarId='Reservation' AND DATE(START) = ? AND empid = ?";
			
			let scheduled_time = [];
			
			connection.execute(getCanCounselTime, [requestTime.date, requestTime.empid], (err, rows) => {
				if (err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
				else if(rows.length !== 0) {
					scheduleCount = rows.length;
					
					rows.forEach((row, index) => {
						for(let time = row.start; time < row.end; time++) {
							scheduled_time.push(time);
						}
					});
						
					socket.emit('returnTime', scheduled_time);
				}
			});
		});
		
		socket.on('initSelfcheck', function() {
			let selectSelfCheck = "SELECT checkno, checkname FROM SelfCheckList s WHERE s.use = 'Y'";

			connection.execute(selectSelfCheck, [], (err, rows) => {
				if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
				else socket.emit('initSelfcheck', rows);
			});
		});
	});
	
	let waitingStudentName = [];
	let waitingStudentCode = [];
	io.of('/chat').on('connection', function(socket) {
		socket.on('open', function(info) {
			socket.name = info.empname;
			socket.join(info.empid);
			socket.myroom = info.empid
			
			if(waitingStudentName[socket.myroom]) {
				socket.emit('waiting', waitingStudentName[socket.myroom]);
			}
		});
		
		socket.on('waiting', function(info) {
			socket.broadcast.to(info.empid).emit('waiting', info.name);
			
			socket.name = info.name;
			socket.code = info.code;
			socket.join(info.empid);
			socket.myroom = info.empid;
			
			let selectUser = "SELECT major, phonenum, birth FROM User WHERE stuno = ?";

			connection.execute(selectUser, [socket.code], (err, rows) => {
				if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
				else {
					socket.major = rows[0].major;
					socket.phone = rows[0].phonenum;

					if(parseInt(new Date().getFullYear().toString().substring(2, 4)) > parseInt(rows[0].birth.substring(0, 2)))
						socket.birth = "20" + rows[0].birth.substring(0, 2) + "-" + rows[0].birth.substring(2, 4) + "-" + rows[0].birth.substring(4, 6);
					else
						socket.birth = "19" + rows[0].birth.substring(0, 2) + "-" + rows[0].birth.substring(2, 4) + "-" + rows[0].birth.substring(4, 6);
				}
			});
			
			waitingStudentName[socket.myroom] = socket.name;
			waitingStudentCode[socket.myroom] = socket.code;
		});
		
		socket.on('okay', function() {
			let selectSerialno = "SELECT serialno FROM Reservation WHERE stuno = ? AND empid = ? AND date = CURDATE() ORDER BY serialno DESC";
			let selectLog = "SELECT chatlog FROM ConsultLog WHERE serialno = ?";
			
			connection.execute(selectSerialno, [waitingStudentCode[socket.myroom], socket.myroom], (err, rows) => {
				if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
				else {
					if(rows[0] === undefined) socket.emit('outError');
					else {
						connection.execute(selectLog, [rows[0].serialno], (selectLogErr, selectLogRows) => {
							if(selectLogErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${selectLogErr}`);
							else if(selectLogRows.length != 0) socket.broadcast.to(socket.myroom).emit('okay', selectLogRows[0].chatlog);
							else socket.broadcast.to(socket.myroom).emit('okay', null);
						});
					}
				}
			});
		});
		
		socket.on('join', function() {
			let selectSerialno = "SELECT serialno FROM Reservation WHERE stuno = ? AND empid = ? AND date=CURDATE() ORDER BY serialno DESC";
			let selectLog = "SELECT chatlog FROM ConsultLog WHERE serialno = ?";
			
			connection.execute(selectSerialno, [socket.code, socket.myroom], (err, rows) => {
				if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
				else {
					connection.execute(selectLog, [rows[0].serialno], (selectLogErr, selectLogRows) => {
						if(selectLogRows.length != 0) socket.broadcast.to(socket.myroom).emit('join', {stuinfo: {
							serialno: rows[0].serialno,
							name: socket.name,
							code: socket.code,
							major: socket.major,
							phone: socket.phone,
							birth: socket.birth
						}, chatlog: selectLogRows[0].chatlog});
						else socket.broadcast.to(socket.myroom).emit('join', {stuinfo: {
							serialno: rows[0].serialno,
							name: socket.name,
							code: socket.code,
							major: socket.major,
							phone: socket.phone,
							birth: socket.birth
						}, chatlog: null});
					});
				}
			});
		});
		
		socket.on('finish', function() {
			socket.broadcast.to(socket.myroom).emit('finish');
		});
		
		socket.on('msg', function(msg) {
			let data = {
				name: socket.name,
				msg: msg
			}
			
			if(socket.code) {
				data.stuno = socket.code;
				data.major = socket.major;
				data.phone = socket.phone;
				data.birth = socket.birth;
			}
			
			socket.broadcast.to(socket.myroom).emit('msg', data);
		});
		
		socket.on('logging', function(data) {
			let selectSerialno = "SELECT serialno FROM Reservation WHERE stuno = ? AND empid=? AND date = CURDATE() ORDER BY serialno DESC";
			
			let selectLog = "SELECT * FROM ConsultLog WHERE serialno = ?";
			
			let updateLog = "UPDATE ConsultLog SET chatlog=CONCAT(chatlog, ?), chatdate=CURDATE() WHERE serialno = ?";
			
			let insertLog = "INSERT INTO ConsultLog(serialno, chatlog, chatdate) VALUES(?, ?, CURDATE())";

			connection.execute(selectSerialno, [data.stuno, data.empid], (err, rows) => {
				if(err) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${err}`);
				else {
					connection.execute(selectLog, [rows[0].serialno], (selectLogErr, selectLogRows) => {
						if(selectLogErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${selectLogErr}`);
						else if(selectLogRows.length != 0) {
							connection.execute(updateLog, [data.log, rows[0].serialno], (updateLogErr, updateLogRows) => {
								if(updateLogErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${updateLogErr}`);
							});
						}
						else {
							connection.execute(insertLog, [rows[0].serialno, data.log], (insertLogErr, insertLogRows) => {
								if(insertLogErr) ErrorLogger.info(`[${moment().format(logTimeFormat)}] ${insertLogErr}`);
							});
						}
					});
				}
			});
		});
		
		// force client disconnect from server
		socket.on('forceDisconnect', function() {
			socket.disconnect();
		});
		
		socket.on('disconnect', function() {
			if(socket.code) {
				socket.broadcast.to(socket.myroom).emit('exit', {name: socket.name, code: socket.code});
				if(waitingStudentCode[socket.myroom] == socket.code) {
					waitingStudentName[socket.myroom] = null;
					waitingStudentCode[socket.myroom] = null;
				}
			}
		});
	});
}
