const { createLogger, format, transports } = require('winston');

var logLevels = {
    levels: {
		emerg: 0,
		alert: 1,
		crit: 2,
		error: 3,
		warning: 4,
		notice: 5,
		info: 6,
		debug: 7,
		user: 8
    }
};

const logger = createLogger({
	levels: logLevels.levels,
	format: format.printf(
		log => `${ log.message } \n`
	),
	transports: [
		new transports.File({ filename: 'user.log', level: 'user' }),
	],
});

if (process.env.NODE_ENV !== 'production'){
	logger.add(new transports.Console({ format: format.simple(), level: 'user' }));
}

module.exports = logger;