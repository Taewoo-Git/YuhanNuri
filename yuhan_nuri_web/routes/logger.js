const {createLogger, format, transports} = require('winston');

exports.account = createLogger({
	format: format.printf(
		log => `${log.message} \n`
	),
	transports: [
		new transports.File({filename: 'log/account.log'}),
	],
});

exports.file = createLogger({
	format: format.printf(
		log => `${log.message} \n`
	),
	transports: [
		new transports.File({filename: 'log/file.log'}),
	],
});

exports.form = createLogger({
	format: format.printf(
		log => `${log.message} \n`
	),
	transports: [
		new transports.File({filename: 'log/form.log'}),
	],
});

exports.question = createLogger({
	format: format.printf(
		log => `${log.message} \n`
	),
	transports: [
		new transports.File({filename: 'log/question.log'}),
	],
});

exports.reservation = createLogger({
	format: format.printf(
		log => `${log.message} \n`
	),
	transports: [
		new transports.File({filename: 'log/reservation.log'}),
	],
});

exports.schedule = createLogger({
	format: format.printf(
		log => `${log.message} \n`
	),
	transports: [
		new transports.File({filename: 'log/schedule.log'}),
	],
});

exports.error = createLogger({
	format: format.printf(
		log => `${log.message} \n`
	),
	transports: [
		new transports.File({filename: 'log/error.log'}),
		new transports.Console({format: format.simple()}),
	],
});
