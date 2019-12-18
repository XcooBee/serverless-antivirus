const AWS = require('aws-sdk'); // eslint-disable-line
const fs = require('fs');
const path = require('path');

const {
    METADATA_FILE_STATUS = 'av-status',
    METADATA_FILE_TIMESTAMP = 'av-timestamp',
} = process.env;

const s3 = new AWS.S3();

const getFileInfo = (bucket, key) => s3.headObject({
    Bucket: bucket,
    Key: key,
}).promise();

const downloadFile = (bucket, key) => new Promise((resolve, reject) => {
    const filename = path.basename(key);

    const stream = s3.getObject({
        Bucket: bucket,
        Key: key,
    })
        .createReadStream()
        .on('end', resolve)
        .on('error', reject);

    stream.pipe(fs.createWriteStream(`/tmp/${filename}`));
});

const uploadFile = (bucket, key) => {
    const filename = path.basename(key);

    return s3.putObject({
        Bucket: bucket,
        Key: key,
        Body: fs.createReadStream(`/tmp/${filename}`),
    }).promise();
};

const tagFile = (bucket, key, status) => {
    const params = {
        Bucket: bucket,
        Key: key,
        Tagging: {
            TagSet: [
                {
                    Key: METADATA_FILE_STATUS,
                    Value: status,
                },
                {
                    Key: METADATA_FILE_TIMESTAMP,
                    Value: new Date().getTime().toString(),
                },
            ],
        }
    };

    return s3.putObjectTagging(params).promise();
};

module.exports = {
    getFileInfo,
    downloadFile,
    uploadFile,
    tagFile,
};
