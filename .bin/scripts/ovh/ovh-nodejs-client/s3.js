import AWS from "aws-sdk";
import { fs } from "fs";

// How to recover data from app vault ?
/*
const { endpoint, region, bucket, accessKeyId, secretAccessKey } = config.s3;

AWS.config.update({
  accessKeyId,
  secretAccessKey,
});
*/

const repository = new AWS.S3({ endpoint, region });

export async function uploadFileToS3(client, pathToFile) {
  const blob = fs.readFileSync(filePath);

  await repository
    .upload({
      Key: key,
      Body: blob,
      Bucket: bucket,
    })
    .promise();
}
