const express=require('express');
const router=express.Router();

const cheerio = require('cheerio-httpcli');


const database = require('../public/res/js/mariadb_config')();
const connection = database.init();
database.open(connection);


router.post('/', function (req, res) { //POST user/login
    var userId = req.body.userId;
    var password = req.body.password;

    var url =
        'http://portal.yuhan.ac.kr/user/loginProcess.face?userId=' +
        userId +
        '&password=' +
        password;
    var param = {};
    let userInfo;
    cheerio.fetch(url, param, function (error, $, response) {
        if (error) {
            console.error(error);
            return;
        } else {
            if (response.cookies.EnviewSessionId) {
                var tempInfo = [];

                cheerio.set('browser', 'chrome');
                cheerio.fetch('http://m.yuhan.ac.kr/bachelor/bcUserInfoR.jsp', param, function (
                    error,
                    $,
                    response
                ) {
                    if (error) {
                        console.error(error);
                        return;
                    } else {
                        $('td').each(function (index, element) {
                            tempInfo.push($(this).text().trim());
                        });
                    }

                    userInfo = {
                        stuCode: tempInfo[0],
                        stuName: tempInfo[1],
                        stuRegNum: tempInfo[2],
                        stuMajor: tempInfo[3],
                        stuHomeNum: tempInfo[4],
                        stuPhoneNum: tempInfo[5],
                        stuEmail: tempInfo[6],
                        stuAddr: tempInfo[7],
                    };
                
                    var userBirth = userInfo.stuRegNum.split('-')[0];
                    var userJoinCheckSql = 'SELECT * FROM User WHERE stuno = ?';
                    var userJoinCheckSql_result;
                    var userJoinSql = 'INSERT INTO User VALUES(?, ?, ?, ?, ?, ?, ?,?)';

                    connection.execute(userJoinCheckSql, [userInfo.stuCode], (err, result) => {
                        if (err) {
                            console.error(err);
                        }
                        console.log('check Reult', result);
                        userJoinCheckSql_result = result.length;
                    });

                    if (!userJoinCheckSql_result) {
                        connection.execute(
                            userJoinSql,
                            [
                                userInfo.stuCode,
                                userInfo.stuName,
                                userBirth,
                                userInfo.stuMajor,
                                userInfo.stuHomeNum,
                                userInfo.stuPhoneNum,
                                userInfo.stuAddr,
                                userInfo.stuEmail
                            ],
                            (err, result) => {
                                if (err) {
                                    console.error(err.sqlMessage);
                                }
                            }
                        );
                    }

                    console.log(userInfo,userBirth);

                    //connection.end();
                    req.session.userInfo = userInfo;
                    res.render('main', {
                        username: req.session.userInfo.stuName,
                    });
                });
            } else {
                res.redirect('/');
            }
        }
    });
});

router.get('/logout', function (req, res) { //GET user/logout
    req.session.destroy();
    res.redirect('/');
});

router.get('/reservation', function (req, res) {// GET /user/reservation
    res.render('reservation');
});

router.post('/reservation', function (req, res) { // POST user/reservation
    var reservation_date = req.body.reservation_data;
    var reservation_time = req.body.reservation_time;

    console.log(typeof reservation_date);
    console.log(reservation_date);

    console.log(typeof reservation_time);
    console.log(reservation_time);

});


module.exports=router;