import argparse
import boto3
import time
import random
import json
from datetime import datetime, timedelta

def generate_log_events(log_group_name, days_back):
    events = []
    
    if log_group_name == "/ecs/nexus-platform":
        templates = [
            {"level":"INFO","service":"data-processor","message":"Processing batch {batch}, {records} records"},
            {"level":"INFO","service":"auth-service","message":"Token validation successful for user {user}"},
            {"level":"WARNING","service":"data-processor","message":"Memory usage at 78%, approaching threshold"},
            {"level":"ERROR","service":"data-processor","message":"OutOfMemoryError: Java heap space — container will restart"},
            {"level":"ERROR","service":"auth-service","message":"Failed to connect to nexus-db-primary after 3 retries: connection refused"},
            {"level":"FATAL","service":"data-processor","message":"Container exiting with code 137 (OOMKilled)"},
            {"level":"INFO","service":"data-processor","message":"Container restarted. Resuming from checkpoint batch-{batch_next}"}
        ]
    elif log_group_name == "/aws/lambda/nexus-billing-webhook":
        templates = [
            "START RequestId: {req} Version: $LATEST",
            '{{"level":"INFO","requestId":"{req}","message":"Stripe webhook received: payment_intent.succeeded","amount":2499,"currency":"usd"}}',
            '{{"level":"INFO","requestId":"{req}","message":"Updating subscription status for customer {cus}"}}',
            "END RequestId: {req}",
            "REPORT RequestId: {req} Duration: 234.12 ms Billed Duration: 235 ms Memory Size: 512 MB Max Memory Used: 87 MB",
            "START RequestId: {req2} Version: $LATEST",
            '{{"level":"ERROR","requestId":"{req2}","message":"Stripe webhook signature verification failed","error":"No signatures found matching the expected signature"}}',
            "END RequestId: {req2}",
            "REPORT RequestId: {req2} Duration: 12.34 ms Billed Duration: 13 ms Memory Size: 512 MB Max Memory Used: 45 MB",
            "START RequestId: {req3} Version: $LATEST",
            '{{"level":"ERROR","requestId":"{req3}","message":"Timeout after 29847ms connecting to payment processor","retryCount":3}}',
            "END RequestId: {req3}",
            "REPORT RequestId: {req3} Duration: 30001.23 ms Billed Duration: 30001 ms Memory Size: 512 MB Max Memory Used: 92 MB"
        ]
    elif log_group_name == "/aws/lambda/nexus-email-trigger":
        templates = [
            "START RequestId: {req} Version: $LATEST",
            '{{"level":"INFO","message":"Dispatching welcome email to user@example.com","template":"onboarding-v3"}}',
            '{{"level":"INFO","message":"Email delivered successfully","messageId":"<msg-abc123@nexustech.io>"}}',
            '{{"level":"WARNING","message":"SendGrid daily quota at 87% (8700/10000 emails)","resetAt":"{reset}"}}',
            "END RequestId: {req}",
            "REPORT RequestId: {req} Duration: 154.12 ms Billed Duration: 155 ms Memory Size: 256 MB Max Memory Used: 64 MB"
        ]
    elif log_group_name == "/aws/lambda/nexus-report-generator":
        templates = [
            '{{"level":"INFO","message":"Generating Q3 analytics report for tenant {tenant}","reportType":"quarterly"}}',
            '{{"level":"INFO","message":"Querying 2.4M records from nexus-events DynamoDB table"}}',
            '{{"level":"WARNING","message":"Report generation took 28340ms, exceeding SLA threshold of 25000ms"}}',
            '{{"level":"INFO","message":"Report uploaded to s3://nexus-platform-backups-{{account}}/reports/{tenant}-Q3-2026.pdf"}}'
        ]
    elif log_group_name == "/rds/nexus-db-primary":
        templates = [
            "{time} UTC [INFO] connection received: host=10.0.1.45 port=52341 pid={pid}",
            "{time} UTC [INFO] connection authorized: user=nexusadmin database=nexusdb SSL enabled",
            "{time} UTC [WARNING] duration: 8427 ms  statement: SELECT ae.*, u.email FROM analytics_events ae JOIN users u ON ae.user_id = u.id WHERE ae.created_at > NOW() - INTERVAL '30 days' AND ae.tenant_id = '{tenant}'",
            "{time} UTC [ERROR] deadlock detected on relation 21847 of database 16384",
            "{time} UTC [INFO] process {pid1} detected deadlock with process {pid2}, aborting",
            "{time} UTC [INFO] checkpoint starting: time",
            "{time} UTC [INFO] checkpoint complete: wrote 1847 buffers (11.2%); 0 WAL file(s) added"
        ]
    elif log_group_name == "/aws/apigateway/nexus-api":
        templates = [
            '{{"requestId":"{req}","ip":"34.89.221.4","caller":"-","user":"-","requestTime":"{time}","httpMethod":"GET","resourcePath":"/api/v2/dashboard","status":"200","protocol":"HTTP/1.1","responseLength":"4821"}}',
            '{{"requestId":"{req2}","ip":"185.220.101.3","caller":"-","user":"-","requestTime":"{time}","httpMethod":"GET","resourcePath":"/api/v2/analytics","status":"500","protocol":"HTTP/1.1","responseLength":"87","error":"Internal Server Error — empty result set from nexus-db-primary"}}',
            '{{"requestId":"{req3}","ip":"103.21.244.0","caller":"-","user":"-","requestTime":"{time}","httpMethod":"POST","resourcePath":"/api/v2/events","status":"429","protocol":"HTTP/1.1","responseLength":"45","error":"Rate limit exceeded"}}',
            '{{"requestId":"{req4}","ip":"10.0.1.45","caller":"-","user":"-","requestTime":"{time}","httpMethod":"GET","resourcePath":"/api/v2/admin/users","status":"403","protocol":"HTTP/1.1","responseLength":"31"}}'
        ]
    else:
        templates = ['{{"level":"INFO","message":"Generic log entry"}}']

    now = datetime.utcnow()
    target_date = now - timedelta(days=days_back)
    
    num_events = random.randint(60, 100)
    for _ in range(num_events):
        offset_seconds = random.randint(0, 86400)
        event_time = target_date.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(seconds=offset_seconds)
        timestamp = int(event_time.timestamp() * 1000)
        
        template = random.choice(templates)
        
        if isinstance(template, dict):
            msg = dict(template)
            msg['timestamp'] = event_time.isoformat() + "Z"
            if '{batch}' in msg.get('message', ''):
                b = random.randint(1000, 9999)
                msg['message'] = msg['message'].format(batch=b, records=random.randint(10, 500), batch_next=b+1)
            elif '{user}' in msg.get('message', ''):
                msg['message'] = msg['message'].format(user=f"u-{random.randint(1000, 9999):x}")
            message = json.dumps(msg)
        else:
            message = template.format(
                req=f"req-{random.randint(100000, 999999):x}",
                req2=f"req-{random.randint(100000, 999999):x}",
                req3=f"req-{random.randint(100000, 999999):x}",
                req4=f"req-{random.randint(100000, 999999):x}",
                cus=f"cus_NxT{random.randint(1000, 9999):x}",
                reset=(event_time + timedelta(days=1)).strftime("%Y-%m-%dT00:00:00Z"),
                tenant=f"t-{random.randint(1000, 9999)}",
                time=event_time.strftime("%Y-%m-%d %H:%M:%S") if "UTC" in template else event_time.strftime("%d/%b/%Y:%H:%M:%S"),
                pid=random.randint(10000, 20000),
                pid1=random.randint(10000, 20000),
                pid2=random.randint(10000, 20000)
            )
        
        events.append({
            'timestamp': timestamp,
            'message': message
        })
        
    return sorted(events, key=lambda x: x['timestamp'])

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--region', default='us-east-1')
    parser.add_argument('--profile', default=None)
    args = parser.parse_args()

    session = boto3.Session(profile_name=args.profile, region_name=args.region)
    logs = session.client('logs')

    log_groups = [
        "/ecs/nexus-platform",
        "/aws/lambda/nexus-billing-webhook",
        "/aws/lambda/nexus-email-trigger",
        "/aws/lambda/nexus-report-generator",
        "/rds/nexus-db-primary",
        "/aws/apigateway/nexus-api"
    ]
    
    total_events = 0
    now = datetime.utcnow()

    for log_group in log_groups:
        print(f"Seeding log group: {log_group}...")
        try:
            logs.create_log_group(logGroupName=log_group)
        except logs.exceptions.ResourceAlreadyExistsException:
            pass
            
        group_events = 0
        
        for days_back in range(7):
            target_date = now - timedelta(days=days_back)
            stream_name = f"nexus-platform/{target_date.strftime('%Y/%m/%d')}"
            
            try:
                logs.create_log_stream(logGroupName=log_group, logStreamName=stream_name)
            except logs.exceptions.ResourceAlreadyExistsException:
                pass
                
            events = generate_log_events(log_group, days_back)
            
            if not events:
                continue
                
            try:
                logs.put_log_events(
                    logGroupName=log_group,
                    logStreamName=stream_name,
                    logEvents=events
                )
                group_events += len(events)
            except logs.exceptions.InvalidSequenceTokenException as e:
                token = e.response['Error']['Message'].split("sequenceToken is: ")[1]
                logs.put_log_events(
                    logGroupName=log_group,
                    logStreamName=stream_name,
                    logEvents=events,
                    sequenceToken=token
                )
                group_events += len(events)
            except Exception as e:
                print(f"  Error putting events in {stream_name}: {e}")
                
        print(f"  Seeded {group_events} events")
        total_events += group_events

    print(f"\nDone! Total events seeded: {total_events}")

if __name__ == "__main__":
    main()
