#!/usr/bin/env python3
"""
RedLine Souls - Dynamic Traffic Rotation (6-hour cycles, 4x daily)
Rotates traffic every 6 hours WITHOUT server restart
NOW WITH: Server load monitoring and emergency traffic reduction
"""

import os, yaml, shutil, time, json, requests, subprocess
from pathlib import Path
from datetime import datetime
import pytz

# Config
SERVER_DIR = Path(__file__).resolve().parent
CONFIG_FILE = SERVER_DIR / "cfg" / "extra_cfg.yml"
BACKUP_DIR = SERVER_DIR / "cfg" / "traffic_presets"
LOG_FILE = SERVER_DIR / "logs" / "dynamic_traffic.log"
AMSTERDAM_TZ = pytz.timezone('Europe/Amsterdam')
CHECK_INTERVAL = 1800  # 30 minutes (preset rotation check)
SCALING_CHECK_INTERVAL = 300  # 5 minutes (player count check)
LOAD_CHECK_INTERVAL = 60  # 1 minute (server load check)

# ============================================================================
# Player Count Auto-Scaling Configuration
# ============================================================================

SCALING_CONFIG = {
    'enabled': True,
    'player_thresholds': [
        # (min_players, max_players, ai_multiplier)
        (0, 10, 1.0),      # 0-10 players: 100% AI (full traffic)
        (11, 15, 0.85),    # 11-15 players: 85% AI
        (16, 20, 0.75),    # 16-20 players: 75% AI
        (21, 25, 0.70),    # 21-25 players: 70% AI (30% reduction!)
        (26, 999, 0.65),   # 26+ players: 65% AI (maximum reduction)
    ],
    'server_status_url': 'http://127.0.0.1:8081/api/details',  # AssettoServer API
    'min_ai_per_player': 25,  # Absolute minimum
    'max_ai_per_player': 75,  # Absolute maximum
    
    # Idle Traffic - Keep AI running even with 0 players
    'idle_traffic_enabled': False,  # DISABLED - AssettoServer won't spawn AI with 0 players
    'idle_ai_count': 15,  # Number of AI cars when empty (feature not supported by engine)
}

# ============================================================================
# Server Load Monitoring & Emergency Scaling Configuration
# ============================================================================

LOAD_CONFIG = {
    'enabled': True,
    'check_interval': LOAD_CHECK_INTERVAL,
    
    # CPU Thresholds
    'cpu_warning': 75.0,      # % CPU usage - start reducing traffic
    'cpu_critical': 85.0,     # % CPU usage - emergency reduction
    'cpu_recovery': 60.0,     # % CPU usage - safe to restore traffic
    
    # Memory Thresholds (server process)
    'memory_warning': 2.5,    # GB - start reducing traffic
    'memory_critical': 3.5,   # GB - emergency reduction
    'memory_recovery': 2.0,   # GB - safe to restore traffic
    
    # System Load Average (1-min avg on 2-core system - CORRECTED)
    'load_warning': 1.5,      # Load avg > 1.5 on 2-core = 75% util
    'load_critical': 1.75,    # Load avg > 1.75 on 2-core = 87.5% util
    'load_recovery': 1.25,    # Load avg < 1.25 on 2-core = 62.5% util
    
    # Player Spike Detection
    'spike_threshold': 5,     # If players increase by 5+ in 5 min
    'spike_duration': 300,    # Track player changes over 5 minutes
    
    # Emergency Scaling
    'emergency_ai_multiplier': 0.50,  # Reduce AI to 50% during emergencies
    'recovery_delay': 300,     # Wait 5 min before restoring after recovery
    'min_checks_before_action': 2,  # Need 2 consecutive bad readings before acting
    
    # State tracking
    'state': 'normal',  # 'normal', 'warning', 'critical', 'recovering'
    'consecutive_warnings': 0,
    'last_emergency_time': 0,
    'baseline_ai': {},  # Store original AI counts per preset
}

# Player history for spike detection
PLAYER_HISTORY = []

# ============================================================================
# Traffic Presets - 4 Daily Rotations (Every 6 Hours)
# ============================================================================

# Base template for variations
BASE_LANE_OVERRIDES = {
    1: {"MinAiSafetyDistanceMeters": 32, "MaxAiSafetyDistanceMeters": 78, "MaxSpeedKph": 90, "RightLaneOffsetKph": 18},
    2: {"MinAiSafetyDistanceMeters": 34, "MaxAiSafetyDistanceMeters": 82, "MaxSpeedKph": 99, "RightLaneOffsetKph": 21},
    3: {"MinAiSafetyDistanceMeters": 37, "MaxAiSafetyDistanceMeters": 88, "MaxSpeedKph": 115, "RightLaneOffsetKph": 24, 
        "MinSpawnProtectionTimeSeconds": 22, "MaxSpawnProtectionTimeSeconds": 38}
}

# Weather-Reactive Traffic (Subtle Wow Factor)
WEATHER_MULTIPLIERS = {
    'Clear': {'speed': 1.0, 'spacing': 1.0, 'name': '☀️ Clear'},
    'FewClouds': {'speed': 1.0, 'spacing': 1.0, 'name': '🌤️ Few Clouds'},
    'ScatteredClouds': {'speed': 0.97, 'spacing': 1.05, 'name': '⛅ Scattered Clouds'},
    'BrokenClouds': {'speed': 0.95, 'spacing': 1.08, 'name': '☁️ Broken Clouds'},
    'OvercastClouds': {'speed': 0.93, 'spacing': 1.10, 'name': '☁️ Overcast'},
    'Fog': {'speed': 0.75, 'spacing': 1.30, 'name': '🌫️ Fog'},
    'Mist': {'speed': 0.85, 'spacing': 1.20, 'name': '🌁 Mist'},
    'LightRain': {'speed': 0.88, 'spacing': 1.18, 'name': '🌦️ Light Rain'},
    'Rain': {'speed': 0.80, 'spacing': 1.28, 'name': '🌧️ Rain'},
    'HeavyRain': {'speed': 0.70, 'spacing': 1.40, 'name': '⛈️ Heavy Rain'},
    'Thunderstorm': {'speed': 0.65, 'spacing': 1.45, 'name': '⛈️ Thunderstorm'},
    'LightSnow': {'speed': 0.75, 'spacing': 1.35, 'name': '🌨️ Light Snow'},
    'Snow': {'speed': 0.65, 'spacing': 1.45, 'name': '❄️ Snow'},
    'HeavySnow': {'speed': 0.55, 'spacing': 1.55, 'name': '❄️ Heavy Snow'},
}

def create_preset(name, emoji, hours, density, speed_mod, ai_count, spacing_mod, aggressive):
    """Generate preset with modifiers applied to base values"""
    return {
        "name": f"{emoji} {name}",
        "hours": hours,
        "settings": {
            "MinAiSafetyDistanceMeters": int(35 * spacing_mod),
            "MaxAiSafetyDistanceMeters": int(85 * spacing_mod),
            "MaxSpeedKph": int(95 + speed_mod),
            "RightLaneOffsetKph": 22 if not aggressive else 28,
            "MaxSpeedVariationPercent": 0.20 + (0.05 if aggressive else 0),
            "TrafficDensity": density,
            "AiPerPlayerTargetCount": ai_count,
            "MaxAiTargetCount": ai_count * 24,
            "IgnoreObstaclesAfterSeconds": 1 if aggressive else 2,
            "LaneCountSpecificOverrides": {
                k: {**v, "MaxSpeedKph": int(v["MaxSpeedKph"] + speed_mod)} 
                for k, v in BASE_LANE_OVERRIDES.items()
            }
        }
    }

TRAFFIC_PRESETS = {
    "night": create_preset("Night Cruise", "🌙", [0,1,2,3,4,5], 1.20, -5, 35, 1.15, False),     # 00-06: Light, slower
    "morning": create_preset("Morning Rush", "☀️", [6,7,8,9,10,11], 0.80, 8, 58, 0.90, True),   # 06-12: Dense, fast
    "afternoon": create_preset("Afternoon Flow", "🌤️", [12,13,14,15,16,17], 0.95, 0, 48, 1.0, False),  # 12-18: Balanced
    "evening": create_preset("Evening Attack", "🌆", [18,19,20,21,22,23], 0.85, 12, 55, 0.85, True)    # 18-24: Aggressive
}

# ============================================================================
# Core Functions
# ============================================================================

def log(msg):
    """Log with timestamp"""
    ts = datetime.now(AMSTERDAM_TZ).strftime("%Y-%m-%d %H:%M:%S")
    log_msg = f"[{ts}] {msg}"
    print(log_msg)
    try:
        LOG_FILE.parent.mkdir(exist_ok=True)
        with open(LOG_FILE, 'a') as f: f.write(log_msg + '\n')
    except: pass

def get_current_weather():
    """Get current weather from AssettoServer API"""
    try:
        response = requests.get('http://127.0.0.1:8081/api/details', timeout=2)
        if response.status_code == 200:
            data = response.json()
            # FIX: API returns 'currentWeatherId' not 'weather'
            weather_name = data.get('currentWeatherId', 'Clear')
            return weather_name
    except Exception as e:
        log(f"⚠️ Weather API failed: {e}")
    
    return 'Clear'  # Safe default

# Cache last weather to avoid redundant updates
_LAST_WEATHER = {'name': None, 'modifiers': None}

def get_weather_multiplier():
    """Get traffic behavior multipliers based on current weather"""
    current_weather = get_current_weather()
    
    # Match weather name to multipliers (case-insensitive, partial match)
    for weather_key, modifiers in WEATHER_MULTIPLIERS.items():
        if weather_key.lower() in current_weather.lower() or current_weather.lower() in weather_key.lower():
            # Cache for comparison
            _LAST_WEATHER['name'] = current_weather
            _LAST_WEATHER['modifiers'] = modifiers
            return modifiers
    
    # Default to clear weather
    default = WEATHER_MULTIPLIERS['Clear']
    _LAST_WEATHER['name'] = current_weather
    _LAST_WEATHER['modifiers'] = default
    return default

# Weather cache is maintained in get_weather_multiplier() - no separate check needed

# ============================================================================
# Player Count Auto-Scaling Functions
# ============================================================================

def get_player_count():
    """Get current player count from AssettoServer API"""
    try:
        response = requests.get(SCALING_CONFIG['server_status_url'], timeout=3)
        if response.status_code == 200:
            data = response.json()
            # API returns {'clients': int, 'maxClients': int, ...}
            return data.get('clients', 0)
        else:
            log(f"⚠️ Server API returned {response.status_code}")
            return None
    except requests.exceptions.RequestException as e:
        log(f"⚠️ Could not reach server API: {e}")
        return None
    except Exception as e:
        log(f"⚠️ Error getting player count: {e}")
        return None

def get_ai_multiplier(player_count):
    """Get AI multiplier based on player count"""
    for min_p, max_p, multiplier in SCALING_CONFIG['player_thresholds']:
        if min_p <= player_count <= max_p:
            return multiplier
    return 1.0  # Default to 100% if something goes wrong

def calculate_scaled_ai(base_ai, player_count):
    """Calculate scaled AI count with safety limits"""
    multiplier = get_ai_multiplier(player_count)
    scaled_ai = int(base_ai * multiplier)
    
    # Apply absolute limits
    scaled_ai = max(SCALING_CONFIG['min_ai_per_player'], scaled_ai)
    scaled_ai = min(SCALING_CONFIG['max_ai_per_player'], scaled_ai)
    
    return scaled_ai, multiplier

def apply_player_scaling(preset_key, preset_data, player_count):
    """Apply player-count-based AI scaling"""
    if not SCALING_CONFIG['enabled']:
        return False
    
    cfg = load_config()
    if not cfg or 'AiParams' not in cfg['main']:
        log("✗ Config load failed")
        return False
    
    # Idle traffic disabled (AssettoServer doesn't spawn AI with 0 players anyway)
    # Skip scaling for empty server - no changes needed
    
    # Normal player-based scaling (1+ players)
    base_ai = preset_data['settings']['AiPerPlayerTargetCount']
    scaled_ai, multiplier = calculate_scaled_ai(base_ai, player_count)
    
    # Only apply if there's actually a change
    if scaled_ai == base_ai:
        # Still need to reset MinAiTargetCount if coming from idle mode
        if cfg['main']['AiParams'].get('MinAiTargetCount', 0) > 0:
            cfg['main']['AiParams']['MinAiTargetCount'] = 0
            if save_config(cfg):
                log(f"✓ Reset MinAI to 0 (normal player-based scaling)")
                os.utime(CONFIG_FILE, None)
                return True
        return False
    
    log(f"👥 Player Count: {player_count} → AI Scaling: {multiplier:.0%} ({base_ai} → {scaled_ai} AI/player)")
    
    cfg = load_config()
    if not cfg or 'AiParams' not in cfg['main']:
        log("✗ Config load failed")
        return False
    
    # Apply scaled AI
    old_ai = cfg['main']['AiParams'].get('AiPerPlayerTargetCount')
    if old_ai != scaled_ai:
        cfg['main']['AiParams']['AiPerPlayerTargetCount'] = scaled_ai
        cfg['main']['AiParams']['MaxAiTargetCount'] = scaled_ai * 24  # Same multiplier as presets
        cfg['main']['AiParams']['MinAiTargetCount'] = 0  # Reset MinAI (used for idle traffic)
        
        if save_config(cfg):
            log(f"✓ Scaled AI: {old_ai} → {scaled_ai} (multiplier: {multiplier:.0%})")
            os.utime(CONFIG_FILE, None)  # Trigger hot-reload
            return True
    
    return False

# ============================================================================
# Server Load Monitoring Functions
# ============================================================================

def get_server_pid():
    """Get AssettoServer process PID"""
    try:
        result = subprocess.run(['pgrep', '-f', 'AssettoServer'], 
                              capture_output=True, text=True, timeout=2)
        if result.returncode == 0 and result.stdout.strip():
            return int(result.stdout.strip().split()[0])
    except Exception as e:
        log(f"⚠️ Could not get server PID: {e}")
    return None

def get_cpu_usage(pid=None):
    """Get CPU usage % (system-wide or per-process)"""
    try:
        if pid:
            # Get process CPU usage
            result = subprocess.run(['ps', '-p', str(pid), '-o', '%cpu='],
                                  capture_output=True, text=True, timeout=2)
            if result.returncode == 0 and result.stdout.strip():
                return float(result.stdout.strip())
        else:
            # Get system-wide CPU usage (100 - idle%)
            result = subprocess.run(['top', '-bn1'], capture_output=True, text=True, timeout=3)
            for line in result.stdout.split('\n'):
                if 'Cpu(s)' in line:
                    # Extract idle percentage
                    parts = line.split(',')
                    for part in parts:
                        if 'id' in part:  # idle
                            idle = float(part.strip().split()[0])
                            return 100.0 - idle
    except Exception as e:
        log(f"⚠️ Could not get CPU usage: {e}")
    return None

def get_memory_usage(pid):
    """Get process memory usage in GB"""
    try:
        result = subprocess.run(['ps', '-p', str(pid), '-o', 'rss='],
                              capture_output=True, text=True, timeout=2)
        if result.returncode == 0 and result.stdout.strip():
            # RSS is in KB, convert to GB
            rss_kb = float(result.stdout.strip())
            return rss_kb / (1024 * 1024)
    except Exception as e:
        log(f"⚠️ Could not get memory usage: {e}")
    return None

def get_load_average():
    """Get 1-minute load average"""
    try:
        with open('/proc/loadavg', 'r') as f:
            load_avg = f.read().split()[0]
            return float(load_avg)
    except Exception as e:
        log(f"⚠️ Could not get load average: {e}")
    return None

def detect_player_spike(current_players):
    """Detect sudden player influx"""
    global PLAYER_HISTORY
    
    now = time.time()
    # Add current reading
    PLAYER_HISTORY.append({'time': now, 'count': current_players})
    
    # Remove old readings (older than spike_duration)
    cutoff = now - LOAD_CONFIG['spike_duration']
    PLAYER_HISTORY = [h for h in PLAYER_HISTORY if h['time'] >= cutoff]
    
    # Check if we have a spike
    if len(PLAYER_HISTORY) >= 2:
        oldest = min(PLAYER_HISTORY, key=lambda x: x['time'])
        increase = current_players - oldest['count']
        
        if increase >= LOAD_CONFIG['spike_threshold']:
            time_span = now - oldest['time']
            log(f"⚡ PLAYER SPIKE DETECTED! +{increase} players in {time_span:.0f}s")
            return True, increase
    
    return False, 0

def check_server_load():
    """Check server health metrics and return status"""
    pid = get_server_pid()
    if not pid:
        return {'healthy': True, 'reason': 'no_pid'}  # Can't check, assume OK
    
    cpu = get_cpu_usage(pid)
    memory = get_memory_usage(pid)
    load_avg = get_load_average()
    
    issues = []
    severity = 'normal'
    
    # Check CPU
    if cpu is not None:
        if cpu >= LOAD_CONFIG['cpu_critical']:
            issues.append(f"CPU CRITICAL ({cpu:.1f}%)")
            severity = 'critical'
        elif cpu >= LOAD_CONFIG['cpu_warning'] and severity != 'critical':
            issues.append(f"CPU HIGH ({cpu:.1f}%)")
            severity = 'warning'
    
    # Check Memory
    if memory is not None:
        if memory >= LOAD_CONFIG['memory_critical']:
            issues.append(f"MEMORY CRITICAL ({memory:.2f}GB)")
            severity = 'critical'
        elif memory >= LOAD_CONFIG['memory_warning'] and severity != 'critical':
            issues.append(f"MEMORY HIGH ({memory:.2f}GB)")
            if severity != 'critical':
                severity = 'warning'
    
    # Check Load Average
    if load_avg is not None:
        if load_avg >= LOAD_CONFIG['load_critical']:
            issues.append(f"LOAD CRITICAL ({load_avg:.2f})")
            severity = 'critical'
        elif load_avg >= LOAD_CONFIG['load_warning'] and severity != 'critical':
            issues.append(f"LOAD HIGH ({load_avg:.2f})")
            if severity not in ['critical', 'warning']:
                severity = 'warning'
    
    return {
        'healthy': severity == 'normal',
        'severity': severity,
        'issues': issues,
        'cpu': cpu,
        'memory': memory,
        'load_avg': load_avg,
        'pid': pid
    }

def apply_emergency_scaling(reason="server overload"):
    """Reduce AI traffic during server stress"""
    log(f"\n{'='*70}")
    log(f"🚨 EMERGENCY TRAFFIC REDUCTION - {reason}")
    log(f"{'='*70}")
    
    cfg = load_config()
    if not cfg or 'AiParams' not in cfg['main']:
        log("✗ Could not load config for emergency scaling")
        return False
    
    # Store baseline if not already stored
    preset_key, _ = get_current_preset()
    if preset_key not in LOAD_CONFIG['baseline_ai']:
        LOAD_CONFIG['baseline_ai'][preset_key] = {
            'AiPerPlayerTargetCount': cfg['main']['AiParams'].get('AiPerPlayerTargetCount'),
            'MaxAiTargetCount': cfg['main']['AiParams'].get('MaxAiTargetCount'),
        }
    
    # Apply emergency reduction
    original_ai = cfg['main']['AiParams'].get('AiPerPlayerTargetCount')
    emergency_ai = max(
        SCALING_CONFIG['min_ai_per_player'],
        int(original_ai * LOAD_CONFIG['emergency_ai_multiplier'])
    )
    
    cfg['main']['AiParams']['AiPerPlayerTargetCount'] = emergency_ai
    cfg['main']['AiParams']['MaxAiTargetCount'] = emergency_ai * 24
    
    if save_config(cfg):
        log(f"✓ AI REDUCED: {original_ai} → {emergency_ai} ({LOAD_CONFIG['emergency_ai_multiplier']:.0%})")
        os.utime(CONFIG_FILE, None)  # Trigger hot-reload
        LOAD_CONFIG['state'] = 'critical'
        LOAD_CONFIG['last_emergency_time'] = time.time()
        return True
    
    return False

def restore_normal_traffic():
    """Restore AI traffic to baseline after emergency"""
    preset_key, _ = get_current_preset()
    
    if preset_key not in LOAD_CONFIG['baseline_ai']:
        log("⚠️ No baseline to restore, skipping recovery")
        LOAD_CONFIG['state'] = 'normal'
        return False
    
    log(f"\n{'='*70}")
    log(f"✅ SERVER RECOVERED - Restoring normal traffic")
    log(f"{'='*70}")
    
    cfg = load_config()
    if not cfg or 'AiParams' not in cfg['main']:
        log("✗ Could not load config for recovery")
        return False
    
    baseline = LOAD_CONFIG['baseline_ai'][preset_key]
    current_ai = cfg['main']['AiParams'].get('AiPerPlayerTargetCount')
    
    cfg['main']['AiParams']['AiPerPlayerTargetCount'] = baseline['AiPerPlayerTargetCount']
    cfg['main']['AiParams']['MaxAiTargetCount'] = baseline['MaxAiTargetCount']
    
    if save_config(cfg):
        log(f"✓ AI RESTORED: {current_ai} → {baseline['AiPerPlayerTargetCount']}")
        os.utime(CONFIG_FILE, None)  # Trigger hot-reload
        LOAD_CONFIG['state'] = 'normal'
        LOAD_CONFIG['consecutive_warnings'] = 0
        return True
    
    return False

def monitor_server_load():
    """Main load monitoring logic with state machine"""
    if not LOAD_CONFIG['enabled']:
        return
    
    status = check_server_load()
    
    # Handle state transitions
    current_state = LOAD_CONFIG['state']
    
    if status['severity'] == 'critical':
        LOAD_CONFIG['consecutive_warnings'] += 1
        
        if LOAD_CONFIG['consecutive_warnings'] >= LOAD_CONFIG['min_checks_before_action']:
            if current_state != 'critical':
                issues_str = ", ".join(status['issues'])
                apply_emergency_scaling(reason=issues_str)
    
    elif status['severity'] == 'warning':
        if current_state == 'normal':
            LOAD_CONFIG['consecutive_warnings'] += 1
            if LOAD_CONFIG['consecutive_warnings'] >= LOAD_CONFIG['min_checks_before_action']:
                log(f"⚠️ Server load elevated: {', '.join(status['issues'])}")
                LOAD_CONFIG['state'] = 'warning'
                LOAD_CONFIG['last_emergency_time'] = time.time()  # Track warning time for recovery
        # Stay in warning or critical, don't escalate/de-escalate yet
    
    else:  # severity == 'normal'
        LOAD_CONFIG['consecutive_warnings'] = 0
        
        # Check if we can recover from critical/warning
        if current_state in ['critical', 'warning']:
            time_since_emergency = time.time() - LOAD_CONFIG['last_emergency_time']
            
            if time_since_emergency >= LOAD_CONFIG['recovery_delay']:
                if current_state == 'critical':
                    restore_normal_traffic()
                else:
                    log(f"✅ Server load normalized")
                    LOAD_CONFIG['state'] = 'normal'
    
    # Periodic status logging (only if not normal or first check)
    if current_state != 'normal' or LOAD_CONFIG.get('last_log_time', 0) == 0:
        log(f"📊 Server Status: {status['severity'].upper()} | "
            f"CPU: {status['cpu']:.1f}% | Mem: {status['memory']:.2f}GB | "
            f"Load: {status['load_avg']:.2f}")
        LOAD_CONFIG['last_log_time'] = time.time()

def get_current_preset():
    """Get preset based on current hour"""
    hour = datetime.now(AMSTERDAM_TZ).hour
    for key, preset in TRAFFIC_PRESETS.items():
        if hour in preset["hours"]:
            return key, preset
    return "afternoon", TRAFFIC_PRESETS["afternoon"]

# ============================================================================
# Poll Analysis Functions
# ============================================================================

def load_poll_votes():
    """Load poll votes from traffic_votes.json"""
    votes_file = SERVER_DIR / "traffic_votes.json"
    if not votes_file.exists():
        return {}
    try:
        with open(votes_file, 'r') as f:
            return json.load(f)
    except Exception as e:
        log(f"⚠️ Could not load poll votes: {e}")
        return {}

def analyze_period_votes(votes_by_period, period_name):
    """Analyze votes for a specific traffic period with weighting"""
    if not votes_by_period:
        return None
    
    # Calculate weighted average
    weighted_sum = sum(v['rating'] * v['vote_weight'] for v in votes_by_period)
    weight_total = sum(v['vote_weight'] for v in votes_by_period)
    weighted_avg = weighted_sum / weight_total if weight_total > 0 else 0
    
    # Separate regular vs new player opinions
    regular_votes = [v for v in votes_by_period if v.get('is_regular')]
    new_player_votes = [v for v in votes_by_period if not v.get('is_regular')]
    
    regular_avg = None
    if regular_votes:
        reg_weighted_sum = sum(v['rating'] * v['vote_weight'] for v in regular_votes)
        reg_weight_total = sum(v['vote_weight'] for v in regular_votes)
        regular_avg = reg_weighted_sum / reg_weight_total if reg_weight_total > 0 else 0
    
    new_player_avg = None
    if new_player_votes:
        new_weighted_sum = sum(v['rating'] * v['vote_weight'] for v in new_player_votes)
        new_weight_total = sum(v['vote_weight'] for v in new_player_votes)
        new_player_avg = new_weighted_sum / new_weight_total if new_weight_total > 0 else 0
    
    return {
        'weighted_avg': weighted_avg,
        'total_votes': len(votes_by_period),
        'unique_voters': len(set(v['steam_id'] for v in votes_by_period)),
        'weight_total': weight_total,
        'regular_avg': regular_avg,
        'regular_count': len(regular_votes),
        'new_player_avg': new_player_avg,
        'new_player_count': len(new_player_votes)
    }

def get_poll_summary(days=3):
    """Get poll summary for the last N days"""
    all_votes = load_poll_votes()
    if not all_votes:
        return None
    
    # Get last N days
    from datetime import timedelta
    today = datetime.now(AMSTERDAM_TZ).date()
    target_dates = [(today - timedelta(days=i)).strftime('%Y-%m-%d') for i in range(days)]
    
    # Organize votes by period
    period_votes = {
        'night': [],
        'morning': [],
        'afternoon': [],
        'evening': []
    }
    
    for date_str in target_dates:
        if date_str in all_votes:
            for vote in all_votes[date_str]:
                period = vote.get('traffic_period', 'unknown')
                if period in period_votes:
                    period_votes[period].append(vote)
    
    # Analyze each period
    summary = {}
    for period_name, votes in period_votes.items():
        analysis = analyze_period_votes(votes, period_name)
        if analysis:
            summary[period_name] = analysis
    
    return summary

def check_poll_based_adjustments():
    """Check if poll data suggests traffic adjustments"""
    MIN_VOTES_FOR_TUNING = 5
    MIN_WEIGHTED_VOTES = 8.0
    MIN_DAYS_OF_DATA = 3
    LOW_RATING_THRESHOLD = 3.0
    HIGH_RATING_THRESHOLD = 4.5
    
    summary = get_poll_summary(days=MIN_DAYS_OF_DATA)
    if not summary:
        log("📊 Poll Analysis: No poll data yet")
        return
    
    log(f"\n{'='*70}")
    log(f"📊 POLL-BASED TRAFFIC ANALYSIS (Last {MIN_DAYS_OF_DATA} days)")
    log(f"{'='*70}")
    
    for period_name, data in summary.items():
        weighted_avg = data['weighted_avg']
        total_votes = data['total_votes']
        unique_voters = data['unique_voters']
        weight_total = data['weight_total']
        regular_avg = data.get('regular_avg')
        new_player_avg = data.get('new_player_avg')
        
        log(f"\n{period_name.upper()} Period:")
        log(f"  Overall Rating: {weighted_avg:.2f}/5.0 ({total_votes} votes from {unique_voters} players)")
        log(f"  Total Weight: {weight_total:.1f} (effective votes)")
        
        if regular_avg is not None:
            log(f"  Regular Players: {regular_avg:.2f}/5.0 ⭐ ({data['regular_count']} votes)")
        if new_player_avg is not None:
            log(f"  New Players: {new_player_avg:.2f}/5.0 ({data['new_player_count']} votes)")
        
        # Check if we have enough data for tuning
        if total_votes < MIN_VOTES_FOR_TUNING:
            log(f"  ⚠️ Not enough votes yet (need {MIN_VOTES_FOR_TUNING})")
            continue
        
        if weight_total < MIN_WEIGHTED_VOTES:
            log(f"  ⚠️ Not enough weighted votes yet (need {MIN_WEIGHTED_VOTES:.1f})")
            continue
        
        # Suggest adjustments
        if weighted_avg < LOW_RATING_THRESHOLD:
            log(f"  🔧 SUGGESTION: {period_name} rated LOW - consider reducing intensity")
            log(f"     → Increase density by 10-15%")
            log(f"     → Reduce AI count by 5-10")
            log(f"     → Reduce speed by 5-10 kph")
        elif weighted_avg >= HIGH_RATING_THRESHOLD:
            log(f"  ✨ SUGGESTION: {period_name} rated HIGH - can increase intensity")
            log(f"     → Decrease density by 10% (more packed)")
            log(f"     → Increase AI count by 5")
            log(f"     → Increase speed by 5 kph")
        else:
            log(f"  ✅ {period_name} rating is good - no changes needed")
    
    log(f"\n{'='*70}\n")

def load_config():
    """Load multi-document YAML config"""
    try:
        with open(CONFIG_FILE, 'r') as f:
            docs = f.read().split('\n---\n')
        return {'main': yaml.safe_load(docs[0]), 'other_docs': docs[1:] if len(docs) > 1 else []}
    except Exception as e:
        log(f"✗ Load failed: {e}")
        return None

def save_config(cfg):
    """Save multi-document YAML config"""
    try:
        with open(CONFIG_FILE, 'w') as f:
            yaml.dump(cfg['main'], f, default_flow_style=False, sort_keys=False)
            for doc in cfg.get('other_docs', []): f.write(f'\n---\n{doc}')
        log(f"✓ Config saved")
        return True
    except Exception as e:
        log(f"✗ Save failed: {e}")
        return False

def backup_config():
    """Backup current config with rolling cleanup (for rapid development)"""
    try:
        BACKUP_DIR.mkdir(parents=True, exist_ok=True)
        
        # Timestamped backup (frequent saves for rapid dev)
        ts = datetime.now(AMSTERDAM_TZ).strftime("%Y%m%d_%H%M%S")
        backup_file = BACKUP_DIR / f"backup_{ts}.yml"
        shutil.copy2(CONFIG_FILE, backup_file)
        
        # AUTO-CLEANUP: Keep only last 20 backups (rolling window)
        backups = sorted(BACKUP_DIR.glob("backup_*.yml"), key=lambda p: p.stat().st_mtime, reverse=True)
        if len(backups) > 20:
            for old_backup in backups[20:]:
                old_backup.unlink()
                log(f"🗑️ Cleaned old backup: {old_backup.name}")
        
        return True
    except Exception as e:
        log(f"⚠️ Backup failed: {e}")
        return False

def apply_preset(preset_key, preset_data):
    """Apply traffic preset to config with weather-reactive adjustments"""
    log(f"{'='*70}\n{preset_data['name']} (Applying)\n{'='*70}")
    
    if not backup_config():
        log("✗ Backup failed, aborting")
        return False
    
    cfg = load_config()
    if not cfg or 'AiParams' not in cfg['main']:
        log("✗ Config load failed")
        return False
    
    # WEATHER-REACTIVE TRAFFIC (Subtle Wow Factor!)
    weather_mod = get_weather_multiplier()
    # Always log weather detection (helps debugging)
    if weather_mod['speed'] != 1.0 or weather_mod['spacing'] != 1.0:
        log(f"🌦️ Weather: {weather_mod['name']} → Speed {weather_mod['speed']:.0%}, Spacing {weather_mod['spacing']:.0%}")
    else:
        log(f"☀️ Weather: {weather_mod['name']} (normal conditions)")
    
    # Apply settings with weather modifiers
    changes = 0
    for k, v in preset_data['settings'].items():
        # Apply weather multipliers to speed/spacing settings
        if k == 'MaxSpeedKph':
            v = int(v * weather_mod['speed'])
        elif k == 'RightLaneOffsetKph':
            v = int(v * weather_mod['speed'])
        elif k in ['MinAiSafetyDistanceMeters', 'MaxAiSafetyDistanceMeters']:
            v = int(v * weather_mod['spacing'])
        elif k == 'LaneCountSpecificOverrides':
            # Apply weather to lane-specific overrides
            v = {
                lane: {
                    **params,
                    'MaxSpeedKph': int(params.get('MaxSpeedKph', 100) * weather_mod['speed']),
                    'RightLaneOffsetKph': int(params.get('RightLaneOffsetKph', 20) * weather_mod['speed']),
                    'MinAiSafetyDistanceMeters': int(params.get('MinAiSafetyDistanceMeters', 30) * weather_mod['spacing']),
                    'MaxAiSafetyDistanceMeters': int(params.get('MaxAiSafetyDistanceMeters', 80) * weather_mod['spacing']),
                }
                for lane, params in v.items()
            }
        
        if cfg['main']['AiParams'].get(k) != v:
            cfg['main']['AiParams'][k] = v
            changes += 1
    
    if not save_config(cfg):
        return False
    
    log(f"✓ {preset_data['name']} active ({changes} changes)")
    os.utime(CONFIG_FILE, None)  # Trigger hot-reload
    return True

# ============================================================================
# Main Logic
# ============================================================================

def monitor_mode():
    """Continuous monitoring - checks every 5min for scaling, changes preset every 6hr, monitors load every 1min"""
    log(f"{'='*70}\n🚗 RedLine Souls - Dynamic Traffic (6hr cycles + Auto-Scaling + Load Monitor)\n{'='*70}")
    log(f"Timezone: Amsterdam")
    log(f"Preset Check: every {CHECK_INTERVAL//60}min")
    log(f"Player Scaling: every {SCALING_CHECK_INTERVAL//60}min")
    log(f"Load Monitoring: every {LOAD_CHECK_INTERVAL}s")
    log(f"Auto-Scaling: {'ENABLED' if SCALING_CONFIG['enabled'] else 'DISABLED'}")
    log(f"Load Monitor: {'ENABLED' if LOAD_CONFIG['enabled'] else 'DISABLED'}")
    
    last_preset = None
    last_scaling_check = 0
    last_load_check = 0
    last_player_count = None
    
    while True:
        try:
            preset_key, preset_data = get_current_preset()
            now = datetime.now(AMSTERDAM_TZ)
            current_time = time.time()
            
            # 1. Check for preset rotation (every 30 min, applies on hour change)
            if last_preset != preset_key:
                log(f"\n⏰ {now.strftime('%H:%M')} - Switching to {preset_data['name']}")
                if apply_preset(preset_key, preset_data):
                    last_preset = preset_key
                    # Reset scaling check to immediately apply scaling for new preset
                    last_scaling_check = 0
                    # Clear baseline so new preset baseline is stored
                    LOAD_CONFIG['baseline_ai'].clear()
            
            # 2. SERVER LOAD MONITORING (every 1 min)
            if LOAD_CONFIG['enabled'] and (current_time - last_load_check >= LOAD_CHECK_INTERVAL):
                monitor_server_load()
                last_load_check = current_time
            
            # 3. Check for player count scaling (every 5 min)
            if SCALING_CONFIG['enabled'] and (current_time - last_scaling_check >= SCALING_CHECK_INTERVAL):
                player_count = get_player_count()
                
                if player_count is not None:
                    # PLAYER SPIKE DETECTION
                    is_spike, spike_amount = detect_player_spike(player_count)
                    if is_spike and LOAD_CONFIG['enabled']:
                        log(f"⚡ Player spike detected, triggering precautionary monitoring")
                        monitor_server_load()  # Immediate check
                    
                    # Only log if player count changed significantly or first check
                    if last_player_count is None or abs(player_count - last_player_count) >= 2:
                        log(f"👥 Current Players: {player_count}")
                        last_player_count = player_count
                    
                    # Apply player-based scaling (only if not in emergency mode)
                    if LOAD_CONFIG['state'] == 'normal':
                        apply_player_scaling(preset_key, preset_data, player_count)
                    else:
                        log(f"⚠️ Skipping player scaling - server in {LOAD_CONFIG['state'].upper()} mode")
                
                last_scaling_check = current_time
            
            # 4. Status log (every 30 min)
            if now.minute % 30 == 0 and now.second < LOAD_CHECK_INTERVAL:
                state_emoji = "✅" if LOAD_CONFIG['state'] == 'normal' else "⚠️" if LOAD_CONFIG['state'] == 'warning' else "🚨"
                log(f"⏰ {now.strftime('%H:%M')} - Active: {preset_data['name']} | "
                    f"Players: {last_player_count or 'N/A'} | "
                    f"Server: {state_emoji} {LOAD_CONFIG['state'].upper()}")
            
            # Sleep for load check interval (shortest interval)
            time.sleep(LOAD_CHECK_INTERVAL)
            
        except KeyboardInterrupt:
            log("\n⛔ Shutdown")
            break
        except Exception as e:
            log(f"✗ Error in monitor loop: {e}")
            import traceback
            log(traceback.format_exc())
            time.sleep(60)

def apply_now():
    """Apply current preset immediately"""
    preset_key, preset_data = get_current_preset()
    log(f"🚀 Applying current preset: {preset_data['name']}")
    apply_preset(preset_key, preset_data)

def show_schedule():
    """Show rotation schedule"""
    print(f"\n{'='*70}\n📅 Traffic Rotation Schedule (Every 6 Hours)\n{'='*70}")
    for key, preset in TRAFFIC_PRESETS.items():
        s = preset['settings']
        hours_str = f"{preset['hours'][0]:02d}:00 - {preset['hours'][-1]:02d}:59"
        print(f"\n{preset['name']} ({hours_str})")
        print(f"  Density: {s['TrafficDensity']:.2f} | Speed: {s['MaxSpeedKph']}kph | AI/player: {s['AiPerPlayerTargetCount']}")
        print(f"  Spacing: {s['MinAiSafetyDistanceMeters']}-{s['MaxAiSafetyDistanceMeters']}m | Highway: {s['LaneCountSpecificOverrides'][3]['MaxSpeedKph']}kph")
    
    print(f"\n{'='*70}")
    print(f"⚙️  AUTO-SCALING FEATURES:")
    print(f"{'='*70}")
    
    print(f"\n1️⃣  Player Count Scaling: {'ENABLED' if SCALING_CONFIG['enabled'] else 'DISABLED'}")
    if SCALING_CONFIG['enabled']:
        # Show idle traffic feature first
        if SCALING_CONFIG.get('idle_traffic_enabled', False):
            print(f"  🌙 Idle Traffic (0 players): {SCALING_CONFIG['idle_ai_count']} AI cars (keeps system warm)")
        print(f"  • 1-10 players: 100% AI")
        print(f"  • 11-15 players: 85% AI")
        print(f"  • 16-20 players: 75% AI")
        print(f"  • 21-25 players: 70% AI (30% reduction!)")
        print(f"  • 26+ players: 65% AI (maximum reduction)")
    
    print(f"\n2️⃣  Server Load Monitoring: {'ENABLED' if LOAD_CONFIG['enabled'] else 'DISABLED'}")
    if LOAD_CONFIG['enabled']:
        print(f"  🔍 Checks every {LOAD_CHECK_INTERVAL}s for:")
        print(f"     • CPU usage (Warning: {LOAD_CONFIG['cpu_warning']}%, Critical: {LOAD_CONFIG['cpu_critical']}%)")
        print(f"     • Memory usage (Warning: {LOAD_CONFIG['memory_warning']}GB, Critical: {LOAD_CONFIG['memory_critical']}GB)")
        print(f"     • System load (Warning: {LOAD_CONFIG['load_warning']}, Critical: {LOAD_CONFIG['load_critical']})")
        print(f"  ⚡ Player Spike Detection:")
        print(f"     • Triggers if +{LOAD_CONFIG['spike_threshold']} players in {LOAD_CONFIG['spike_duration']//60} minutes")
        print(f"  🚨 Emergency Actions:")
        print(f"     • Reduces AI to {LOAD_CONFIG['emergency_ai_multiplier']:.0%} during overload")
        print(f"     • Waits {LOAD_CONFIG['recovery_delay']//60} min before restoring")
        print(f"     • Needs {LOAD_CONFIG['min_checks_before_action']} consecutive warnings to act")
    
    print(f"\n3️⃣  Poll-Based Tuning: Coming soon!")
    print(f"  • Analyzes player feedback (/1 to /5 votes)")
    print(f"  • Weighted by playtime (30 min = 1.0x, max 3.0x)")
    print(f"  • Regular players ⭐ count more")
    print(f"  • Needs 5+ votes over 3+ days before adjusting")
    
    print(f"\n{'='*70}")
    print(f"💡 HOW IT WORKS:")
    print(f"{'='*70}")
    print(f"Idle (0 players): {SCALING_CONFIG['idle_ai_count']} AI cars keep system warm - instant join!")
    print(f"Normal Operation: Preset rotates every 6 hours + player scaling")
    print(f"Player Spike: System monitors closely, ready to reduce load")
    print(f"Server Stressed: AI reduced to 50% until CPU/memory recovers")
    print(f"After Recovery: Waits 5 min, then gradually restores normal traffic")
    print(f"\n{'='*70}\n")

# ============================================================================
# CLI
# ============================================================================

if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser(description="Dynamic Traffic Rotation (6hr cycles + Auto-Scaling + Load Monitor)")
    p.add_argument('--monitor', action='store_true', help='Run continuous monitoring')
    p.add_argument('--apply-now', action='store_true', help='Apply current preset now')
    p.add_argument('--schedule', action='store_true', help='Show schedule and features')
    p.add_argument('--poll-analysis', action='store_true', help='Analyze poll data and suggest adjustments')
    p.add_argument('--check-load', action='store_true', help='Check server load once and exit')
    args = p.parse_args()
    
    if args.schedule:
        show_schedule()
    elif args.apply_now:
        apply_now()
    elif args.poll_analysis:
        check_poll_based_adjustments()
    elif args.check_load:
        # One-time load check
        if not LOAD_CONFIG['enabled']:
            print("⚠️ Load monitoring is disabled in config")
        else:
            print(f"\n{'='*70}")
            print(f"🔍 SERVER LOAD CHECK")
            print(f"{'='*70}\n")
            status = check_server_load()
            print(f"Status: {status['severity'].upper()}")
            if status['cpu']:
                print(f"CPU Usage: {status['cpu']:.1f}%")
            if status['memory']:
                print(f"Memory Usage: {status['memory']:.2f} GB")
            if status['load_avg']:
                print(f"Load Average: {status['load_avg']:.2f}")
            if status['issues']:
                print(f"\n⚠️ Issues:")
                for issue in status['issues']:
                    print(f"  • {issue}")
            else:
                print(f"\n✅ All metrics healthy")
            print(f"\n{'='*70}\n")
    elif args.monitor:
        monitor_mode()
    else:
        p.print_help()

