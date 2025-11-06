using AssettoServer.Server.Configuration;
using JetBrains.Annotations;
using YamlDotNet.Serialization;

namespace SpawnAudioPlugin;

[UsedImplicitly(ImplicitUseKindFlags.Assign, ImplicitUseTargetFlags.WithMembers)]
public class SpawnAudioConfiguration : IValidateConfiguration<SpawnAudioConfigurationValidator>
{
    /// <summary>
    /// Enable or disable the spawn audio plugin
    /// </summary>
    public bool Enabled { get; init; } = true;
    
    /// <summary>
    /// Delay in seconds before playing audio after spawn
    /// </summary>
    public float SpawnDelaySeconds { get; init; } = 3.0f;
    
    /// <summary>
    /// Audio file URL (relative to server HTTP root or absolute URL)
    /// </summary>
    public string AudioUrl { get; init; } = "http://188.245.183.146:8081/audio/RedLineSoulsIntro.ogg";
    
    /// <summary>
    /// Volume (0.0 to 1.0)
    /// </summary>
    public float Volume { get; init; } = 1.0f;
    
    /// <summary>
    /// Enable debug logging
    /// </summary>
    public bool Debug { get; init; } = false;
}

public class SpawnAudioConfigurationValidator : IValidateConfiguration<SpawnAudioConfiguration>
{
    public SpawnAudioConfiguration ValidateConfiguration(SpawnAudioConfiguration configuration)
    {
        if (configuration.Volume < 0.0f || configuration.Volume > 1.0f)
        {
            throw new ConfigurationException("Volume must be between 0.0 and 1.0");
        }
        
        if (configuration.SpawnDelaySeconds < 0.0f)
        {
            throw new ConfigurationException("SpawnDelaySeconds must be positive");
        }
        
        return configuration;
    }
}

