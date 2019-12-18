const warmer = require('lambda-warmer');

const {
    updateDefinitions,
    runDeamon,
    scanFile,
} = require('./clamav');

const updateDefinitionsHandler = async () => {
    await updateDefinitions();

    return true;
};

const scanFileHandler = async (event) => {
    await runDeamon();

    if (event.warmer
        && !event.__WARMER_INVOCATION__
        && !event.__WARMER_CONCURRENCY__
        && !event.__WARMER_CORRELATIONID__
    ) {
        event.concurrency = process.env.WARM_CONCURRENCY || 1; // eslint-disable-line
    }

    const warmed = await warmer(event);

    if (warmed) {
        return 'Warming lambda';
    }

    const { bucket, key } = event;

    return scanFile(bucket, key);
};

module.exports = {
    updateDefinitionsHandler,
    scanFileHandler,
};
