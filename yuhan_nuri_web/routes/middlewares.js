exports.isAccessDenied = (req, res, next) => {
	if(req.session.adminInfo === undefined) res.redirect('/');
	else {
		if(req.session.adminInfo.author === 1) next();
		else {
			res.send("<script>alert('접근 권한이 없습니다.'); window.history.back();</script>");
			next();
		}
	}
}

exports.isAdminLoggedIn = (req, res, next) => { // 관리자 로그인 정보 확인 미들웨어
	if(req.session.adminInfo === undefined) res.redirect('/');
	else next();
}

exports.isUserLoggedIn = (req, res, next) => { // 사용자 로그인 정보 확인 미들웨어
	if(req.signedCookies._uid !== undefined || req.session._uid !== undefined) next();
	else res.redirect('/');
}
