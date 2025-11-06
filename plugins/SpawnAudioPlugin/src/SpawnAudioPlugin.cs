using AssettoServer.Network.Tcp;
using AssettoServer.Server;
using AssettoServer.Server.Configuration;
using AssettoServer.Server.Plugin;
using AssettoServer.Shared.Network.Packets.Outgoing;
using AssettoServer.Shared.Network.Packets.Shared;
using Microsoft.Extensions.Hosting;
using Serilog;

namespace SpawnAudioPlugin;

public class SpawnAudioPlugin : CriticalBackgroundService, IAssettoServerAutostart
{
    private readonly SpawnAudioConfiguration _configuration;
    private readonly EntryCarManager _entryCarManager;
    private readonly Func<ACTcpClient, Task> _onClientConnected;

    public SpawnAudioPlugin(
        SpawnAudioConfiguration configuration,
        EntryCarManager entryCarManager,
        IHostApplicationLifetime applicationLifetime) 
        : base(applicationLifetime)
    {
        _configuration = configuration;
        _entryCarManager = entryCarManager;
        
        if (!_configuration.Enabled)
        {
            Log.Information("SpawnAudioPlugin is disabled in configuration");
            return;
        }

        // Hook into client connection event
        _onClientConnected = OnClientConnectedAsync;
        _entryCarManager.ClientConnected += OnClientConnected;
        
        Log.Information("SpawnAudioPlugin initialized - Audio URL: {AudioUrl}, Delay: {Delay}s",
            _configuration.AudioUrl, _configuration.SpawnDelaySeconds);
    }

    private void OnClientConnected(ACTcpClient client, EventArgs args)
    {
        _ = _onClientConnected(client);
    }

    private async Task OnClientConnectedAsync(ACTcpClient client)
    {
        try
        {
            if (!_configuration.Enabled)
                return;

            // Get player information
            var entryCar = client.EntryCar;
            if (entryCar == null)
            {
                if (_configuration.Debug)
                    Log.Debug("Client connected but EntryCar is null");
                return;
            }

            var steamId = client.Guid?.ToString() ?? "unknown";
            var playerName = entryCar.Client?.Name ?? "Unknown";

            if (_configuration.Debug)
            {
                Log.Debug("Player connected: {PlayerName} (SteamID: {SteamId})",
                    playerName, steamId);
            }

            // Send spawn audio trigger to the client
            // Using CSP chat message as a reliable delivery method
            // The Lua script will parse this and play the audio
            var audioCommand = $"__SPAWN_AUDIO__|{steamId}|{playerName}";
            
            // Small delay to ensure client is fully connected
            await Task.Delay(500);
            
            // Send via chat message (most reliable method)
            client.SendPacket(new ChatMessage
            {
                SessionId = 255, // System message
                Message = audioCommand
            });

            if (_configuration.Debug)
            {
                Log.Information("Sent spawn audio trigger to {PlayerName} (SteamID: {SteamId})",
                    playerName, steamId);
            }
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Error in OnClientConnectedAsync");
        }
    }

    protected override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // No background work needed - event-driven only
        return Task.CompletedTask;
    }

    public override void Dispose()
    {
        if (_entryCarManager != null)
        {
            _entryCarManager.ClientConnected -= OnClientConnected;
        }
        base.Dispose();
    }
}

