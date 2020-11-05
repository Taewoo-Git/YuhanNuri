const port = 3000;

const express = require('express');
const app = express();

const session = require('express-session');
const dotenv = require('dotenv');
const path=require('path');

const userRouter = require('./routes/user');
const adminRouter = require('./routes/admin');
const fcmRouter=require('./routes/fcm');

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

app.use('/user', userRouter);
app.use('/admin',adminRouter);
app.use('/fcm',fcmRouter);


const server = app.listen(port, () => {
    console.log('Listening on port ' + port + '\n');
});

const io = require(__dirname + '/public/res/js/socket.js')(server); // socket.js파일에 server를 미들웨어로 사용

app.get('/', function (req, res) {
	let isInfo = req.session.userInfo; // 기존 세션의 존재 여부를 판단하여 view 처리.
	//console.info("isAutoLogin: " + req.signedCookies.isAutoLogin);
	let mainDataSql = "SELECT no, type, content FROM EditTest";	// 메인에 들어가는 데이터 SQL문
	if(isInfo) {
		connection.execute(mainDataSql,(err,rows)=>{
		if(err){
			console.error(err);
		}
		    res.render('main', {
				username: isInfo.stuName,
				data:rows
			});
		});
	}
	else if(req.signedCookies.isAutoLogin != undefined) res.redirect('/user/auto');
	else res.render('login');
});

app.get('/main', function (req, res) {
	let mainDataSql = "SELECT no, type, content FROM EditTest";	// 메인에 들어가는 데이터 SQL문
	connection.execute(mainDataSql,(err,rows)=>{
		if(err){
			console.error(err);
		}
		    res.render('main', {
			username: req.session.userInfo.stuName,
			data:rows
			});
		});
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

// 			<div class="tab-pane fade show active" id="공지사항">
// 				<label><b>공지사항</b></label><br/>
// 				<% JSON.parse(data[0].content).forEach(function(b,i){%>
// 					<%if(b.type == "paragraph"){%>
// 						<p>
// 							<%= b.data.text%>
// 						</p>
// 					<%}%>
// 					<%if(b.type == "image"){%>
// 						<img src="<%=b.data.file.url%>" alt="<%=b.data.caption%>"/>
// 					<%}%>
// 					<%if(b.type == "header"){%>
// 						<%if(b.data.level === 1){%>
// 							<h1>
// 								<%= b.data.text%>
// 							</h1>
// 						<%}%>
// 						<%if(b.data.level === 2){%>
// 							<h2>
// 								<%= b.data.text%>
// 							</h2>
// 						<%}%>
// 						<%if(b.data.level === 3){%>
// 							<h3>
// 								<%= b.data.text%>
// 							</h3>
// 						<%}%>
// 						<%if(b.data.level === 4){%>
// 							<h4>
// 								<%= b.data.text%>
// 							</h4>
// 						<%}%>
// 						<%if(b.data.level === 5){%>
// 							<h5>
// 								<%= b.data.text%>
// 							</h5>
// 						<%}%>
// 						<%if(b.data.level === 6){%>
// 							<h6>
// 								<%= b.data.text%>
// 							</h6>
// 						<%}%>
// 					<%}%>
// 					<%if(b.type == "list"){%>
// 						<% if(b.data.style==="ordered"){%>
// 							<ol>
// 								<% b.data.items.forEach(function(v,i){%>
// 									<li><%=v%></li>
// 								<%})%>
// 							</ol>
// 						<%}%>
// 						<% if(b.data.style==="unordered"){%>
// 							<ol>
// 								<% b.data.items.forEach(function(v,i){%>
// 									<li><%=v%></li>
// 								<%})%>
// 							</ol>
// 						<%}%>
// 					<%}%>
// 				<%})%>
//   			</div>
//   			<div class="tab-pane fade" id="이용안내">
// 				<label><b>이용안내</b></label><br/>
//     							<% JSON.parse(data[1].content).forEach(function(b,i){%>
// 					<%if(b.type == "paragraph"){%>
// 						<p>
// 							<%= b.data.text%>
// 						</p>
// 					<%}%>
// 					<%if(b.type == "image"){%>
// 						<img src="<%=b.data.file.url%>" alt="<%=b.data.caption%>"/>
// 					<%}%>
// 					<%if(b.type == "header"){%>
// 						<%if(b.data.level === 1){%>
// 							<h1>
// 								<%= b.data.text%>
// 							</h1>
// 						<%}%>
// 						<%if(b.data.level === 2){%>
// 							<h2>
// 								<%= b.data.text%>
// 							</h2>
// 						<%}%>
// 						<%if(b.data.level === 3){%>
// 							<h3>
// 								<%= b.data.text%>
// 							</h3>
// 						<%}%>
// 						<%if(b.data.level === 4){%>
// 							<h4>
// 								<%= b.data.text%>
// 							</h4>
// 						<%}%>
// 						<%if(b.data.level === 5){%>
// 							<h5>
// 								<%= b.data.text%>
// 							</h5>
// 						<%}%>
// 						<%if(b.data.level === 6){%>
// 							<h6>
// 								<%= b.data.text%>
// 							</h6>
// 						<%}%>
// 					<%}%>
// 					<%if(b.type == "list"){%>
// 						<% if(b.data.style==="ordered"){%>
// 							<ol>
// 								<% b.data.items.forEach(function(v,i){%>
// 									<li><%=v%></li>
// 								<%})%>
// 							</ol>
// 						<%}%>
// 						<% if(b.data.style==="unordered"){%>
// 							<ol>
// 								<% b.data.items.forEach(function(v,i){%>
// 									<li><%=v%></li>
// 								<%})%>
// 							</ol>
// 						<%}%>
// 					<%}%>
// 				<%})%>
//   			</div>
//   			<div class="tab-pane fade" id="FAQ">
// 				<label><b>FAQ</b></label><br/>
// 				<% JSON.parse(data[2].content).forEach(function(b,i){%>
// 					<%if(b.type == "paragraph"){%>
// 						<p>
// 							<%= b.data.text%>
// 						</p>
// 					<%}%>
// 					<%if(b.type == "image"){%>
// 						<img src="<%=b.data.file.url%>" alt="<%=b.data.caption%>"/>
// 					<%}%>
// 					<%if(b.type == "header"){%>
// 						<%if(b.data.level === 1){%>
// 							<h1>
// 								<%= b.data.text%>
// 							</h1>
// 						<%}%>
// 						<%if(b.data.level === 2){%>
// 							<h2>
// 								<%= b.data.text%>
// 							</h2>
// 						<%}%>
// 						<%if(b.data.level === 3){%>
// 							<h3>
// 								<%= b.data.text%>
// 							</h3>
// 						<%}%>
// 						<%if(b.data.level === 4){%>
// 							<h4>
// 								<%= b.data.text%>
// 							</h4>
// 						<%}%>
// 						<%if(b.data.level === 5){%>
// 							<h5>
// 								<%= b.data.text%>
// 							</h5>
// 						<%}%>
// 						<%if(b.data.level === 6){%>
// 							<h6>
// 								<%= b.data.text%>
// 							</h6>
// 						<%}%>
// 					<%}%>
// 					<%if(b.type == "list"){%>
// 						<% if(b.data.style==="ordered"){%>
// 							<ol>
// 								<% b.data.items.forEach(function(v,i){%>
// 									<li><%=v%></li>
// 								<%})%>
// 							</ol>
// 						<%}%>
// 						<% if(b.data.style==="unordered"){%>
// 							<ol>
// 								<% b.data.items.forEach(function(v,i){%>
// 									<li><%=v%></li>
// 								<%})%>
// 							</ol>
// 						<%}%>
// 					<%}%>
// 				<%})%>
//   			</div>