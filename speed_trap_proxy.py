#!/usr/bin/env python3
"""
Speed Trap Webhook Proxy - Prevents game lag from Discord uploads
Acts as a local webhook endpoint that buffers and forwards to Discord asynchronously
"""

import os
import json
import time
import requests
import threading
from pathlib import Path
from queue import Queue, Empty
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
import logging
import cgi

# Configuration
PROXY_PORT = 8083  # Local proxy port
REAL_WEBHOOK_URL = None  # Will be loaded from config
WEBHOOK_QUEUE = Queue(maxsize=100)  # Limit queue size
BUFFER_DIR = Path("/home/acserver/server/speed_trap_buffer")
BUFFER_DIR.mkdir(exist_ok=True)

# Logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    handlers=[
        logging.FileHandler(BUFFER_DIR / "webhook_proxy.log"),
        logging.StreamHandler()
    ]
)
log = logging.getLogger(__name__)

# Rate limiting
MIN_DELAY_BETWEEN_SENDS = 0.5  # 500ms between uploads (smooth, no spam)
MAX_RETRIES = 3
RETRY_DELAY = 5

# Stats
stats = {
    'total_received': 0,
    'total_sent': 0,
    'total_failed': 0,
    'total_dropped': 0,
    'avg_delay_ms': 0
}

STATS_FILE = Path("/home/acserver/server/_utils/speed_trap_stats.json")


def save_violation_stats(webhook_data):
    """Save violation data for leaderboard tracking"""
    try:
        # Extract violation info from webhook data
        data = webhook_data.get('data', {})
        
        # Parse the message template to extract fields
        if isinstance(data, dict) and 'content' in data:
            content = data['content']
            violation = {
                'timestamp': datetime.now().isoformat(),
                'raw_content': content
            }
            
            # Try to extract structured data from content
            lines = content.split('\n')
            for line in lines:
                if '**Driver:**' in line:
                    violation['driver'] = line.split('`')[1] if '`' in line else 'Unknown'
                elif '**Speed:**' in line:
                    violation['speed'] = line.split('`')[1].replace(' km/h', '') if '`' in line else '0'
                elif '**Limit:**' in line:
                    violation['limit'] = line.split('`')[1].replace(' km/h', '') if '`' in line else '0'
                elif '**Over Limit:**' in line:
                    violation['over_limit'] = line.split('`')[1].replace(' km/h', '') if '`' in line else '0'
                elif '**Camera:**' in line:
                    violation['camera'] = line.split('`')[1] if '`' in line else 'Unknown'
            
            # Load existing stats
            if STATS_FILE.exists():
                with open(STATS_FILE, 'r') as f:
                    stats_data = json.load(f)
            else:
                stats_data = {'violations': [], 'last_updated': None}
            
            # Add new violation
            stats_data['violations'].append(violation)
            stats_data['last_updated'] = datetime.now().isoformat()
            
            # Keep last 1000 violations
            if len(stats_data['violations']) > 1000:
                stats_data['violations'] = stats_data['violations'][-1000:]
            
            # Save
            with open(STATS_FILE, 'w') as f:
                json.dump(stats_data, f, indent=2)
                
    except Exception as e:
        log.error(f"Error saving violation stats: {e}")



class WebhookProxyHandler(BaseHTTPRequestHandler):
    """HTTP handler that receives webhooks and queues them"""
    
    def log_message(self, format, *args):
        """Override to use our logger"""
        pass  # Suppress default HTTP logging
    
    def do_POST(self):
        """Handle incoming webhook POST"""
        try:
            receive_time = time.time()
            
            # Parse content type
            content_type = self.headers.get('Content-Type', '')
            
            if 'multipart/form-data' in content_type:
                # Handle file upload (speed trap image)
                form = cgi.FieldStorage(
                    fp=self.rfile,
                    headers=self.headers,
                    environ={
                        'REQUEST_METHOD': 'POST',
                        'CONTENT_TYPE': content_type
                    }
                )
                
                # Extract JSON data and file
                webhook_data = {
                    'url': REAL_WEBHOOK_URL,
                    'files': {},
                    'data': {},
                    'receive_time': receive_time
                }
                
                for key in form.keys():
                    item = form[key]
                    if item.filename:
                        # It's a file
                        webhook_data['files'][key] = (
                            item.filename,
                            item.file.read(),
                            item.type
                        )
                    else:
                        # It's form data
                        webhook_data['data'][key] = item.value
                
            else:
                # Handle JSON webhook
                content_length = int(self.headers.get('Content-Length', 0))
                body = self.rfile.read(content_length)
                
                webhook_data = {
                    'url': REAL_WEBHOOK_URL,
                    'data': json.loads(body) if body else {},
                    'files': None,
                    'receive_time': receive_time
                }
            
            # Queue for async sending (non-blocking)
            if WEBHOOK_QUEUE.full():
                stats['total_dropped'] += 1
                log.warning("⚠️ Queue full, dropping webhook")
                self.send_response(503)
                self.end_headers()
                self.wfile.write(b'{"error": "Queue full"}')
                return
            
            WEBHOOK_QUEUE.put(webhook_data)
            stats['total_received'] += 1
            
            # Also save to statistics file for leaderboard
            try:
                save_violation_stats(webhook_data)
            except Exception as e:
                log.error(f"Failed to save stats: {e}")
            
            # Respond immediately (game doesn't wait)
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = {
                'status': 'queued',
                'queue_size': WEBHOOK_QUEUE.qsize(),
                'message': 'Webhook queued for processing'
            }
            self.wfile.write(json.dumps(response).encode())
            
            log.info(f"📸 Webhook received and queued (Queue: {WEBHOOK_QUEUE.qsize()})")
            
        except Exception as e:
            log.error(f"Error handling webhook: {e}")
            self.send_response(500)
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())


def send_webhook(webhook_url, data, files=None, retries=0):
    """Send webhook with retry logic"""
    try:
        if files:
            # Prepare multipart upload
            files_dict = {}
            for key, (filename, content, mimetype) in files.items():
                files_dict[key] = (filename, content, mimetype)
            
            response = requests.post(
                webhook_url,
                data=data,
                files=files_dict,
                timeout=15
            )
        else:
            # JSON webhook
            response = requests.post(
                webhook_url,
                json=data,
                timeout=15
            )
        
        if response.status_code in [200, 201, 204]:
            stats['total_sent'] += 1
            return True
        elif response.status_code == 429:  # Rate limited
            retry_after = int(response.headers.get('Retry-After', RETRY_DELAY))
            log.warning(f"⏱️ Rate limited, waiting {retry_after}s")
            time.sleep(retry_after)
            if retries < MAX_RETRIES:
                return send_webhook(webhook_url, data, files, retries + 1)
        else:
            log.error(f"❌ Webhook failed: {response.status_code}")
            stats['total_failed'] += 1
            return False
            
    except requests.exceptions.Timeout:
        log.warning(f"⏱️ Timeout (attempt {retries + 1}/{MAX_RETRIES})")
        if retries < MAX_RETRIES:
            time.sleep(RETRY_DELAY)
            return send_webhook(webhook_url, data, files, retries + 1)
        stats['total_failed'] += 1
        return False
        
    except Exception as e:
        log.error(f"❌ Webhook error: {e}")
        stats['total_failed'] += 1
        return False


def webhook_worker():
    """Background worker that sends webhooks from queue"""
    log.info("🚀 Webhook worker started")
    last_send_time = 0
    delays = []
    
    while True:
        try:
            # Get next webhook (blocking with timeout)
            webhook_data = WEBHOOK_QUEUE.get(timeout=1)
            
            # Calculate delay
            processing_delay = (time.time() - webhook_data['receive_time']) * 1000
            delays.append(processing_delay)
            if len(delays) > 100:
                delays.pop(0)
            stats['avg_delay_ms'] = sum(delays) / len(delays)
            
            # Rate limiting - smooth delivery
            time_since_last = time.time() - last_send_time
            if time_since_last < MIN_DELAY_BETWEEN_SENDS:
                sleep_time = MIN_DELAY_BETWEEN_SENDS - time_since_last
                time.sleep(sleep_time)
            
            # Send webhook
            url = webhook_data['url']
            data = webhook_data['data']
            files = webhook_data['files']
            
            success = send_webhook(url, data, files)
            if success:
                log.info(f"✓ Sent to Discord (Delay: {processing_delay:.0f}ms, Queue: {WEBHOOK_QUEUE.qsize()})")
            
            last_send_time = time.time()
            WEBHOOK_QUEUE.task_done()
            
        except Empty:
            continue
        except Exception as e:
            log.error(f"Worker error: {e}")
            time.sleep(1)


def load_config():
    """Load real webhook URL from speed_trap_proxy.conf"""
    global REAL_WEBHOOK_URL
    
    config_file = Path("/home/acserver/server/speed_trap_proxy.conf")
    try:
        with open(config_file, 'r') as f:
            for line in f:
                if line.startswith('REAL_DISCORD_WEBHOOK='):
                    REAL_WEBHOOK_URL = line.split('=', 1)[1].strip()
                    log.info(f"✓ Loaded webhook URL: {REAL_WEBHOOK_URL[:50]}...")
                    return True
    except Exception as e:
        log.error(f"Failed to load webhook URL: {e}")
        return False
    
    log.error("Could not find REAL_DISCORD_WEBHOOK in config")
    return False


def start_proxy():
    """Start the webhook proxy server"""
    if not load_config():
        log.error("Cannot start without webhook URL")
        return None
    
    # Start worker thread
    worker = threading.Thread(target=webhook_worker, daemon=True)
    worker.start()
    
    # Start HTTP server
    server = HTTPServer(('127.0.0.1', PROXY_PORT), WebhookProxyHandler)
    log.info(f"✓ Proxy listening on http://127.0.0.1:{PROXY_PORT}")
    log.info(f"✓ Forwarding to: {REAL_WEBHOOK_URL[:50]}...")
    log.info(f"✓ Rate limit: {MIN_DELAY_BETWEEN_SENDS}s between sends")
    
    return server


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Speed Trap Webhook Proxy")
    parser.add_argument('--run', action='store_true', help='Run the proxy server')
    parser.add_argument('--stats', action='store_true', help='Show stats')
    args = parser.parse_args()
    
    if args.stats:
        print(json.dumps(stats, indent=2))
    elif args.run:
        log.info("="*70)
        log.info("🚀 Speed Trap Webhook Proxy Starting")
        log.info("="*70)
        
        server = start_proxy()
        if server:
            try:
                # Log stats every minute
                def log_stats():
                    while True:
                        time.sleep(60)
                        log.info(f"📊 Stats: Received={stats['total_received']}, "
                                f"Sent={stats['total_sent']}, Failed={stats['total_failed']}, "
                                f"Dropped={stats['total_dropped']}, Avg Delay={stats['avg_delay_ms']:.0f}ms, "
                                f"Queue={WEBHOOK_QUEUE.qsize()}")
                
                stats_thread = threading.Thread(target=log_stats, daemon=True)
                stats_thread.start()
                
                server.serve_forever()
            except KeyboardInterrupt:
                log.info("\n⛔ Shutting down...")
                server.shutdown()
    else:
        parser.print_help()
