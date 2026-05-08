# resource "aws_iam_role" "firehose_role" {
#     name = "firehose-waf-logs-role"
#     assume_role_policy = jsonencode({
#         Version = "2012-10-17"
#         Statement = [
#             {
#                 Effect = "Allow"
#                 Principal = {
#                     Service = "firehose.amazonaws.com"
#                 }
#                 Action = "sts:AssumeRole"
#             }
#         ]
#     })
# }

# resource "aws_iam_role_policy" "firehose_policy" {
#     name = "firehose-waf-logs-policy"
#     role = aws_iam_role.firehose_role.id
#     policy = jsonencode({
#         Version = "2012-10-17"
#         Statement = [
#             {
#                 Effect = "Allow"
#                 Action = [
#                     "s3:PutObject",
#                     "s3:PutObjectAcl",
#                     "s3:GetBucketLocation",
#                     "s3:ListBucket"
#                 ]
#                 Resource = [
#                     "${aws_s3_bucket.my_procode_bucket_for_logs.arn}/*"
#                 ]
#             }
#         ]
#     })
# }

# resource "aws_kinesis_firehose_delivery_stream" "waf_logs_stream" {
#     provider = aws.us_east_1
#     name = "waf-logs-stream"
#     destination = "extended_s3"

#     extended_s3_configuration {
#         role_arn = aws_iam_role.firehose_role.arn
#         bucket_arn = aws_s3_bucket.my_procode_bucket_for_logs.arn
#         prefix = "waf-logs/"

#         buffering_interval = 300
#         buffering_size = 5
#         compression_format = "GZIP"
#     }
# }