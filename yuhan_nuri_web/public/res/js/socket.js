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
			
			let insertSimpleApplyForm = "INSERT INTO SimpleApplyForm(typeno, stuno, stuname, gender, age, email, data) " +
										"VALUES(?, ?, ?, ?, ?, ?, ?);";
			
			let insertReservation = "INSERT INTO Reservation(no, typecode, stuno, empno, date, starttime, agree, status, finished) " +
									"VALUES(?, ?, ?, ?, ?, ?, 1, 0, 0);";
			
			let insertSelfCheck = "INSERT INTO SelfCheck(typeno, stuno, data) VALUES(?, ?, ?);"
			
			let simpleApplyFormData = [
				recvData.type,
				recvData.stuCode,
				recvData.stuName,
				recvData.stuGender,
				recvData.stuBirth,
				recvData.stuEmail,
				recvData.stuAnswer
			];
			
			let reservationData = [
				parseInt(recvData.reservationCode),
				recvData.stuCode,
				recvData.empno,
				recvData.date,
				parseInt(recvData.time)
			];
			
			let selfCheck = [
				recvData.type,
				recvData.stuCode,
				recvData.selfcheck
				
			];
			
			connection.execute(insertSimpleApplyForm, simpleApplyFormData, (err) => {
				if(err) console.error(err);
				else {
					if(recvData.type === 5) socket.emit('initComplete');
					else if(recvData.type === 4) {
						let serialCheck = `select no+1 as 'serial' from Reservation where no like '${new moment().format("YYYYMMDD")}%' order by no desc limit 1;`;
						connection.execute(serialCheck, [], (err, result) => {
							if(err) console.error(err);
							else {					
								if(result.length > 0) reservationData.splice(0, 0, result[0].serial);
								else reservationData.splice(0, 0, `${new moment().format("YYYYMMDD")}0001`);
								
								connection.execute(insertReservation, reservationData, (err) => {
									if(err) console.error(err);
									else {
										connection.execute(insertSelfCheck, selfCheck, (err) => {
											if(err) console.error(err);
											else {
												socket.emit('initComplete');
											}
										});
									}
								});
								
							}
						});
					}
				}
			});
			
		});
		
		socket.on('initReservation', function() {
			let selectCounselor = "SELECT empname, empno FROM Counselor WHERE position='counselor'";

			connection.execute(selectCounselor, [], (err, rows) => {
				if(err) console.error(err);
				else socket.emit('initReservation', rows);
			});
		});
		
		socket.on('selectCounselor', function(empno) {
			let selectCounselor = "SELECT DISTINCT(DATE(start)) AS possible FROM Schedule WHERE empno=? " +
				"AND DATE(start) > (CURDATE() + INTERVAL 1 DAY)";

			connection.execute(selectCounselor, [empno], (err, rows) => {
				if(err) console.error(err);
				else socket.emit('selectCounselor', rows);
			});
		});
		
		socket.on('selectDateTime', function(requestTime) {
			const getCanCounselTime = "SELECT id, HOUR(start) as start, HOUR(end) as end " +
									"FROM Schedule WHERE calendarId = 'Reservation' AND DATE(start) = ? AND empno = ?";
			
			const getUsedScheduleTime = "SELECT HOUR(start) as start FROM UsedSchedule WHERE id = ?";
			
			let schedule_id = "";
			let scheduled_time = [];

			let usedScheduled_time = [];
			let canCounselTimes = [];
			let scheduleCount = 0;
			
			connection.execute(getCanCounselTime, [requestTime.date, requestTime.empno], (err, rows) => {
				if (err) console.error(err);
				else if(rows.length !== 0) {
					scheduleCount = rows.length;

					rows.forEach((row, index) => {
						schedule_id = row.id;
						for(let time = row.start; time <= row.end; time++) {
							scheduled_time.push(time);
						}

						connection.execute(getUsedScheduleTime, [schedule_id], (err, rows) => {
							if(err) console.error(err);
							else{
								rows.forEach((item, index) => {
									usedScheduled_time.push(item.start);
								});

								let rtn = scheduled_time.filter((item) => !usedScheduled_time.includes(item));

								if(index+1 === scheduleCount) socket.emit('returnTime', rtn)
							}
						});
					});
				}
			});
		});
		
		socket.on('initSelfcheck', function(empno) {
			let selectSelfCheck = "SELECT content FROM EditTest WHERE empno=? AND type='자가진단'";

			connection.execute(selectSelfCheck, [empno], (err, rows) => {
				if(err) console.error(err);
				else socket.emit('initSelfcheck', JSON.parse(rows[0].content));
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
