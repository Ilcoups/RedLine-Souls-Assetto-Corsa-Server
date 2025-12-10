// ===========================
// NAVIGATION & PAGE SYSTEM
// ===========================

class PageManager {
    constructor() {
        this.currentPage = 'home';
        this.leaderboardData = [];
        this.init();
    }

    init() {
        this.setupNavigation();
        this.setupScrollAnimations();
        this.setupCounters();
        this.setupLeaderboardSearch();
        this.loadEnhancedStats();

        // Handle initial hash
        this.handleInitialHash();

        // Handle hash changes (back/forward button)
        window.addEventListener('hashchange', () => {
            this.handleInitialHash();
        });
    }

    handleInitialHash() {
        const hash = window.location.hash.replace('#', '');
        const validPages = ['home', 'stats', 'players'];

        if (validPages.includes(hash)) {
            this.navigateToPage(hash);
        } else if (!hash) {
            this.navigateToPage('home');
        }
    }

    setupNavigation() {
        // Handle navigation clicks
        document.querySelectorAll('[data-page]').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const page = link.getAttribute('data-page');
                this.navigateToPage(page);
            });
        });

        // Update active nav state
        this.updateActiveNav();
    }

    navigateToPage(pageName) {
        // Update URL hash without scrolling
        if (history.pushState) {
            history.pushState(null, null, `#${pageName}`);
        } else {
            location.hash = `#${pageName}`;
        }

        // Hide all pages
        document.querySelectorAll('.page-content').forEach(page => {
            page.style.display = 'none';
            page.classList.remove('page-enter');
        });

        // Show selected page
        const targetPage = document.getElementById(`${pageName}-page`);
        if (targetPage) {
            targetPage.style.display = 'block';
            targetPage.classList.add('page-enter');
            this.currentPage = pageName;
            this.updateActiveNav();

            // Scroll to top smoothly
            window.scrollTo({ top: 0, behavior: 'smooth' });

            // Load leaderboard data immediately when players page is shown
            if (pageName === 'players') {
                this.loadLeaderboardData();
            }

            // Re-trigger scroll animations
            this.setupScrollAnimations();

            // Restart counters if on stats page
            if (pageName === 'stats') {
                this.setupCounters();
            }

            // Track page view in Google Analytics
            if (typeof gtag !== 'undefined') {
                gtag('event', 'page_view', {
                    page_title: pageName === 'home' ? 'Home' : pageName === 'stats' ? 'Statistics' : 'Leaderboard',
                    page_location: window.location.href,
                    page_path: `/#${pageName}`
                });
            }
        }
    }

    updateActiveNav() {
        // Only update links that are part of the SPA system (have data-page)
        document.querySelectorAll('.nav-link[data-page]').forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('data-page') === this.currentPage) {
                link.classList.add('active');
            }
        });
    }

    setupScrollAnimations() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('visible');
                }
            });
        }, {
            threshold: 0.1,
            rootMargin: '0px 0px -100px 0px'
        });

        document.querySelectorAll('.animate-on-scroll').forEach(el => {
            el.classList.remove('visible');
            observer.observe(el);
        });
    }

    setupCounters() {
        document.querySelectorAll('.counter-value').forEach(counter => {
            const target = parseInt(counter.getAttribute('data-target') || counter.textContent);
            const duration = 2000;
            const increment = target / (duration / 16);
            let current = 0;

            const updateCounter = () => {
                current += increment;
                if (current < target) {
                    counter.textContent = Math.floor(current);
                    requestAnimationFrame(updateCounter);
                } else {
                    counter.textContent = target;
                }
            };

            // Start counting when element is visible
            const observer = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        // Don't reset to 0, start from current visual state if possible
                        // counter.textContent = '0'; // Removed to prevent flash
                        updateCounter();
                        observer.disconnect();
                    }
                });
            }, { threshold: 0.5 });

            observer.observe(counter);
        });
    }

    loadEnhancedStats() {
        // Load enhanced statistics and leaderboard
        const cacheBuster = '?v=' + Date.now();
        fetch('/enhanced_stats.json' + cacheBuster)
            .then(res => {
                if (!res.ok) {
                    throw new Error(`HTTP error! status: ${res.status}`);
                }
                return res.json();
            })
            .then(data => {
                console.log('Loaded enhanced stats:', data);

                // Update monthly stats
                const stats = data.monthly_stats || {};
                this.updateStatCounter('monthly-joins', stats.monthly_joins || 0);
                this.updateStatCounter('total-sessions', stats.total_sessions || 0);
                this.updateStatCounter('total-playtime', stats.total_playtime_hours || 0);
                this.updateStatCounter('avg-players', stats.avg_players_per_day || 0);

                // Update homepage hero stats
                this.updateStatCounter('monthly-joins-hero', stats.monthly_joins || 0);
                this.updateStatCounter('total-sessions-hero', stats.total_sessions || 0);

                // Store leaderboard data for later use
                this.leaderboardData = data.leaderboard || [];

                // Update leaderboard if players page is currently visible
                if (this.currentPage === 'players') {
                    this.updateLeaderboard(this.leaderboardData);
                }

                // Initialize charts
                this.initCharts(data);
            })
            .catch(err => {
                console.error('Failed to load enhanced stats:', err);
            });
    }

    loadLeaderboardData() {
        // Load leaderboard data if not already loaded
        if (this.leaderboardData && this.leaderboardData.length > 0) {
            this.updateLeaderboard(this.leaderboardData);
            return;
        }

        // Otherwise fetch it
        const cacheBuster = '?v=' + Date.now();
        fetch('/enhanced_stats.json' + cacheBuster)
            .then(res => res.json())
            .then(data => {
                this.leaderboardData = data.leaderboard || [];
                this.updateLeaderboard(this.leaderboardData);
            })
            .catch(err => {
                console.error('Failed to load leaderboard:', err);
            });
    }

    initCharts(data) {

        // Activity Chart
        const activityCtx = document.getElementById('activityChart');
        if (activityCtx && data.activity_chart && typeof Chart !== 'undefined' && !this.activityChart) {
            const isMobile = window.innerWidth < 768;

            this.activityChart = new Chart(activityCtx, {
                type: 'line',
                data: {
                    labels: data.activity_chart.labels,
                    datasets: [{
                        label: 'Active Players',
                        data: data.activity_chart.players,
                        borderColor: '#ff3333',
                        backgroundColor: 'rgba(255, 51, 51, 0.1)',
                        borderWidth: isMobile ? 2 : 3,
                        pointRadius: isMobile ? 2 : 4,
                        pointHoverRadius: isMobile ? 4 : 6,
                        pointBackgroundColor: '#ff3333',
                        fill: true,
                        tension: 0.4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false },
                        tooltip: {
                            backgroundColor: 'rgba(10, 10, 15, 0.9)',
                            titleColor: '#fff',
                            bodyColor: '#fff',
                            borderColor: '#ff3333',
                            borderWidth: 1,
                            padding: 10,
                            displayColors: false
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            grid: { color: 'rgba(255, 255, 255, 0.05)' },
                            ticks: {
                                color: '#8888aa',
                                font: { size: isMobile ? 10 : 12 }
                            }
                        },
                        x: {
                            grid: { display: false },
                            ticks: {
                                color: '#8888aa',
                                maxTicksLimit: isMobile ? 6 : 10,
                                maxRotation: 45,
                                minRotation: 45,
                                font: { size: isMobile ? 10 : 12 }
                            }
                        }
                    }
                }
            });
        }

        // Top Speeds Chart
        const speedCtx = document.getElementById('speedChart');
        if (speedCtx && data.top_speeds && !this.speedChart) {
            const topSpeedsData = data.top_speeds.slice(0, 10);
            this.speedChart = new Chart(speedCtx, {
                type: 'bar',
                data: {
                    labels: topSpeedsData.map(s => s.name),
                    datasets: [{
                        label: 'Max Speed (km/h)',
                        data: topSpeedsData.map(s => s.speed),
                        backgroundColor: 'rgba(255, 51, 51, 0.8)',
                        borderColor: '#ff3333',
                        borderWidth: 0
                    }]
                },
                options: {
                    indexAxis: 'y',
                    responsive: true,
                    maintainAspectRatio: false,
                    aspectRatio: 1.2,
                    plugins: {
                        legend: {
                            display: false
                        },
                        tooltip: {
                            backgroundColor: 'rgba(10, 10, 15, 0.9)',
                            titleColor: '#fff',
                            bodyColor: '#fff',
                            borderColor: '#ff3333',
                            borderWidth: 1,
                            padding: 12,
                            displayColors: false,
                            callbacks: {
                                label: function (context) {
                                    return context.parsed.x + ' km/h';
                                }
                            }
                        }
                    },
                    scales: {
                        x: {
                            beginAtZero: true,
                            grid: {
                                color: 'rgba(255, 255, 255, 0.05)'
                            },
                            ticks: {
                                color: '#8888aa'
                            }
                        },
                        y: {
                            grid: {
                                display: false
                            },
                            ticks: {
                                color: '#8888aa',
                                font: {
                                    size: 11
                                }
                            }
                        }
                    }
                }
            });
        }

        // Playtime Distribution Chart
        const playtimeCtx = document.getElementById('playtimeChart');
        if (playtimeCtx && data.playtime_distribution && !this.playtimeChart) {
            const dist = data.playtime_distribution;
            this.playtimeChart = new Chart(playtimeCtx, {
                type: 'doughnut',
                data: {
                    labels: Object.keys(dist),
                    datasets: [{
                        data: Object.values(dist),
                        backgroundColor: [
                            '#ff3333',
                            '#ff5555',
                            '#ff7777',
                            '#ff9999',
                            '#ffbbbb'
                        ],
                        borderColor: '#0a0a0f',
                        borderWidth: 2
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'bottom',
                            labels: {
                                color: '#8888aa',
                                padding: 15,
                                font: {
                                    size: 12
                                }
                            }
                        },
                        tooltip: {
                            backgroundColor: 'rgba(10, 10, 15, 0.9)',
                            titleColor: '#fff',
                            bodyColor: '#fff',
                            borderColor: '#ff3333',
                            borderWidth: 1,
                            padding: 12,
                            callbacks: {
                                label: function (context) {
                                    return context.label + ': ' + context.parsed + ' players';
                                }
                            }
                        }
                    }
                }
            });
        }

        // Car Popularity Chart
        const carCtx = document.getElementById('carChart');
        if (carCtx && data.car_popularity && !this.carChart) {
            const pop = data.car_popularity;
            this.carChart = new Chart(carCtx, {
                type: 'doughnut',
                data: {
                    labels: Object.keys(pop),
                    datasets: [{
                        data: Object.values(pop),
                        backgroundColor: [
                            '#ff3333', '#ff5555', '#ff7777', '#ff9999', '#ffbbbb'
                        ],
                        borderColor: '#0a0a0f',
                        borderWidth: 2
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    aspectRatio: 1.5,
                    plugins: {
                        legend: {
                            position: 'right',
                            labels: { color: '#8888aa', font: { size: 11 }, boxWidth: 12 }
                        }
                    }
                }
            });
        }

        // Hall of Shame
        if (data.hall_of_shame) {
            this.updateHallOfShame(data.hall_of_shame);
        }
    }


    updateHallOfShame(violations) {
        const list = document.getElementById('hall-of-shame-list');
        if (!list) return;

        list.innerHTML = violations.map((v, i) => `
            <div class="leaderboard-item" style="padding: 12px;">
                <div class="leaderboard-rank" style="font-size: 1.2rem; min-width: 40px;">#${i + 1}</div>
                <div class="leaderboard-player">
                    <div class="leaderboard-player-name">${this.escapeHtml(v.driver)}</div>
                    <div class="leaderboard-stats">
                        <span style="color: #ff3333; font-weight: bold;">⚡ ${v.speed} km/h</span>
                        <span style="opacity: 0.6;">📅 ${v.date}</span>
                    </div>
                </div>
            </div>
        `).join('');
    }

    updateStatCounter(elementId, value) {
        const el = document.getElementById(elementId);
        if (el) {
            el.setAttribute('data-target', value);
            el.textContent = value;
        }
    }

    updateLeaderboard(players, searchTerm = '') {
        const leaderboardList = document.getElementById('leaderboard-list');
        if (!leaderboardList) return;

        // Check if we need initial render (if no items exist yet)
        const existingItems = leaderboardList.getElementsByClassName('leaderboard-item');
        const needsInitialRender = existingItems.length === 0 && players && players.length > 0;

        if (needsInitialRender) {
            // Clear loading spinner or empty state
            leaderboardList.innerHTML = players.map((player, index) => {
                const rank = index + 1;
                const rankClass = rank <= 3 ? `rank-${rank}` : '';

                // Get stats with proper fallback
                const score = (player.score !== undefined && player.score !== null) ? Number(player.score) : 0;

                return `
                <div class="leaderboard-item animate-on-scroll" data-name="${this.escapeHtml(player.name || '').toLowerCase()}">
                    <div class="leaderboard-rank ${rankClass}">#${rank}</div>
                    <div class="leaderboard-player">
                        <div class="leaderboard-player-name">${this.escapeHtml(player.name)}</div>
                        <div class="leaderboard-stats">
                            <span style="color: #ff3333; font-weight: bold;">🏆 ${score.toLocaleString()} pts</span>
                            <span style="opacity: 0.7;">🚗 ${this.escapeHtml(player.car)}</span>
                            <span style="opacity: 0.9; color: #aaa; font-size: 0.9em;">⏱️ ${this.escapeHtml(player.duration)}</span>
                            <span style="opacity: 0.9; color: #aaa; font-size: 0.9em;">📅 ${this.escapeHtml(player.date)}</span>
                        </div>
                    </div>
                </div>
                `;
            }).join('');

            // Trigger animations for initial load
            this.setupScrollAnimations();
        }

        // Filter existing items
        const search = (searchTerm || '').toLowerCase().trim();
        const items = leaderboardList.getElementsByClassName('leaderboard-item');
        let hasVisible = false;

        for (let item of items) {
            const name = item.getAttribute('data-name');
            if (!search || name.includes(search)) {
                item.style.display = '';
                hasVisible = true;
            } else {
                item.style.display = 'none';
            }
        }

        // Show/hide no results message
        let noResults = document.getElementById('leaderboard-no-results');
        if (!hasVisible) {
            if (!noResults) {
                noResults = document.createElement('div');
                noResults.id = 'leaderboard-no-results';
                noResults.className = 'no-results';
                noResults.innerHTML = '<p>No players match your search</p>';
                leaderboardList.appendChild(noResults);
            }
            noResults.style.display = 'block';
        } else if (noResults) {
            noResults.style.display = 'none';
        }
    }

    setupLeaderboardSearch() {
        const searchInput = document.getElementById('leaderboard-search');
        if (!searchInput) return;

        searchInput.addEventListener('input', (e) => {
            const searchTerm = e.target.value;
            if (this.leaderboardData && this.leaderboardData.length > 0) {
                this.updateLeaderboard(this.leaderboardData, searchTerm);
            }
        });
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// ===========================
// LIVE STATUS SYSTEM
// ===========================

class StatusManager {
    constructor() {
        this.statusUrl = '/status.json';
        this.updateInterval = 10000; // 10 seconds
        this.init();
    }

    init() {
        this.updateStatus();
        setInterval(() => this.updateStatus(), this.updateInterval);
    }

    async updateStatus() {
        try {
            const response = await fetch(this.statusUrl + '?' + Date.now());
            const data = await response.json();
            this.displayStatus(data);
        } catch (error) {
            console.error('Failed to fetch status:', error);
            this.displayOfflineStatus();
        }
    }

    displayStatus(data) {
        // Update player count
        const playerCount = document.getElementById('player-count');
        const playerLabel = document.querySelector('.player-count-label');

        if (playerCount) {
            const count = data.online_players?.length || 0;
            if (count === 0) {
                playerCount.textContent = "Ready to Race";
                playerCount.style.fontSize = "1.5rem";
                if (playerLabel) playerLabel.style.display = 'none';
            } else {
                playerCount.textContent = count;
                playerCount.style.fontSize = "";
                if (playerLabel) playerLabel.style.display = 'inline';
            }
        }

        // Update status indicator
        const statusIndicator = document.getElementById('status-indicator');
        const statusText = document.getElementById('status-text');
        if (statusIndicator && statusText) {
            statusIndicator.className = 'status-indicator online';
            statusText.textContent = 'ONLINE';
        }

        // Update player list
        this.updatePlayerList(data.online_players || []);

        // Update daily stats
        this.updateDailyStats(data.daily_stats);
    }

    displayOfflineStatus() {
        const statusIndicator = document.getElementById('status-indicator');
        const statusText = document.getElementById('status-text');
        const playerCount = document.getElementById('player-count');

        if (statusIndicator) statusIndicator.className = 'status-indicator offline';
        if (statusText) statusText.textContent = 'OFFLINE';
        if (playerCount) playerCount.textContent = '0';
    }

    updatePlayerList(players) {
        const playerList = document.getElementById('player-list');
        if (!playerList) return;

        if (players.length === 0) {
            playerList.innerHTML = '<p class="no-players" style="opacity: 0.7; font-style: italic;">Server is quiet... Be the first to join! 🏁</p>';
            return;
        }

        playerList.innerHTML = players.map(player => `
            <div class="player-item animate-on-scroll">
                <span class="player-name">${window.pageManager.escapeHtml(player)}</span>
            </div>
        `).join('');
    }

    updateDailyStats(stats) {
        if (!stats) return;

        const uniquePlayersEl = document.getElementById('unique-players');
        const totalCrashesEl = document.getElementById('total-crashes');

        if (uniquePlayersEl) uniquePlayersEl.textContent = stats.unique_players || 0;
        if (totalCrashesEl) totalCrashesEl.textContent = stats.total_crashes || 0;
    }
}

// ===========================
// INITIALIZATION
// ===========================

document.addEventListener('DOMContentLoaded', () => {
    window.pageManager = new PageManager();
    window.statusManager = new StatusManager();
    // Parallax disabled for production stability
});
