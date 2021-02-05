const {createLogger, format, transports} = require('winston');

const ErrorLogger = createLogger({
	format: format.printf(
		log => `${log.message} \n`
	),
	transports: [
		new transports.File({filename: 'error.log'}),
	],
});

if(process.env.NODE_ENV !== 'production') ErrorLogger.add(new transports.Console({format: format.simple()}));

module.exports = ErrorLogger;