#!/bin/sh
# Declare the log function
log() {
    echo -e `/bin/date`'\t'${1}
}

log "Initialized mongodb backup script"

set -e

TIMESTAMP=`date +%Y%m%d_%H%M%S`
#OUTPUT_DIR=/db_backups/mongodb_backup
OUTPUT_DIR=/dev/volumes/ebs/db_backups/mongodb_backup

S3KEY=AKIAIEOM3V3IANIBCWJA
S3SECRET=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

DESTINATION_DIRECTORY=/dev/volumes/ebs/db_backups
COMPRESSED_FILENAME=mongodb_backup_${TIMESTAMP}.tar.gz

# Take the DB dump with OPLogs
log "Starting to take DB backup"
mongodump --out $OUTPUT_DIR --oplog -u admin -p g3nuin33l3phant --authenticationDatabase admin

log "Mongo Backup complete"

# Tar the backup folder created above
log "Compressing the backup files"
#/bin/tar -zcvf /db_backups/${COMPRESSED_FILENAME} $OUTPUT_DIR
/bin/tar -zcvf /dev/volumes/ebs/db_backups/${COMPRESSED_FILENAME} $OUTPUT_DIR
log "Compression complete"


bucket='bial-db-backup-prod'
date=$(/bin/date +"%a, %d %b %Y %T %z")
acl="x-amz-acl:private"
content_type='application/x-compressed-tar'
string="PUT\n\n$content_type\n$date\n$acl\n/$bucket/$COMPRESSED_FILENAME"
signature=$(echo -en "${string}" | openssl sha1 -hmac "${S3SECRET}" -binary | base64)

# Upload the compressed file to S3
log "Uploading the compressed backup file to S3"

/usr/bin/curl -X PUT -T "${DESTINATION_DIRECTORY}/${COMPRESSED_FILENAME}" \
-H "Host: $bucket.s3.amazonaws.com" \
-H "Date: $date" \
-H "Content-Type: $content_type" \
-H "$acl" \
-H "Authorization: AWS ${S3KEY}:$signature" \
"https://$bucket.s3-ap-southeast-1.amazonaws.com/$COMPRESSED_FILENAME"

log "Upload complete"

log "Cleaning up the backup files"
rm -rf $OUTPUT_DIR
#rm -rf $COMPRESSED_FILENAME
rm $DESTINATION_DIRECTORY/$COMPRESSED_FILENAME
log "clean up the backup files is completed"

#log "Intializing backup of AODB Proxy Service database"
#ssh bial@10.50.66.13 'bash' < ~/bial/scripts/aps-backup.sh

log "DB Backup complete"

