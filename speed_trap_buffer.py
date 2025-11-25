#!/usr/bin/env python3
"""
Speed Trap Webhook Buffer - Prevents game lag from instant Discord uploads
Queues speed trap webhooks and sends them asynchronously with rate limiting
"""

import os
import json
import time
import requests
import threading
from pathlib import Path
from queue import Queue, Empty
from datetime import datetime
import logging

# Configuration
WEBHOOK_QUEUE = Queue()
BUFFER_DIR = Path("/home/acserver/server/speed_trap_buffer")
BUFFER_DIR.mkdir(exist_ok=True)

# Logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    handlers=[
        logging.FileHandler(BUFFER_DIR / "speed_trap_buffer.log"),
        logging.StreamHandler()
    ]
)
log = logging.getLogger(__name__)

# Rate limiting to prevent Discord API spam
MIN_DELAY_BETWEEN_SENDS = 1.0  # Minimum 1 second between uploads
MAX_RETRIES = 3
RETRY_DELAY = 5  # Wait 5 seconds before retrying

# Stats
stats = {
    'total_queued': 0,
    'total_sent': 0,
    'total_failed': 0,
    'queue_size': 0
}


def send_webhook(webhook_url, data, files=None, retries=0):
    """Send webhook with retry logic"""
    try:
        if files:
            response = requests.post(webhook_url, data=data, files=files, timeout=10)
        else:
            response = requests.post(webhook_url, json=data, timeout=10)
        
        if response.status_code in [200, 201, 204]:
            stats['total_sent'] += 1
            log.info(f"✓ Speed trap sent successfully (Queue: {stats['queue_size']})")
            return True
        elif response.status_code == 429:  # Rate limited
            retry_after = int(response.headers.get('Retry-After', RETRY_DELAY))
            log.warning(f"Rate limited by Discord, waiting {retry_after}s")
            time.sleep(retry_after)
            if retries < MAX_RETRIES:
                return send_webhook(webhook_url, data, files, retries + 1)
        else:
            log.error(f"Webhook failed with status {response.status_code}: {response.text}")
            stats['total_failed'] += 1
            return False
            
    except requests.exceptions.Timeout:
        log.warning(f"Webhook timeout (attempt {retries + 1}/{MAX_RETRIES})")
        if retries < MAX_RETRIES:
            time.sleep(RETRY_DELAY)
            return send_webhook(webhook_url, data, files, retries + 1)
        stats['total_failed'] += 1
        return False
        
    except Exception as e:
        log.error(f"Webhook error: {e}")
        stats['total_failed'] += 1
        return False


def webhook_worker():
    """Background worker that sends webhooks from queue"""
    log.info("🚀 Speed trap webhook worker started")
    last_send_time = 0
    
    while True:
        try:
            # Get next webhook from queue (blocking, with timeout)
            webhook_data = WEBHOOK_QUEUE.get(timeout=1)
            stats['queue_size'] = WEBHOOK_QUEUE.qsize()
            
            # Rate limiting - ensure minimum delay between sends
            time_since_last = time.time() - last_send_time
            if time_since_last < MIN_DELAY_BETWEEN_SENDS:
                sleep_time = MIN_DELAY_BETWEEN_SENDS - time_since_last
                log.debug(f"Rate limiting: sleeping {sleep_time:.2f}s")
                time.sleep(sleep_time)
            
            # Send the webhook
            url = webhook_data.get('url')
            data = webhook_data.get('data')
            files = webhook_data.get('files')
            
            send_webhook(url, data, files)
            last_send_time = time.time()
            
            # Mark task as done
            WEBHOOK_QUEUE.task_done()
            
        except Empty:
            # No items in queue, just continue
            continue
            
        except Exception as e:
            log.error(f"Worker error: {e}")
            time.sleep(1)


def queue_speed_trap(webhook_url, message_data, image_path=None):
    """
    Queue a speed trap webhook for async sending
    This returns immediately without blocking the game
    """
    webhook_data = {
        'url': webhook_url,
        'data': {},
        'files': None,
        'timestamp': datetime.now().isoformat()
    }
    
    # Prepare webhook payload
    if image_path and Path(image_path).exists():
        # With image attachment
        webhook_data['data'] = {
            'content': message_data.get('content', ''),
            'username': message_data.get('username', 'Speed Trap')
        }
        # Image will be sent as multipart/form-data
        webhook_data['files'] = {
            'file': (Path(image_path).name, open(image_path, 'rb'), 'image/png')
        }
    else:
        # Text-only webhook
        webhook_data['data'] = message_data
    
    # Add to queue (non-blocking)
    WEBHOOK_QUEUE.put(webhook_data)
    stats['total_queued'] += 1
    stats['queue_size'] = WEBHOOK_QUEUE.qsize()
    
    log.info(f"📸 Speed trap queued (Queue size: {stats['queue_size']})")
    return True


def start_worker():
    """Start the background webhook worker thread"""
    worker_thread = threading.Thread(target=webhook_worker, daemon=True)
    worker_thread.start()
    log.info("✓ Webhook worker thread started")
    return worker_thread


def get_stats():
    """Get current stats"""
    return {
        **stats,
        'queue_size': WEBHOOK_QUEUE.qsize()
    }


if __name__ == "__main__":
    # Test mode
    import argparse
    parser = argparse.ArgumentParser(description="Speed Trap Webhook Buffer")
    parser.add_argument('--test', action='store_true', help='Run test mode')
    parser.add_argument('--stats', action='store_true', help='Show stats')
    parser.add_argument('--daemon', action='store_true', help='Run as daemon')
    args = parser.parse_args()
    
    if args.stats:
        print(json.dumps(get_stats(), indent=2))
    elif args.test:
        log.info("Testing webhook buffer...")
        start_worker()
        
        # Queue test webhook
        test_data = {
            'username': 'Speed Trap Test',
            'content': '🧪 Test webhook from buffer system'
        }
        queue_speed_trap('https://httpbin.org/post', test_data)
        
        log.info("Waiting for queue to process...")
        WEBHOOK_QUEUE.join()
        log.info(f"Stats: {json.dumps(get_stats(), indent=2)}")
        
    elif args.daemon:
        log.info("Running webhook buffer daemon...")
        start_worker()
        try:
            while True:
                time.sleep(60)
                log.info(f"Stats: Queued={stats['total_queued']}, Sent={stats['total_sent']}, Failed={stats['total_failed']}, Queue={WEBHOOK_QUEUE.qsize()}")
        except KeyboardInterrupt:
            log.info("Shutting down...")
    else:
        parser.print_help()
