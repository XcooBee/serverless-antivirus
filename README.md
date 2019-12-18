# Lambda AV Deamon

ClamAV deamon implementations with AWS Lambda.

# Getting started

## Initialize packages
```bash
npm i --only=prod
```

## Build

Build is don with using Amazon Linux Docker

```bash
./build_lambda.sh
```

The output will be `lambda.zip`

## Configure

### Environment variables
Required:
```
CLAMAV_BUCKET_NAME - Bucket, where AV definitions will be stored
```

Optional:
```
PATH_TO_AV_DEFINITIONS - Path to AV definitions folder inside CLAMAV_BUCKET_NAME bucket
FILE_STATUS_CLEAN - status, that will be returned if file is clean. Default: CLEAN
FILE_STATUS_INFECTED - status, that will be returned if file is infected. Default: INFECTED
FILE_STATUS_SKIPPED - status, that will be returned if file is bigger than 300MB. Default: SKIPPED
FILE_STATUS_PROCESSING_ERROR - status, that will be returned when something went wrong. Default: PROCESSING_ERROR
METADATA_FILE_STATUS - tag name for status field. Default: av-status
METADATA_FILE_TIMESTAMP - tag name for check timestamp. Default: av-timestamp
WARM_CONCURRENCY - number of hot lambdas you want to keep always ready to rock. Default: 1
```

### Handlers
#### Update Definitions Handler

```
index.updateDefinitionsHandler
```

##### Requirments

Write access to bucket, where definitions will be stored (`CLAMAV_BUCKET_NAME`)

Recommended timeout: `5min`

Recommended memory: `1024MB`


#### Scan File Handler

First run of function will start deamon and then scan file for viruses.

All next invocations will use deamon to scan files, while lambda is warm.

```
index.scanFileHandler
```

##### Requirments

Read access to bucket, where definitions will be stored (`CLAMAV_BUCKET_NAME`)

Read and Tag access to bucket, where file to check is located

Recommended timeout: `5min`

Recommended memory: `2048MB`


##### Event Payload:
```
{
    "bucket": "my-bucket-name", // bucket of file to scan
    "key": "path/to/file.exe" // file key to scan
}
```

##### Output:

Will respond with one of check statuses (`FILE_STATUS_CLEAN`, `FILE_STATUS_INFECTED`, `FILE_STATUS_SKIPPED`, `FILE_STATUS_PROCESSING_ERROR`)

## Keeping always hot

The idea is to check files as quickly as possible.
To do so we set up ClamAV deamon and always call him with `clamdscan` to verify file.
First call (cold start) will take much more time than all other within 1 lambda, because we have to download definitions and start deamon. But anyway after deamon starts lambda will verify your file and return response.
For example: you receive 1 file every minute and you want to check them for viruses. You told av lambda **Hey, check it**. You'll get response let's say in 20 seconds. But. Next file check will take only 300ms. How was that? :)

### Pre-warming

If you want to be always ready to check files in 200ms, you can use warmer to keep lambda always hot.
To do so, you have to configure `CloudWatch` event to call `Scan File` lambda every (TODO: investigate how much) 10-15 minutes.
Payload is `{"warmer":true}`.
And if you have `WARM_CONCURRENCY` set to more than 1, you have to grant lambda permissions to invoke itself and it will create multiple instances ready to check files quickly.