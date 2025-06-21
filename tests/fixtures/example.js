function example() {
	// #region Configuration Setup
	const config = {
		host: 'localhost',
		port: 3000,
		ssl: false
	};
	const database = {
		url: 'mongodb://localhost:27017',
		name: 'testdb'
	};
	// #endregion

	// #region Helper Functions
	function validateConfig(cfg) {
		return cfg.host && cfg.port;
	}

	function initDatabase(db) {
		return { ...database, ...db };
	}

	function connectToServices() {
		return Promise.all([
			connectToDatabase(),
			connectToCache()
		]);
	}
	// #endregion

	// #region Main Logic
	async function initialize() {
		if (!validateConfig(config)) {
			throw new Error('Invalid configuration');
		}

		await connectToServices();
		return { config, database };
	}
	// #endregion

	return initialize();
}
