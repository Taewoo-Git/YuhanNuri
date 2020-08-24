const socket = require('socket.io');

module.exports = (server) => {
	const io = socket(server,{
		cookie: false
	});
	
	io.on('connection', function(socket) {
		socket.on('login', function(username) {
			socket.name = username;
			console.info("User Chat Login :", socket.name);
		});
		
		socket.on('msg', function(msg) {
			let data = {
				name: socket.name,
				msg: msg
			}
			socket.broadcast.emit('msg', data);
		});
		
		//console.info(socket);
	});
}
