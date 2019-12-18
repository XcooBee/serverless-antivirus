const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const {
    getFileInfo,
    downloadFile,
    uploadFile,
    tagFile,
} = require('./s3');

const {
    CLAMAV_BUCKET_NAME,
    PATH_TO_AV_DEFINITIONS,
    FILE_STATUS_CLEAN = 'CLEAN',
    FILE_STATUS_INFECTED = 'INFECTED',
    FILE_STATUS_SKIPPED = 'SKIPPED',
    FILE_STATUS_PROCESSING_ERROR = 'PROCCESSING_ERROR',
} = process.env;

const DEAMON_STATE_RUN = 1;
const DEAMON_STATE_STOP = 0;

// max filesize is about 300MB with some additional space
// because lambda allows using only 512MB of /tmp/ and AV definitions weigh about 120MB
const MAX_FILE_SIZE = 300 * 1024 * 1024;

const clamavDefinitionFiles = ['main.cvd', 'daily.cvd', 'bytecode.cvd'];

let deamonState = DEAMON_STATE_STOP;

let tryCount = 0;

const runDeamon = async () => {
    if (deamonState === DEAMON_STATE_RUN) {
        return;
    }

    tryCount++;

    execSync('rm -rf /tmp/*');

    await Promise.all(clamavDefinitionFiles.map((file) => {
        const fileKey = PATH_TO_AV_DEFINITIONS
            ? `${PATH_TO_AV_DEFINITIONS}/${file}`
            : file;

        return downloadFile(CLAMAV_BUCKET_NAME, fileKey);
    }));

    try {
        execSync('./clamd -c ./clamd.conf');
    } catch (err) {
        // sometimes deamon cannot verify clamav DB, so let's try few more times
        if (tryCount > 3) {
            tryCount = 0;
            throw err;
        }

        await runDeamon();
    }

    deamonState = DEAMON_STATE_RUN;
};

const scanFile = async (bucket, key) => {
    const fileInfo = await getFileInfo(bucket, key);

    // skip scanning large files
    if (fileInfo.ContentLength > MAX_FILE_SIZE) {
        await tagFile(bucket, key, FILE_STATUS_SKIPPED);

        return FILE_STATUS_SKIPPED;
    }

    try {
        await downloadFile(bucket, key);
    } catch (e) {
        throw new Error('Error with downloading file from S3');
    }

    const filename = path.basename(key);

    let status;

    try {
        execSync(`./clamdscan -c ./clamd.conf '/tmp/${filename}'`);

        status = FILE_STATUS_CLEAN;
    } catch (e) {
        if (e.status === 1) {
            status = FILE_STATUS_INFECTED;
        } else {
            status = FILE_STATUS_PROCESSING_ERROR;
        }
    }

    fs.unlinkSync(`/tmp/${filename}`);
    await tagFile(bucket, key, status);

    return status;
};

const updateDefinitions = () => {
    execSync('rm -rf /tmp/*');

    execSync('./freshclam --config-file=freshclam.conf --datadir=/tmp/');

    return Promise.all(clamavDefinitionFiles.map((file) => {
        const fileKey = PATH_TO_AV_DEFINITIONS
            ? `${PATH_TO_AV_DEFINITIONS}/${file}`
            : file;

        return uploadFile(CLAMAV_BUCKET_NAME, fileKey);
    }));
};

module.exports = {
    runDeamon,
    scanFile,
    updateDefinitions,
};
