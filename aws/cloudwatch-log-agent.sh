#!/bin/bash

set -euf -o pipefail
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/bin/
sudo tee "/opt/aws/amazon-cloudwatch-agent/bin/config.json" > /dev/null <<'EOF'
{
    "agent": {
            "metrics_collection_interval": 60,
            "run_as_user": "root"
    },
    "logs": {
            "logs_collected": {
                    "files": {
                            "collect_list": [
                                    {
                                            "file_path": "/var/log/audit/audit.log",
                                            "log_group_name": "/ec2/ssh",
                                            "log_stream_name": "{instance_id}",
                                            "retention_in_days": 30
                                    }
                            ]
                    }
            }
    },
    "metrics": {
            "aggregation_dimensions": [
                    [
                            "InstanceId"
                    ]
            ],
            "append_dimensions": {
                    "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
                    "ImageId": "${aws:ImageId}",
                    "InstanceId": "${aws:InstanceId}",
                    "InstanceType": "${aws:InstanceType}"
            },
            "metrics_collected": {
                    "collectd": {
                            "metrics_aggregation_interval": 60
                    },
                    "disk": {
                            "measurement": [
                                    "used_percent"
                            ],
                            "metrics_collection_interval": 60,
                            "resources": [
                                    "*"
                            ]
                    },
                    "mem": {
                            "measurement": [
                                    "mem_used_percent"
                            ],
                            "metrics_collection_interval": 60
                    },
                    "statsd": {
                            "metrics_aggregation_interval": 60,
                            "metrics_collection_interval": 30,
                            "service_address": ":8125"
                    }
            }
    }
}
EOF

OS_INFO=$(cat /etc/os-release | grep NAME)
echo $OS_INFO

if [[ $OS_INFO =~ 'Amazon' ]]; then
    sudo yum install -y collectd amazon-cloudwatch-agent
fi

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
