#!/usr/bin/env python3
import re
import json
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parents[1]
LOGS = ROOT / 'logs'
STATS = LOGS / 'stats'

events = []

def to_iso(ts_str):
    # input like: 2025-11-14 08:59:27.443 +00:00
    try:
        # strip timezone and parse
        base = ts_str.split(' +')[0]
        dt = datetime.strptime(base, '%Y-%m-%d %H:%M:%S.%f')
        return dt.isoformat() + 'Z'
    except Exception:
        # fallback: try alternative formats
        try:
            dt = datetime.strptime(ts_str, '%Y-%m-%d %H:%M:%S')
            return dt.isoformat() + 'Z'
        except Exception:
            return ts_str

def parse_connects():
    pattern = re.compile(r'(?P<ts>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+) \+00:00 \[INF\] (?P<rest>.+) has connected')
    # rest is like: Name (7656119..., 40 (car/ADAn))
    for p in STATS.glob('connects-*.tmp'):
        for line in p.read_text(encoding='utf-8', errors='ignore').splitlines():
            m = pattern.search(line)
            if not m:
                continue
            ts = to_iso(m.group('ts'))
            rest = m.group('rest').strip()
            # try to extract steam id and car
            steam = None
            car = None
            player = rest
            if '(' in rest and rest.endswith(')'):
                # split at first '('
                name, paren = rest.split('(', 1)
                player = name.strip()
                paren = paren.rstrip(')')
                # paren example: '76561198410409040, 40 (ks_nissan_gtr-0_pearl_white/ADAn)'
                parts = paren.split(',', 1)
                if parts:
                    steam = parts[0].strip()
                # find last '(' ... ')' for car inside paren
                car_match = re.search(r'\(([^)]+/ADAn|[^)]+)\)\s*$', '(' + paren + ')')
                if car_match:
                    car = car_match.group(1)
                else:
                    # fallback: try to find something with '/'
                    slash = paren.find('/')
                    if slash != -1:
                        car = paren[paren.rfind('(', 0, slash)+1:paren.rfind(')')] if '(' in paren else paren

            event = {
                'timestamp': ts,
                'player': player,
                'steam_id': steam,
                'car': car,
                'event_type': 'join',
                'value': 1,
                'unit': None,
                'session': None,
                'metadata': {}
            }
            events.append(event)

def parse_disconnects():
    pattern = re.compile(r'(?P<ts>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+) \+00:00 \[INF\] (?P<player>.+) has disconnected')
    # We'll map disconnect to last known connect for steam/car
    last_connect_by_player = {}
    for e in events:
        if e['event_type'] == 'join':
            last_connect_by_player[e['player']] = e

    for p in STATS.glob('disconnects-*.tmp'):
        for line in p.read_text(encoding='utf-8', errors='ignore').splitlines():
            m = pattern.search(line)
            if not m:
                continue
            ts = to_iso(m.group('ts'))
            player = m.group('player').strip()
            steam = None
            car = None
            if player in last_connect_by_player:
                steam = last_connect_by_player[player].get('steam_id')
                car = last_connect_by_player[player].get('car')

            event = {
                'timestamp': ts,
                'player': player,
                'steam_id': steam,
                'car': car,
                'event_type': 'leave',
                'value': 1,
                'unit': None,
                'session': None,
                'metadata': {}
            }
            events.append(event)

def parse_dynamic_traffic():
    dyn = LOGS / 'dynamic_traffic.log'
    if not dyn.exists():
        return
    for line in dyn.read_text(encoding='utf-8', errors='ignore').splitlines():
        # timestamp in [YYYY-MM-DD hh:mm:ss]
        ts_match = re.match(r'\[(?P<ts>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\] ?(?P<msg>.*)', line)
        if not ts_match:
            continue
        ts = ts_match.group('ts')
        msg = ts_match.group('msg')
        # switching to preset
        sw = re.search(r'Switching to .*?([\w\s\u2600-\u26FF\u2700-\u27BF\W]+)$', msg)
        if 'Switching to' in msg:
            # extract preset name after 'Switching to'
            p = msg.split('Switching to',1)[1].strip()
            preset = p.strip().strip('–—- ').lower().replace(' ', '_').replace('☀️','morning').replace('🌤️','afternoon')
            event = {
                'timestamp': ts + 'Z',
                'player': None,
                'steam_id': None,
                'car': None,
                'event_type': 'traffic_change',
                'ai_density': None,
                'preset': preset,
                'value': None,
                'unit': None,
                'session': None,
                'metadata': {}
            }
            events.append(event)
            continue
        # idle traffic changes like: 'Idle Traffic: 58 → 15 AI cars' or 'MaxAI 1392 → 15'
        idle = re.search(r'Idle Traffic: .*?→\s*(?P<to>\d+)', msg)
        if idle:
            to = int(idle.group('to'))
            event = {
                'timestamp': ts + 'Z',
                'player': None,
                'steam_id': None,
                'car': None,
                'event_type': 'traffic_change',
                'ai_density': to,
                'preset': None,
                'value': None,
                'unit': None,
                'session': None,
                'metadata': {}
            }
            events.append(event)

def parse_daily_stats():
    # Look for stats-YYYYMMDD.txt files and extract totals
    for p in STATS.glob('stats-*.txt'):
        text = p.read_text(encoding='utf-8', errors='ignore')
        # date from filename
        datepart = p.stem.split('-',1)[1]
        ts = datepart + 'T00:00:00Z'
        totals = {}
        m_conn = re.search(r'Total Connections:\s*(\d+)', text)
        m_disc = re.search(r'Total Disconnections:\s*(\d+)', text)
        m_unique = re.search(r'Unique Players:\s*(\d+)', text)
        if m_conn or m_disc or m_unique:
            totals['time_seconds'] = None
            totals['connections'] = int(m_conn.group(1)) if m_conn else None
            totals['disconnections'] = int(m_disc.group(1)) if m_disc else None
            totals['unique_players'] = int(m_unique.group(1)) if m_unique else None
            event = {
                'timestamp': ts,
                'player': None,
                'steam_id': None,
                'car': None,
                'event_type': 'session_stats',
                'stats': totals,
                'value': None,
                'unit': None,
                'session': None,
                'metadata': {}
            }
            events.append(event)

def main():
    parse_connects()
    parse_disconnects()
    parse_dynamic_traffic()
    parse_daily_stats()

    # sort events by timestamp where possible
    def keyfn(e):
        try:
            return e.get('timestamp') or ''
        except Exception:
            return ''

    events_sorted = sorted(events, key=keyfn)
    out = ROOT / 'redline_souls_logs.json'
    out.write_text(json.dumps(events_sorted, indent=2, ensure_ascii=False))
    print(f'Wrote {len(events_sorted)} events to {out}')

if __name__ == '__main__':
    main()
