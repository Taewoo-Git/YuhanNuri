const socket = require('socket.io');

const db = require('./database.js')();
const connection = db.init();

db.open(connection,'socket');

module.exports = (server) => {	
	const io = socket(server, {
		cookie: false
	});
	
	io.of('/reservation').on('connection', function(socket) {
		socket.on('initPrivacy', function() {
			console.log("privacy!");

			socket.emit('initPrivacy');
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
