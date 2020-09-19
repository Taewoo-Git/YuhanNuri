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
		console.info('admionrows', rows);
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

	//현재 path를 타고온 type이 db에 있는 타입인지 확인을 합니다. 없는 경우 에러 미들웨어로 보내 404 에러를 뜨게 합니다.
	//있는 경우 해당 타입의 이름을 가지고 들어와 Home/심리 자가진단/타입의 이름으로 찍히게 됩니다.
	//읽어 보시고 이해가 되셨다면 해당 주석을 지우셔도 됩니다.- 성준
	connection.execute(sql_findType,[req.params.type],(err,rows)=>{ //해당 type의 유무 확인
		if(err){
			console.error(err);
			next(err);
		}
		if(rows.length == 0){ //rows [] 
			next(err);
		}else{
			res.render('selfCheckForm',{state:rows[0].typename});
		}
	});
	
	//현재 데이터를 받아서 처리하는 방식은 만들지 않았습니다.하여 수고롭지만 매번 데이터를 넣어 확인해주시길 바랍니다. - 성준
});


router.post("/saveForm",(req, res, next) => { // 변수명 짓기 어려워요... 임의의 이름으로 하다 추후 다시 바꾸어보아요..ㅠ -성준
	
	const sendAjax = JSON.parse(req.body.sendAjax); 
	console.log(sendAjax);
	
	const test_type = [0, '우울']; // 테스트용 type
	
	const sql_insertCardInfo = "INSERT INTO FormTypeContent VALUES(?, ?, ?, ?)"; 
	const sql_insertAnswerInfo = "INSERT INTO FormAnswer VALUES(?, ?, ?, ?)";
	const sql_deleteForNew = "DELETE FROM FormTypeInfo WHERE typeno = ?";
	const sql_recreType = "INSERT INTO FormTypeInfo VALUES(?,?)";
	
	
	// typeno 에 따른 갈아엎어버리는 코드 시작. 새로 넣기 위해서
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
	// 갈아 엎기 끗. DB 상에서 DELETE CASCADE 설정 했으니 싹 지워질것임
	
	
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
		
		if(cardData.askList === undefined){ //normal일 경우에 askList가 존재 하지 않아서 그냥 넘김 - 성준
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
})


module.exports = router;
