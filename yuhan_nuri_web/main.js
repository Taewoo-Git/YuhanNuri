const port = 3000;

const express = require('express');
const app = express();

const session = require('express-session');
const dotenv = require('dotenv');

const userRouter = require('./routes/user');

dotenv.config();

app.set('views', __dirname + '/views');
app.set('view engine', 'ejs');

app.engine('html', require('ejs').renderFile);

app.use(express.static(__dirname + '/public'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

app.use(session({ secret: process.env.COOKIE_SECRET, resave: false, saveUninitialized: false}));

app.use('/user', userRouter);

const server = app.listen(port, () => {
    console.log('Listening on port ' + port + '\n');
});

const io = require('socket.io')(server, {
    cookie: false
});

app.get('/', function (req, res) {
	res.render('login');
});

app.get('/main', function (req, res) { //Mr.애매모호
    console.log('Session', req.session);
    res.render('main', {
        username: req.session.userInfo.stuName,
    });
});

app.get('/chat', function (req, res) {
	res.render('chat', {
        username: req.session.userInfo.stuName,
    });
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

//유저에 관련된 정보들은 routes/user.js에 넣어 놓았습니다!
