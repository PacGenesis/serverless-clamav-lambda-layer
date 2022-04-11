const { execSync } = require("child_process");
const AWS = require('aws-sdk');
const s3 = new AWS.S3();
//const got = require('got');

module.exports.virusScan = async (event, context) => {
  if (!event.Records) {
    console.log("Not an S3 event invocation!");
    return;
  }

  for (const record of event.Records) {
    if (!record.s3) {
      console.log("Not an S3 Record!");
      continue;
    }
    console.log("ENVIRONMENT VARIABLES\n" + JSON.stringify(process.env, null, 2))
    console.log("EVENT\n" + JSON.stringify(event, null, 2))
    const signedUrl = s3.getSignedUrl("getObject", {
      Key: record.s3.object.key,
      Bucket: record.s3.bucket.name,
      Expires: 900, // 15 minutes
    });
    try { 
      // scan it by streaming.  Gets around the storage limitation of lambda functions.
      console.log(signedUrl)
      console.log("begin streaming to clamav")
      const scanStatus = execSync(`curl -ks "${signedUrl}" | clamscan - --database=/opt/var/lib/clamav`);
      //console.log(scanStatus)
      await s3
        .putObjectTagging({
          Bucket: record.s3.bucket.name,
          Key: record.s3.object.key,
          Tagging: {
            TagSet: [
              {
                Key: 'av-status',
                Value: 'clean'
              }
            ]
          }
        })
        .promise();
    } catch(err) {
      console.log('failed')
      if (err.status === 1) {
        // tag as dirty, OR you can delete it
        await s3
          .putObjectTagging({
            Bucket: record.s3.bucket.name,
            Key: record.s3.object.key,
            Tagging: {
              TagSet: [
                {
                  Key: 'av-status',
                  Value: 'dirty'
                }
              ]
            }
          })
          .promise();
      }
    }

  }
};
