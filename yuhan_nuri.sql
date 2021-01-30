-- --------------------------------------------------------
-- 호스트:                          54.180.149.157
-- 서버 버전:                        10.1.44-MariaDB-0ubuntu0.18.04.1 - Ubuntu 18.04
-- 서버 OS:                        debian-linux-gnu
-- HeidiSQL 버전:                  10.2.0.5599
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;


-- yuhan_nuri 데이터베이스 구조 내보내기
CREATE DATABASE IF NOT EXISTS `yuhan_nuri` /*!40100 DEFAULT CHARACTER SET utf8mb4 */;
USE `yuhan_nuri`;

-- 테이블 yuhan_nuri.AnswerLog 구조 내보내기
CREATE TABLE IF NOT EXISTS `AnswerLog` (
  `serialno` int(11) NOT NULL,
  `askno` int(11) NOT NULL,
  `choiceanswer` text NOT NULL,
  PRIMARY KEY (`serialno`,`askno`),
  KEY `FK_AnswerLog_askno_TO_AskList_askno` (`askno`),
  CONSTRAINT `FK_AnswerLog_askno_TO_AskList_askno` FOREIGN KEY (`askno`) REFERENCES `AskList` (`askno`) ON UPDATE CASCADE,
  CONSTRAINT `FK_AnswerLog_serialno_TO_SimpleApplyForm_serialno` FOREIGN KEY (`serialno`) REFERENCES `SimpleApplyForm` (`serialno`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.AnswerLog:~0 rows (대략적) 내보내기
/*!40000 ALTER TABLE `AnswerLog` DISABLE KEYS */;
/*!40000 ALTER TABLE `AnswerLog` ENABLE KEYS */;

-- 테이블 yuhan_nuri.AskList 구조 내보내기
CREATE TABLE IF NOT EXISTS `AskList` (
  `askno` int(11) NOT NULL AUTO_INCREMENT,
  `typeno` int(11) NOT NULL,
  `choicetypeno` int(11) NOT NULL,
  `ask` text NOT NULL,
  `use` char(1) NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`askno`,`typeno`),
  KEY `FK_AskList_typeno_TO_AskType_typeno` (`typeno`),
  KEY `FK_AskList_choicetypeno_TO_ChoiceType` (`choicetypeno`),
  CONSTRAINT `FK_AskList_choicetypeno_TO_ChoiceType` FOREIGN KEY (`choicetypeno`) REFERENCES `ChoiceType` (`choicetypeno`) ON UPDATE CASCADE,
  CONSTRAINT `FK_AskList_typeno_TO_AskType_typeno` FOREIGN KEY (`typeno`) REFERENCES `AskType` (`typeno`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=266 DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.AskList:~0 rows (대략적) 내보내기
/*!40000 ALTER TABLE `AskList` DISABLE KEYS */;
/*!40000 ALTER TABLE `AskList` ENABLE KEYS */;

-- 테이블 yuhan_nuri.AskType 구조 내보내기
CREATE TABLE IF NOT EXISTS `AskType` (
  `typeno` int(11) NOT NULL AUTO_INCREMENT,
  `typename` varchar(20) NOT NULL,
  PRIMARY KEY (`typeno`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.AskType:~3 rows (대략적) 내보내기
/*!40000 ALTER TABLE `AskType` DISABLE KEYS */;
INSERT INTO `AskType` (`typeno`, `typename`) VALUES
	(1, '상담예약'),
	(2, '심리검사'),
	(3, '만족도조사');
/*!40000 ALTER TABLE `AskType` ENABLE KEYS */;

-- 테이블 yuhan_nuri.ChoiceList 구조 내보내기
CREATE TABLE IF NOT EXISTS `ChoiceList` (
  `choiceno` int(11) NOT NULL AUTO_INCREMENT,
  `askno` int(11) NOT NULL,
  `typeno` int(11) NOT NULL,
  `choice` text,
  PRIMARY KEY (`choiceno`,`askno`,`typeno`),
  KEY `FK_ChoiceList_askno_TO_AskList_askno` (`askno`),
  KEY `FK_ChoiceList_typeno_TO_AskList_typeno` (`typeno`),
  CONSTRAINT `FK_ChoiceList_askno_TO_AskList_askno` FOREIGN KEY (`askno`) REFERENCES `AskList` (`askno`) ON UPDATE CASCADE,
  CONSTRAINT `FK_ChoiceList_typeno_TO_AskList_typeno` FOREIGN KEY (`typeno`) REFERENCES `AskList` (`typeno`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=177 DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.ChoiceList:~0 rows (대략적) 내보내기
/*!40000 ALTER TABLE `ChoiceList` DISABLE KEYS */;
/*!40000 ALTER TABLE `ChoiceList` ENABLE KEYS */;

-- 테이블 yuhan_nuri.ChoiceType 구조 내보내기
CREATE TABLE IF NOT EXISTS `ChoiceType` (
  `choicetypeno` int(11) NOT NULL AUTO_INCREMENT,
  `choicetypename` varchar(20) NOT NULL DEFAULT '',
  PRIMARY KEY (`choicetypeno`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.ChoiceType:~3 rows (대략적) 내보내기
/*!40000 ALTER TABLE `ChoiceType` DISABLE KEYS */;
INSERT INTO `ChoiceType` (`choicetypeno`, `choicetypename`) VALUES
	(1, 'Radio'),
	(2, 'Check'),
	(3, 'Normal');
/*!40000 ALTER TABLE `ChoiceType` ENABLE KEYS */;

-- 테이블 yuhan_nuri.ConsultLog 구조 내보내기
CREATE TABLE IF NOT EXISTS `ConsultLog` (
  `serialno` int(11) NOT NULL,
  `chatlog` text,
  `date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`serialno`) USING BTREE,
  CONSTRAINT `FK_ConsultLog_serialno_TO_Reservation_serialno` FOREIGN KEY (`serialno`) REFERENCES `Reservation` (`serialno`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.ConsultLog:~0 rows (대략적) 내보내기
/*!40000 ALTER TABLE `ConsultLog` DISABLE KEYS */;
/*!40000 ALTER TABLE `ConsultLog` ENABLE KEYS */;

-- 테이블 yuhan_nuri.ConsultType 구조 내보내기
CREATE TABLE IF NOT EXISTS `ConsultType` (
  `typeno` int(11) NOT NULL AUTO_INCREMENT,
  `typename` varchar(10) NOT NULL,
  PRIMARY KEY (`typeno`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.ConsultType:~4 rows (대략적) 내보내기
/*!40000 ALTER TABLE `ConsultType` DISABLE KEYS */;
INSERT INTO `ConsultType` (`typeno`, `typename`) VALUES
	(1, '채팅상담'),
	(2, '화상상담'),
	(3, '전화상담'),
	(4, '대면상담');
/*!40000 ALTER TABLE `ConsultType` ENABLE KEYS */;

-- 테이블 yuhan_nuri.Counselor 구조 내보내기
CREATE TABLE IF NOT EXISTS `Counselor` (
  `empid` varchar(30) NOT NULL DEFAULT '',
  `emppwd` varchar(100) NOT NULL DEFAULT '',
  `empname` varchar(20) NOT NULL DEFAULT '',
  `positionno` int(11) NOT NULL DEFAULT '1',
  `use` char(1) NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`empid`) USING BTREE,
  KEY `FK_Counselor_positionno_To_PositionType_positionno` (`positionno`),
  CONSTRAINT `FK_Counselor_positionno_To_PositionType_positionno` FOREIGN KEY (`positionno`) REFERENCES `PositionType` (`positionno`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.Counselor:~9 rows (대략적) 내보내기
/*!40000 ALTER TABLE `Counselor` DISABLE KEYS */;
INSERT INTO `Counselor` (`empid`, `emppwd`, `empname`, `positionno`, `use`) VALUES
	('admin', '$2b$12$KYl46rZEeMnxPA.uQLY/SeWSH0cWTiYRLeVbM9vZ9QhVGXMff1Nsa', '관리자', 1, 'Y');
/*!40000 ALTER TABLE `Counselor` ENABLE KEYS */;

-- 테이블 yuhan_nuri.HomeBoard 구조 내보내기
CREATE TABLE IF NOT EXISTS `HomeBoard` (
  `no` int(11) NOT NULL,
  `empid` varchar(30) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `content` mediumtext,
  PRIMARY KEY (`no`),
  KEY `FK_HomeBoard_empid_TO_Counselor_empid` (`empid`),
  CONSTRAINT `FK_HomeBoard_empid_TO_Counselor_empid` FOREIGN KEY (`empid`) REFERENCES `Counselor` (`empid`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.HomeBoard:~2 rows (대략적) 내보내기
/*!40000 ALTER TABLE `HomeBoard` DISABLE KEYS */;
INSERT INTO `HomeBoard` (`no`, `empid`, `date`, `content`) VALUES
	(1, NULL, NULL, ''),
	(2, NULL, NULL, '');
/*!40000 ALTER TABLE `HomeBoard` ENABLE KEYS */;

-- 테이블 yuhan_nuri.PositionType 구조 내보내기
CREATE TABLE IF NOT EXISTS `PositionType` (
  `positionno` int(11) NOT NULL AUTO_INCREMENT,
  `positionname` varchar(30) NOT NULL DEFAULT '',
  KEY `positionno` (`positionno`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.PositionType:~2 rows (대략적) 내보내기
/*!40000 ALTER TABLE `PositionType` DISABLE KEYS */;
INSERT INTO `PositionType` (`positionno`, `positionname`) VALUES
	(1, '교직원'),
	(2, '근로학생');
/*!40000 ALTER TABLE `PositionType` ENABLE KEYS */;

-- 테이블 yuhan_nuri.PsyTest 구조 내보내기
CREATE TABLE IF NOT EXISTS `PsyTest` (
  `serialno` int(11) NOT NULL,
  `testno` int(11) NOT NULL,
  PRIMARY KEY (`serialno`,`testno`),
  KEY `FK_PsyTest_testno_TO_PsyTestList_testno` (`testno`),
  CONSTRAINT `FK_PsyTest_serialno_TO_SimpleApplyForm_serialno` FOREIGN KEY (`serialno`) REFERENCES `SimpleApplyForm` (`serialno`) ON UPDATE CASCADE,
  CONSTRAINT `FK_PsyTest_testno_TO_PsyTestList_testno` FOREIGN KEY (`testno`) REFERENCES `PsyTestList` (`testno`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.PsyTest:~53 rows (대략적) 내보내기
/*!40000 ALTER TABLE `PsyTest` DISABLE KEYS */;
/*!40000 ALTER TABLE `PsyTest` ENABLE KEYS */;

-- 테이블 yuhan_nuri.PsyTestList 구조 내보내기
CREATE TABLE IF NOT EXISTS `PsyTestList` (
  `testno` int(10) NOT NULL AUTO_INCREMENT,
  `testname` varchar(100) DEFAULT NULL,
  `description` text,
  `use` char(1) NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`testno`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.PsyTestList:~15 rows (대략적) 내보내기
/*!40000 ALTER TABLE `PsyTestList` DISABLE KEYS */;
INSERT INTO `PsyTestList` (`testno`, `testname`, `description`, `use`) VALUES
	(1, 'MBTI', '16가지 성격유형 중 자신의 성격유형에 대한 장단점 탐색', 'Y'),
	(2, 'TCI', '자신의 기질과 성격 탐색', 'Y'),
	(3, '성격5요인 검사', '성격을 5요인으로 나눠 알아보고 사회생활의 어려움을 사전에 발견하여 대처방법 모색', 'Y'),
	(4, 'CST 검사', '성격강점을 측정하여 자신에 대한 이해 향상', 'Y'),
	(5, '에니어그램 검사', '개인의 기질별 특성에 따른 욕구와 잠재력, 특징과 스트레스 방향 등을 평가', 'Y'),
	(6, '홀랜드(적성탐색검사)', '자신의 가치관, 능력, 성격 등을 측정하여 6가지 직업분야 중 자신의 적성을 탐색', 'Y'),
	(7, 'CTI(진로사고검사)', '진로선택을 어렵게 만드는 심리적 요인을 탐색', 'Y'),
	(8, 'MMPI-2', '현재 심리상태, 스트레스 정도, 적응수준 정도 등 심층적인 마음의 상태를 탐색', 'Y'),
	(9, 'SCT(문장완성검사)', '미완성 문장을 완성하며 가족‧대인관계‧자기개념 영역 등을 탐색', 'Y'),
	(10, '자기감정(불안) 평가', '불안정도를 측정', 'Y'),
	(11, '대인관계문제', '대인관계문제를 종합적으로 평가, 진단하는 검사', 'Y'),
	(12, 'SLT 자기조절학습검사', '자기조절 학습전략, 학습 동기와 정서 상태를 측정', 'Y'),
	(13, 'MST(학습동기유형검사)', '학습자의 학습동기 수준과 유형, 그에 영향을 주는 주보호자의 양육 방식을 탐색', 'Y'),
	(14, 'MLST(학습전략검사)', '학업 성취도에 영향을 미치는 심리적 특성과 동기 수준 정도를 탐색', 'Y');
/*!40000 ALTER TABLE `PsyTestList` ENABLE KEYS */;

-- 테이블 yuhan_nuri.QuestionBoard 구조 내보내기
CREATE TABLE IF NOT EXISTS `QuestionBoard` (
  `no` int(11) NOT NULL AUTO_INCREMENT,
  `stuno` char(9) NOT NULL,
  `type` varchar(30) DEFAULT NULL,
  `date` date NOT NULL,
  `title` varchar(100) NOT NULL,
  `content` mediumtext NOT NULL,
  `empname` varchar(20) DEFAULT NULL,
  `answerdate` date DEFAULT NULL,
  `answer` text,
  PRIMARY KEY (`no`),
  KEY `QuestionBoard_stuno_fk` (`stuno`),
  CONSTRAINT `QuestionBoard_stuno_fk` FOREIGN KEY (`stuno`) REFERENCES `User` (`stuno`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.QuestionBoard:~11 rows (대략적) 내보내기
/*!40000 ALTER TABLE `QuestionBoard` DISABLE KEYS */;
/*!40000 ALTER TABLE `QuestionBoard` ENABLE KEYS */;

-- 테이블 yuhan_nuri.Reservation 구조 내보내기
CREATE TABLE IF NOT EXISTS `Reservation` (
  `serialno` int(11) NOT NULL,
  `stuno` char(9) NOT NULL,
  `empid` varchar(30) DEFAULT NULL,
  `typeno` int(11) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `starttime` tinyint(2) DEFAULT NULL,
  `agree` tinyint(1) NOT NULL DEFAULT '1',
  `status` tinyint(1) NOT NULL DEFAULT '0',
  `finished` tinyint(1) NOT NULL DEFAULT '0',
  `research` tinyint(1) NOT NULL DEFAULT '0',
  `researchdatetime` datetime DEFAULT NULL,
  PRIMARY KEY (`serialno`) USING BTREE,
  KEY `FK_Reservation_stuno_TO_User_stuno` (`stuno`),
  KEY `FK_Reservation_empid_TO_Counselor_empid` (`empid`),
  KEY `FK_Reservation_typeno_TO_ConsultType_typeno` (`typeno`),
  CONSTRAINT `FK_Reservation_empid_TO_Counselor_empid` FOREIGN KEY (`empid`) REFERENCES `Counselor` (`empid`) ON UPDATE CASCADE,
  CONSTRAINT `FK_Reservation_serialno_TO_SimpleApplyForm_serialno` FOREIGN KEY (`serialno`) REFERENCES `SimpleApplyForm` (`serialno`) ON UPDATE CASCADE,
  CONSTRAINT `FK_Reservation_stuno_TO_User_stuno` FOREIGN KEY (`stuno`) REFERENCES `User` (`stuno`) ON UPDATE CASCADE,
  CONSTRAINT `FK_Reservation_typeno_TO_ConsultType_typeno` FOREIGN KEY (`typeno`) REFERENCES `ConsultType` (`typeno`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.Reservation:~35 rows (대략적) 내보내기
/*!40000 ALTER TABLE `Reservation` DISABLE KEYS */;
/*!40000 ALTER TABLE `Reservation` ENABLE KEYS */;

-- 테이블 yuhan_nuri.Schedule 구조 내보내기
CREATE TABLE IF NOT EXISTS `Schedule` (
  `scheduleno` int(11) NOT NULL AUTO_INCREMENT,
  `empid` varchar(30) NOT NULL DEFAULT '',
  `calendarId` varchar(20) NOT NULL,
  `title` varchar(50) NOT NULL,
  `category` varchar(50) NOT NULL,
  `start` datetime NOT NULL,
  `end` datetime NOT NULL,
  `location` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`scheduleno`) USING BTREE,
  KEY `FK_Schedule_empid_TO_Counselor_empid` (`empid`),
  CONSTRAINT `FK_Schedule_empid_TO_Counselor_empid` FOREIGN KEY (`empid`) REFERENCES `Counselor` (`empid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.Schedule:~10 rows (대략적) 내보내기
/*!40000 ALTER TABLE `Schedule` DISABLE KEYS */;
/*!40000 ALTER TABLE `Schedule` ENABLE KEYS */;

-- 테이블 yuhan_nuri.SelfCheck 구조 내보내기
CREATE TABLE IF NOT EXISTS `SelfCheck` (
  `serialno` int(11) NOT NULL,
  `checkno` int(11) NOT NULL,
  `score` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`serialno`,`checkno`) USING BTREE,
  KEY `FK_SelfCheck_checkno_TO_SelfCheckList_checkno` (`checkno`),
  CONSTRAINT `FK_SelfCheck_checkno_TO_SelfCheckList_checkno` FOREIGN KEY (`checkno`) REFERENCES `SelfCheckList` (`checkno`) ON UPDATE CASCADE,
  CONSTRAINT `FK_SelfCheck_serialno_TO_SimpleApplyForm_serialno` FOREIGN KEY (`serialno`) REFERENCES `SimpleApplyForm` (`serialno`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.SelfCheck:~56 rows (대략적) 내보내기
/*!40000 ALTER TABLE `SelfCheck` DISABLE KEYS */;
/*!40000 ALTER TABLE `SelfCheck` ENABLE KEYS */;

-- 테이블 yuhan_nuri.SelfCheckList 구조 내보내기
CREATE TABLE IF NOT EXISTS `SelfCheckList` (
  `checkno` int(11) NOT NULL AUTO_INCREMENT,
  `checkname` text NOT NULL,
  `use` char(1) NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`checkno`)
) ENGINE=InnoDB AUTO_INCREMENT=50 DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.SelfCheckList:~36 rows (대략적) 내보내기
/*!40000 ALTER TABLE `SelfCheckList` DISABLE KEYS */;
/*!40000 ALTER TABLE `SelfCheckList` ENABLE KEYS */;

-- 테이블 yuhan_nuri.SimpleApplyForm 구조 내보내기
CREATE TABLE IF NOT EXISTS `SimpleApplyForm` (
  `serialno` int(11) NOT NULL,
  `stuno` char(9) NOT NULL,
  `stuname` varchar(50) NOT NULL,
  `gender` varchar(10) NOT NULL,
  `birth` varchar(20) NOT NULL,
  `email` varchar(50) NOT NULL,
  `date` date NOT NULL,
  PRIMARY KEY (`serialno`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.SimpleApplyForm:~28 rows (대략적) 내보내기
/*!40000 ALTER TABLE `SimpleApplyForm` DISABLE KEYS */;
/*!40000 ALTER TABLE `SimpleApplyForm` ENABLE KEYS */;

-- 테이블 yuhan_nuri.User 구조 내보내기
CREATE TABLE IF NOT EXISTS `User` (
  `stuno` char(9) NOT NULL,
  `stuname` varchar(10) NOT NULL,
  `birth` char(6) NOT NULL,
  `major` varchar(20) NOT NULL,
  `phonenum` varchar(13) NOT NULL,
  `addr` varchar(150) NOT NULL,
  `email` varchar(30) NOT NULL,
  `token` mediumtext NOT NULL,
  PRIMARY KEY (`stuno`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 테이블 데이터 yuhan_nuri.User:~6 rows (대략적) 내보내기
/*!40000 ALTER TABLE `User` DISABLE KEYS */;
/*!40000 ALTER TABLE `User` ENABLE KEYS */;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
