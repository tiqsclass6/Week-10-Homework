#!/bin/bash
# Use this for your user data (script from top to bottom)
# install httpd (Linux 2 version)
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Get the IMDSv2 token
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Background the curl requests
curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4 &> /tmp/local_ipv4 &
curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone &> /tmp/az &
curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ &> /tmp/macid &
wait

macid=$(cat /tmp/macid)
local_ipv4=$(cat /tmp/local_ipv4)
az=$(cat /tmp/az)
vpc=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${macid}/vpc-id)

echo "
<!doctype html>
<html lang="en" class="h-100">
  <head>
    <meta charset="UTF-8">
    <title>Details for EC2 instance</title>
    <style>
      body {
        background: url('https://brazil-2025.s3.us-east-1.amazonaws.com/brazil-bg.jpg') no-repeat center center fixed;
        background-size: cover;
        color: #ffffff;
        font-family: Arial, sans-serif;
        text-align: center;
      }
      .image-container {
        display: flex;
        justify-content: center;
        align-items: center;
        gap: 20px;
        flex-wrap: wrap; /* keeps layout responsive on smaller screens */
        margin-top: 20px;
      }
      .image-container img {
        width: 45%;
        height: auto;
        border-radius: 10px;
        object-fit: contain;
      }
      .details {
        font-size: 1.2em;
        text-align: center;
        width: 60%;
        margin: 30px auto;
        background: rgba(0, 0, 0, 0.5);
        padding: 20px;
        border-radius: 10px;
      }
    </style>
  </head>
  <body>
    <h1>Theo's Brazilian Blondes</h1>

    <div class="image-container">
      <img src="https://brazil-2025.s3.us-east-1.amazonaws.com/brazil4.jpg" alt="Brazil Image 1">
      <img src="https://brazil-2025.s3.us-east-1.amazonaws.com/brazil2.jpg" alt="Brazil Image 2">
    </div>

    <div class="details">
      <h2>AWS Instance Details</h2>
      <p><b>Instance Name:</b> $(hostname -f)</p>
      <p><b>Instance Private IP Address:</b> ${local_ipv4}</p>
      <p><b>Availability Zone:</b> ${az}</p>
      <p><b>Virtual Private Cloud (VPC):</b> ${vpc}</p>
    </div>
  </body>
</html>
" > /var/www/html/index.html

# Clean up the temp files
rm -f /tmp/local_ipv4 /tmp/az /tmp/macid