const socket = require('socket.io');

const db = require('./database.js')();
const connection = db.init();

db.open(connection,'socket');

const moment = require('moment');
require('moment-timezone'); 
moment.tz.setDefault("Asia/Seoul");

module.exports = (server) => {	
	const io = socket(server, {
		cookie: false
	});
	
	io.of('/reservation').on('connection', function(socket) {
		socket.on('initPrivacy', function() {
			socket.emit('initPrivacy');
		});
		
		socket.on('initComplete', function(recvData) {
			let selectSimpleApplyForm = "SELECT MAX(serialno) AS serialno from SimpleApplyForm;";
			
			let insertSimpleApplyFormMental = "INSERT INTO SimpleApplyForm(serialno, stuno, stuname, gender, birth, email, date) " +
											  "VALUES(?, ?, ?, ?, ?, ?, CURDATE());";
			
			let insertReservationMental = "INSERT INTO Reservation(serialno, stuno) VALUES(?, ?);";
			
			let insertAnswerLogMental = "INSERT INTO AnswerLog(serialno, askno, choiceanswer) VALUES(?, ?, ?);";
			
			let insertPsyTest = "INSERT INTO PsyTest(serialno, testno) VALUES(?, ?);";
			
			let insertSimpleApplyFormConsult = "INSERT INTO SimpleApplyForm(serialno, stuno, stuname, gender, birth, email, date) " +
											   "VALUES(?, ?, ?, ?, ?, ?, CURDATE());";
			
			let insertReservationConsult = "INSERT INTO Reservation(serialno, stuno, empid, typeno, date, starttime) VALUES(?, ?, ?, ?, ?, ?);";
			
			let insertAnswerLogConsult = "INSERT INTO AnswerLog(serialno, askno, choiceanswer) VALUES(?, ?, ?);";
			
			let insertSelfCheck = "INSERT INTO SelfCheck(serialno, checkno, score) VALUES(?, ?, ?);";
			
			if(recvData.type == 1) {
				connection.execute(selectSimpleApplyForm, [], (err, result) => {
					if(err) console.error(err);
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
							if(insertSimpleApplyFormErr) console.error(insertSimpleApplyFormErr);
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
									if(insertReservationErr) console.error(insertReservationErr);
									else {
										for(let i=0; i<recvData.stuAnswer.length; i++) {
											connection.execute(insertAnswerLogConsult, [serialno, recvData.stuAnswer[i].question, recvData.stuAnswer[i].answer], (insertAnswerLogErr) => {
												if(insertAnswerLogErr) console.error(insertAnswerLogErr);
											});
										}
										
										for(let i=0; i<recvData.selfcheckCode.split(',').length; i++) {
											connection.execute(insertSelfCheck, [serialno, recvData.selfcheckCode.split(',')[i], recvData.selfcheckNum.split(',')[i]], (insertSelfCheckErr) => {
												if(insertSelfCheckErr) console.error(insertSelfCheckErr);
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
			else if(recvData.type == 2) {
				connection.execute(selectSimpleApplyForm, [], (err, result) => {
					if(err) console.error(err);
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
							if(insertSimpleApplyFormErr) console.error(insertSimpleApplyFormErr);
							else {
								connection.execute(insertReservationMental, [serialno, recvData.stuCode], (insertReservationErr) => {
									if(insertReservationErr) console.error(insertReservationErr);
									else {
										for(let i=0; i<recvData.stuAnswer.length; i++) {
											connection.execute(insertAnswerLogMental, [serialno, recvData.stuAnswer[i].question, recvData.stuAnswer[i].answer], (insertAnswerLogErr) => {
												if(insertAnswerLogErr) console.error(insertAnswerLogErr);
											});
										}
										
										for(let i=0; i<recvData.psyTestList.split(',').length; i++) {
											connection.execute(insertPsyTest, [serialno, recvData.psyTestList.split(',')[i]], (insertPsyTestErr) => {
												if(insertPsyTestErr) console.error(insertPsyTestErr);
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
			let selectCounselor = "SELECT empname, empid FROM Counselor WHERE positionno=1";

			connection.execute(selectCounselor, [], (err, rows) => {
				if(err) console.error(err);
				else socket.emit('initReservation', rows);
			});
		});
		
		socket.on('selectCounselor', function(empid) {
			let selectCounselor = "SELECT DISTINCT(DATE(start)) AS possible FROM Schedule WHERE empid=? AND DATE(start) > CURDATE() AND calendarId='Reservation';";

			connection.execute(selectCounselor, [empid], (err, rows) => {
				if(err) console.error(err);
				else socket.emit('selectCounselor', rows);
			});
		});
		
		socket.on('selectDateTime', function(requestTime) {
			const getCanCounselTime = "SELECT scheduleno, HOUR(start) as start, HOUR(end) as end FROM Schedule WHERE calendarId='Reservation' AND DATE(START)=? AND empid=?;";
			
			let scheduled_time = [];
			
			connection.execute(getCanCounselTime, [requestTime.date, requestTime.empid], (err, rows) => {
				if (err) console.error(err);
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
			let selectSelfCheck = "SELECT checkno, checkname FROM SelfCheckList s WHERE s.use='Y';";

			connection.execute(selectSelfCheck, [], (err, rows) => {
				if(err) console.error(err);
				else socket.emit('initSelfcheck', rows);
			});
		});
	});
	
	io.of('/chat').on('connection', function(socket) {
		let myroom = "";
		
		socket.on('open', function(info) {
			socket.name = info.empname;
			socket.join(info.empno);
			
			myroom = info.empno
		});
		
		socket.on('join', function(info) {
			socket.name = info.name;
			socket.code = info.code;
			
			socket.join(info.empno);
			myroom = info.empno
			
			socket.broadcast.to(info.empno).emit('join', {name: info.name, code: info.code});
		});
		
		socket.on('msg', function(msg) {
			let data = {
				name: socket.name,
				msg: msg
			}
			
			socket.broadcast.to(myroom).emit('msg', data);
		});
		
		// force client disconnect from server
		socket.on('forceDisconnect', function() {
			socket.disconnect();
		});
		
		socket.on('disconnect', function() {
			socket.broadcast.to(myroom).emit('exit', {name: socket.name, code: socket.code});
		});
	});
}
