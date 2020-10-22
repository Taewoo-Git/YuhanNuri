const express = require('express');
const router = express.Router();

const db = require('../public/res/js/database.js')();
const connection = db.init();
db.open(connection, "admin");


router.get("/",function(req,res,next){ //GET /admin
	const getReservationData = "SELECT * FROM Reservation WHERE status = 0";
	
	connection.execute(getReservationData, (err,rows) => {
		if(err) {
			console.error(err);
			next(err);
		}
		//console.info('admionrows', rows);
		res.render('admin', {getReservation: rows});
	});
});

router.post("/accessReservation", function(req,res,next) { //POST /admin/accessReservation
	const getAccessReservationData = "UPDATE Reservation SET status=1, empno = ? WHERE no = ?";
	let data = req.body.sendAjax;
	let empno = req.session.adminInfo.empno;
	connection.execute(getAccessReservationData, [empno, data], (err,rows) => {
		if(err) {
			console.error(err);
			next(err);
		}
		
		res.json({getReservation: rows});
	});
});



router.get("/form/:type", function(req,res,next){ 
	
	const sql_findType="select typename from FormTypeInfo where typeno = ?";
	const sql_findTypes="select typename from FormTypeInfo";
	const sql_readCardData="select *, (select GROUP_CONCAT(content) FROM FormAnswer WHERE cardno=c.cardno) AS answer FROM FormTypeContent c WHERE typeno=?;"
	let type="";
	let types=[];
	
	connection.execute(sql_findType,[req.params.type],(err,rows)=>{ //해당 type의 유무 확인
		if(err){
			console.error(err);
			next(err);
		}
		if(rows.length == 0){ //rows [] 
			next(err);
		}else{
			type=rows[0].typename;
		}
	});
	connection.execute(sql_findTypes,(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}
		if(rows.length==0){
			next(err);
		}else{
			types=rows;
		}
	});
	connection.execute(sql_readCardData,[req.params.type],(err,rows)=>{
		if(err){
			console.error(err);
			next(err);
		}
		//비어 있을 경우 오른쪽 버튼을 이용해 추가 해달라는 문구 추가 함 - 성준
		res.render('selfcheckForm',{result:rows,type:type,types:types});
		
	});
});


router.post("/saveForm",(req, res, next) => { 
	
	const sendAjax = JSON.parse(req.body.sendAjax); 
	console.log(sendAjax);
	
	const test_type = [0, '우울']; // 테스트용 type
	
	const sql_insertCardInfo = "INSERT INTO FormTypeContent VALUES(?, ?, ?, ?)"; 
	const sql_insertAnswerInfo = "INSERT INTO FormAnswer VALUES(?, ?, ?, ?)";
	const sql_deleteCardInfo = "DELETE FROM FormTypeContent WHERE typeno = ?";
	//const sql_deleteForNew = "DELETE FROM FormTypeInfo WHERE typeno = ?";
	//const sql_recreType = "INSERT INTO FormTypeInfo VALUES(?,?)";
	
	
	// typeno 에 따른 갈아엎어버리는 코드 시작. 새로 넣기 위해서
	
	/*
	connection.execute(sql_deleteForNew , [ test_type[0] ] , (err) => { //무적권 배열식
		if(err){
			console.error(err);
			next(err);
		}
	});
	
	connection.execute(sql_recreType, test_type, (err) => { // 요거 배열 형태로 넣어도 들어갈라나. 해봐야지
		if(err) {
			console.error(err);
			next(err);
		}
	});
	*/
	
	// 이거 auto_increment 로 간다면 content 부분만 삭제해야 할듯 - 윤권
	
	
	connection.execute(sql_deleteCardInfo, [test_type[0]], (err) => {
		if(err){
			console.error(err);
			next(err);
		}
	});
	// FormTypeContent 에서 유형에 따라 삭제하는 코드, FormTypeInfo는 건드리지 않으며 auto_increment 로 간다면 이게 맞음
	
	
	// 새로 추가 코드
	sendAjax.forEach((cardData, cardno) => {
		let question = cardData.question;
		let answertype = cardData.type;
		
		console.log('Question :',cardno, test_type[0], question, answertype);
		connection.execute(sql_insertCardInfo, [cardno, test_type[0], question, answertype] , (err, rows) => { 
			if(err) {
				console.error(err);
				next(err);
			}
		});
		
		if(cardData.askList === undefined){ 
			return ;
		}else{
				cardData.askList.forEach((askData, askIndex) => {
				let ask = askData.ask;
				console.log('Answer:',askIndex, cardno, test_type[0], ask);
				connection.execute(sql_insertAnswerInfo, [askIndex, cardno, test_type[0], ask], (err, rows) => {
					if(err){
						console.error(err);
						next(err);
					}
				});
			});
		}
	});
	
	console.info("데이터베이스 입력 완료");
	res.json({state:'ok'});
});

router.post("/addType",function(req, res, next){
	// type을 저장하는 부분
	const sql_selectName = "SELECT * FROM FormTypeInfo WHERE typename = ?";
	const sql_creType = "INSERT INTO FormTypeInfo(typename) VALUES(?)";
	const newTypename = req.body.add_type;
	
	connection.execute(sql_selectName, [newTypename], (err, rows) => {
		console.info('냥',rows);
		if(rows.length != 0){
			console.info("err : 이미 있는 타입 !");
			return;
			// 이미 있는 유형일 경우 안들어가도록 처리를 해 놓음, 에러창이 뜨거나 해야되는데 어떤 방식으로 해야할지는 논의가 필요해 보임 - 윤권
		}else{
			connection.execute(sql_creType, [newTypename], (err) => {
				if(err){
					console.error(err);
					next(err);
				}
			});
			// DB 에는 새로운 유형 집어 넣음, 여기 또한 modal 폼이 꺼지거나 해야될거 같은데 차후 어떻게 처리할지 논의해봐야 할듯 - 윤권
		}
	});
});

router.get("/adminTest",function(req,res,next){ //GET /admin/adminTest
	res.render('calendarTest');
})

module.exports = router;
