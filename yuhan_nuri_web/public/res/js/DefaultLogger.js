const {createLogger, format, transports} = require('winston');

const DefaultLogger = createLogger({
	format: format.printf(
		log => `${log.message} \n`
	),
	transports: [
		new transports.File({filename: 'default.log'}),
	],
});

//if(process.env.NODE_ENV !== 'production') DefaultLogger.add(new transports.Console({format: format.simple()}));

module.exports = DefaultLogger;