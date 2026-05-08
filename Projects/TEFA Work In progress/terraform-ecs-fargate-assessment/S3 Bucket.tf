# resource "aws_s3_bucket" "my_procode_bucket_for_logs" {
#   bucket = "procode-logs-${random_id.logs_bucket_suffix.hex}"

#   tags = {
#     Name        = "Logging bucket"
#     Environment = "Dev"
#   }
# }
# resource "random_id" "logs_bucket_suffix" {
#   byte_length = 4
# }

# resource "aws_s3_bucket_policy" "logs_bucket_policy" {
#   bucket = aws_s3_bucket.my_procode_bucket_for_logs.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AllowCloudFrontAccessLogs"
#         Effect = "Allow"
#         Principal = {
#           Service = "cloudfront.amazonaws.com"
#         }
#         Action   = "s3:PutObject"
#         Resource = "${aws_s3_bucket.my_procode_bucket_for_logs.arn}/cloudfront-access-logs/*"
#       }
#       # {
#       #   # Sid    = "AllowALBAccessLogs"
#       #   # Effect = "Allow"
#       #   # Principal = {
#       #   #   Service = "elasticloadbalancing.amazonaws.com"
#       #   # }
#       #   # Action = [
#       #   #    "s3:PutObject",
#       #   #    "s3:PutObjectAcl"
#       #   # ]
#       #   Resource = "${aws_s3_bucket.my_procode_bucket_for_logs.arn}/alb-access-logs/*"
#       # }
#     ]
#   })
# }
