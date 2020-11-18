const port = 3000;

const express = require('express');
const app = express();

const session = require('express-session');
const dotenv = require('dotenv');
const path=require('path');

const helmet=require('helmet');

const userRouter = require('./routes/user');
const adminRouter = require('./routes/admin');

const cookieParser = require('cookie-parser');

const db = require('./public/res/js/database.js')();
const connection = db.init();

db.open(connection,'main');

dotenv.config();

app.set('views', __dirname + '/views');
app.set('view engine', 'ejs');

app.engine('html', require('ejs').renderFile);

app.use(express.static(__dirname + '/public'));
app.use('/uploads',express.static(path.join(__dirname, 'uploads')));
app.use('/style',express.static(path.join(__dirname, '/public/res/css')));
app.use('/lib',express.static(path.join(__dirname, '/public/res/lib')));

app.use(express.json());
app.use(express.urlencoded({ extended: false }));

app.use(session({ secret: process.env.COOKIE_SECRET, resave: false, saveUninitialized: false}));
app.use(cookieParser('vaCzbAVeMy9pT7Uw'));

if(process.env.NODE_ENV==='production'){
	app.use(helmet());
	// helmet 미들웨어에는 이런 기능들을 통해 보안을 설정 합니다. 어느정도 타협해야하는 보안 수준이 있다면 말씀해 주시면 빼도록 하겠습니다 - 성준
	// csp: Content-Security-Policy 헤더 설정. XSS(Cross-site scripting) 공격 및 기타 교차 사이트 인젝션 예방.
	// hidePoweredBy: X-Powered-By 헤더 제거.
	// hpkp: Public Key Pinning 헤더 추가. 위조된 인증서를 이용한 중간자 공격 방지.
	// hsts: SSL/TLS를 통한 HTTP 연결을 적용하는 Strict-Transport-Security 헤더 설정.
	// noCache : Cache-Control 및 Pragma 헤더를 설정하여 클라이언트 측에서 캐싱을 사용하지 않도록 함.
	// frameguard : X-Frame-Options 헤더 설정하여 clickjacking에 대한 보호 제공.
	// ieNoOpen : (IE8 이상) X-Download-Options 설정.
	// xssFilter :  X-XSS-Protection 설정. 대부분의 최신 웹 브라우저에서 XSS(Cross-site scripting) 필터를 사용.
	// noSniff : X-Content-Type-Options 설정하여, 선언된 콘텐츠 유형으로부터 벗어난 응답에 대한 브라우저의 MIME 가로채기를 방지.
}
app.use('/user', userRouter);
app.use('/admin', adminRouter);


const server = app.listen(port, () => {
    console.log('Listening on port ' + port + '\n');
});

const io = require(__dirname + '/public/res/js/socket.js')(server); // socket.js파일에 server를 미들웨어로 사용

app.get('/', function (req, res) {
	//console.info("isAutoLogin: " + req.signedCookies.isAutoLogin);
	let selectHomeBoard = "select  * from HomeBoard";

	if(req.session.userInfo){
		connection.execute(selectHomeBoard,(err,rows)=>{
			if(err){
				console.error(err);
			}else{
				res.render('main',{
					data:rows
				});
			}
		})
	}
	
	else if(req.signedCookies.isAutoLogin != undefined) res.redirect('/user/auto');
	else res.render('login');
});

app.use((req,res,next)=>{
	const error=new Error(`${req.method} ${decodeURIComponent(req.url)}는 존재하지 않는 페이지 입니다!`);
	error.status=404;
	next(error); 
});

app.use((err,req,res,next)=>{
	res.locals.message=err.message;
	res.locals.error=process.env.NODE_ENV !== 'production' ? err : {}; 
	res.status(err.status || 500);
	res.render('error');
});
