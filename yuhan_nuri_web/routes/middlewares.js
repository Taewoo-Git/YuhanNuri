exports.isAdminLoggedIn=(req,res,next)=>{ // 어드민 로그인 정보 확인 미들웨어
	if(req.session.adminInfo===undefined){
		res.redirect('/');
	}else{
		next();
	}
}
exports.isUserLoggedIn=(req,res,next)=>{ // 유저 로그인 정보 확인 미들웨어
	if(req.session.userInfo===undefined){
		res.redirect('/');
	}else{
		next();
	}
}
