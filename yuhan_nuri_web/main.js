let server;

const express = require('express');
const app = express();

const http = require('http');
const https = require('https');
const options = process.env.NODE_ENV === "production" ? require('./security.js')() : undefined;

const session = require('express-session');
const dotenv = require('dotenv');
const path = require('path');

const helmet = require('helmet');

const user = require('./routes/user');
const admin = require('./routes/admin');

const {DeleteOneMonth, DeleteFiveYear} = require('./routes/schedule');
const {ConsultTodayPush, ConsultTomorrowPush} = require('./routes/fcm');

const cookieParser = require('cookie-parser');

const schedule = require('node-schedule');

const moment = require('moment');
require('moment-timezone'); 
moment.tz.setDefault("Asia/Seoul");

const db = require('./routes/database.js')();
const connection = db.init();

const Logger = require('./routes/logger.js');
const logTimeFormat = "YYYY-MM-DD HH:mm:ss";

const favicon = require('serve-favicon');
app.use(favicon(path.join(__dirname, 'public/res/imgs', 'favicon.ico')));

db.open(connection, 'main');

dotenv.config();

app.set('views', __dirname + '/views');
app.set('view engine', 'ejs');

app.engine('html', require('ejs').renderFile);

app.use(express.static(__dirname + '/public'));
app.use('/js', express.static(path.join(__dirname, '/public/res/js')));
app.use('/lib', express.static(path.join(__dirname, '/public/res/lib')));
app.use('/css', express.static(path.join(__dirname, '/public/res/css')));
app.use('/images', express.static(path.join(__dirname,'/public/res/imgs')));

app.use('/uploads', express.static(path.join(__dirname,'/uploads')));

app.use(express.json());
app.use(express.urlencoded({extended: false}));

app.use(session({secret: process.env.SESSION_SECRET, resave: false, saveUninitialized: false}));
app.use(cookieParser(process.env.COOKIE_SECRET));

app.use(helmet({
	contentSecurityPolicy: false,
}));

// helmet 미들웨어에는 이런 기능들을 통해 보안을 설정 합니다. 어느정도 타협해야하는 보안 수준이 있다면 말씀해 주시면 빼도록 하겠습니다
// csp: Content-Security-Policy 헤더 설정. XSS(Cross-site scripting) 공격 및 기타 교차 사이트 인젝션 예방.
// hidePoweredBy: X-Powered-By 헤더 제거.
// hpkp: Public Key Pinning 헤더 추가. 위조된 인증서를 이용한 중간자 공격 방지.
// hsts: SSL/TLS를 통한 HTTP 연결을 적용하는 Strict-Transport-Security 헤더 설정.
// noCache: Cache-Control 및 Pragma 헤더를 설정하여 클라이언트 측에서 캐싱을 사용하지 않도록 함.
// frameguard: X-Frame-Options 헤더 설정하여 clickjacking에 대한 보호 제공.
// ieNoOpen: (IE8 이상) X-Download-Options 설정.
// xssFilter: X-XSS-Protection 설정. 대부분의 최신 웹 브라우저에서 XSS(Cross-site scripting) 필터를 사용.
// noSniff: X-Content-Type-Options 설정하여, 선언된 콘텐츠 유형으로부터 벗어난 응답에 대한 브라우저의 MIME 가로채기를 방지.

app.use('/user', user);
app.use('/admin', admin);

options ? server = https.createServer(options, app).listen(443, () => {
	console.log('YuhanNuri, Listening on port ' + 443);
	
	DeleteOneMonth();
	DeleteFiveYear();
	ConsultTodayPush();
	ConsultTomorrowPush();
}) : undefined;

options ? http.createServer(function(req, res) {
	res.writeHead(301, {
		Location: `https://${req.headers["host"]}${req.url}`
	});
	res.end();
}).listen(80)
: server = http.createServer(app).listen(80, () => {
	console.log('YuhanNuri, Listening on port ' + 80);
	
	DeleteOneMonth();
	DeleteFiveYear();
	ConsultTodayPush();
	ConsultTomorrowPush();
});

const io = require('./routes/socket.js')(server); // socket.js파일에 server를 미들웨어로 사용

app.get('/', function (req, res) {
	if(req.signedCookies._uid !== undefined) req.session._uid = req.signedCookies._uid;
	if(req.session._uid !== undefined) {
		let selectHomeBoard = 'SELECT * FROM HomeBoard';
		connection.execute(selectHomeBoard, (err, rows) => {
			if(err) Logger.Error.info(`[${moment().format(logTimeFormat)}] ${err}`);
			else {
				res.render('main', {
					data: rows
				});
			}
		});
	}
	else res.render('login');
});

app.get('/app', function(req, res) {
	res.download('./public/res/app/YuhanNuri.apk');
});

app.get('/ios', function(req, res) {
	res.send("<script>window.location.assign('itms-services://?action=download-manifest&url=https://counsel.yuhan.ac.kr/res/app/manifest.plist')</script>");
});

app.use((req, res, next) => {
	const error = new Error(`${req.method} ${decodeURIComponent(req.url)}는 존재하지 않는 페이지 입니다.`);
	error.status = 404;
	next(error);
});

app.use((err, req, res, next) => {
	res.locals.message = err.message;
	res.locals.error = process.env.NODE_ENV !== 'production' ? err : {}; 
	res.status(err.status || 500);
	res.render('error');
});
