# Lambda AV Deamon

ClamAV deamon implementations with AWS Lambda.

## Purpose

Using Lambda as container for Antivirus allows serverless deployements but has a few issues. The main one we are overcoming is the time-to-start. It may take 30s or more for the instance to be able to scan files. If you have frequently a few files to scan this can add up. The XcooBee Antivirus container drastically speeds up the startup-time of the Lambda instance for the purpose of scanning virus loads on files. We do this by creating a memory resident service (daemon) with definitions already loaded. The service can respond to scan request nearly instantaneously. 

## Implementation 

We have split the process into two components both contained in the same repo.

a) Scan Files and install deamon (service)
b) Update definitions

We recommend that you to deploy the same code to two lambda functions. One for purposes of updating definition and the other for running your scans. 
Your event payload determines the behavhior.

## Issues

If you wish to keep a warm instance to avoid coldstarts you will have to use the classic CloudWatch event methodology.
You cannot use the AWS based warming functions since those do not call the needed handler to create the service. 

# Getting started

## Initialize packages
```bash
npm i --only=prod
```

## Build

Build is on with using Amazon Linux Docker

```bash
./build_lambda.sh
```

The output will be `lambda.zip`

## Configure

Configuration is done by specifying environmental variables on the Lambda instance. We assume two different Lambda function will be used.

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

For the Update AV definition Function:

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
To do so we set up ClamAV deamon and always call it with `clamdscan` to verify file(s).
On first call (cold start) this will take much more time. This is because we have to download definitions and start deamon. 
After the deamon has been started the process will verify your file and return a response.

Example use case: 
 
 - You receive 1 file every minute and you want to check it for viruses. The first check may require 20-30s since the lambda has to load all defs and services. Subsequent file checks will take only 300ms. How is that? :)

### Pre-warming

If you want to be always ready to check files in 200ms, you can use warmer to keep lambda warm.
To do so, you have to configure `CloudWatch` event to call `Scan File` lambda every (TODO: investigate how much) 10-15 minutes.
Payload should be `{"warmer":true}`.
If you wish to use multiple warm instances you need to specify `WARM_CONCURRENCY` environmental variable with the number of concurrent warm instances that you wish to have.
Please note that if you have `WARM_CONCURRENCY` set to more than 1, you have to also grant lambda permissions to invoke itself. This will create multiple instances ready to check files quickly.
