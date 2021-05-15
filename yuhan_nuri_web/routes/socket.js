const socket = require('socket.io');

const db = require('./database.js')();
const connection = db.init();

db.open(connection,'socket');

const moment = require('moment');
require('moment-timezone');
moment.tz.setDefault("Asia/Seoul");

const logger = require('./logger.js');
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
				if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
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
				if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
				else {
					if(rows[0] === undefined) socket.emit('outError');
					else {
						connection.execute(selectLog, [rows[0].serialno], (selectLogErr, selectLogRows) => {
							if(selectLogErr) logger.error.info(`[${moment().format(logTimeFormat)}] ${selectLogErr}`);
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
				if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
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
				if(err) logger.error.info(`[${moment().format(logTimeFormat)}] ${err}`);
				else {
					connection.execute(selectLog, [rows[0].serialno], (selectLogErr, selectLogRows) => {
						if(selectLogErr) logger.error.info(`[${moment().format(logTimeFormat)}] ${selectLogErr}`);
						else if(selectLogRows.length != 0) {
							connection.execute(updateLog, [data.log, rows[0].serialno], (updateLogErr, updateLogRows) => {
								if(updateLogErr) logger.error.info(`[${moment().format(logTimeFormat)}] ${updateLogErr}`);
							});
						}
						else {
							connection.execute(insertLog, [rows[0].serialno, data.log], (insertLogErr, insertLogRows) => {
								if(insertLogErr) logger.error.info(`[${moment().format(logTimeFormat)}] ${insertLogErr}`);
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
