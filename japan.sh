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
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Secure 443 - Load Balancer</title>
    <style>
      body {
        margin: 0;
        background: url('https://japan-2025.s3.us-east-1.amazonaws.com/japan-bg.jpg') no-repeat center center fixed;
        background-size: cover;
        color: #ffffff;
        font-family: Arial, Helvetica, sans-serif;
        text-align: center;
      }
      .wrap {
        padding: 24px 16px 48px;
        background: rgba(0, 0, 0, 0.35);
        min-height: 100vh;
      }
      h1 { margin: 0.2em 0; }

      /* Image row */
      .image-row {
        display: flex;
        justify-content: center;
        align-items: stretch;       /* keep heights aligned if different aspect ratios */
        gap: 20px;
        flex-wrap: wrap;            /* stacks on small screens */
        margin: 24px auto 8px;
        max-width: 1200px;
      }
      .image-row a {
        display: block;
        width: 45%;
        max-width: 100%;
      }
      .image-row img {
        display: block;
        width: 100%;
        height: auto;               /* proportional scaling */
        border-radius: 10px;
        box-shadow: 0 6px 18px rgba(0,0,0,0.35);
        transition: transform 150ms ease, box-shadow 150ms ease;
      }
      .image-row img:hover {
        transform: translateY(-2px);
        box-shadow: 0 10px 24px rgba(0,0,0,0.45);
      }

      .details {
        font-size: 1.125rem; /* ~18px */
        text-align: left;
        width: min(800px, 92%);
        margin: 24px auto 0;
        background: rgba(0, 0, 0, 0.5);
        padding: 16px 18px;
        border-radius: 10px;
        line-height: 1.5;
      }
      .label { font-weight: bold; }
    </style>
  </head>
  <body>
    <div class="wrap">
      <h1>Class 6 is Secure</h1>

      <div class="image-row">
        <a href="https://japan-2025.s3.us-east-1.amazonaws.com/japan1.jpg" target="_blank" rel="noopener">
          <img src="https://japan-2025.s3.us-east-1.amazonaws.com/japan1.jpg" alt="Japan image 1" loading="lazy">
        </a>
        <a href="https://japan-2025.s3.us-east-1.amazonaws.com/japan2.jpg" target="_blank" rel="noopener">
          <img src="https://japan-2025.s3.us-east-1.amazonaws.com/japan2.jpg" alt="Japan image 2" loading="lazy">
        </a>
      </div>

      <div class="details">
        <h2>In Southeast Asia w/ these Beauties</h2>
        <p><span class="label">Instance Name:</span> $(hostname -f)</p>
        <p><span class="label">Instance Private IP Address:</span> ${local_ipv4}</p>
        <p><span class="label">Availability Zone:</span> ${az}</p>
        <p><span class="label">Virtual Private Cloud (VPC):</span> ${vpc}</p>
      </div>
    </div>
  </body>
</html>
" > /var/www/html/index.html

# Clean up the temp files
rm -f /tmp/local_ipv4 /tmp/az /tmp/macid