const port = 3000;

const express = require('express');
const app = express();

const session = require('express-session');
const dotenv = require('dotenv');

const userRouter = require('./routes/user');
const chatRouter = require('./routes/chat');

const cookieParser = require('cookie-parser');

dotenv.config();

app.set('views', __dirname + '/views');
app.set('view engine', 'ejs');

app.engine('html', require('ejs').renderFile);

app.use(express.static(__dirname + '/public'));
app.use(express.json())
app.use(express.urlencoded({ extended: false }));

app.use(session({ secret: process.env.COOKIE_SECRET, resave: false, saveUninitialized: false}));
app.use(cookieParser('vaCzbAVeMy9pT7Uw'));

app.use('/user', userRouter);
app.use('/chat', chatRouter);

const server = app.listen(port, () => {
    console.log('Listening on port ' + port + '\n');
});

const io = require(__dirname + '/public/res/js/socket.js')(server); // socket.js파일에 server를 미들웨어로 사용

app.get('/', function (req, res) {
	let isInfo = req.session.userInfo; // 기존 세션의 존재 여부를 판단하여 view 처리.
	
	if(isInfo) {
		res.render('main', {
			username: isInfo.stuName
		});
	}
	else if(req.signedCookies.AutoLogin) res.redirect('/user/auto');
	else res.render('login');
});

app.get('/main', function (req, res) {
    res.render('main', {
        username: req.session.userInfo.stuName
    });
});
