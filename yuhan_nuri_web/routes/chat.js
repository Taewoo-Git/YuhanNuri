const express = require('express');
const router = express.Router();

router.get('/', function (req, res) { //GET ~/chat
	res.render('chat', {
        username: req.session.userInfo.stuName,
    });
});

module.exports = router;