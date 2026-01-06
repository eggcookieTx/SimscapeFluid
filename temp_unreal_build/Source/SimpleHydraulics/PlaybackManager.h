// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "PlaybackManager.generated.h"

class UNiagaraComponent;
class UNiagaraSystem;

USTRUCT(BlueprintType)
struct FSimulationFrame
{
	GENERATED_BODY()

	UPROPERTY(BlueprintReadOnly)
	float Time;

	UPROPERTY(BlueprintReadOnly)
	TArray<float> Pressure;

	UPROPERTY(BlueprintReadOnly)
	TArray<float> Flow;

	UPROPERTY(BlueprintReadOnly)
	TArray<float> MassFlow;

	UPROPERTY(BlueprintReadOnly)
	TArray<float> RodVelocity;

	UPROPERTY(BlueprintReadOnly)
	TArray<float> RodPosition;

	FSimulationFrame()
		: Time(0.0f)
	{
	}
};

USTRUCT(BlueprintType)
struct FComponentTopology
{
	GENERATED_BODY()

	UPROPERTY()
	FString ID;

	UPROPERTY()
	FString Type;

	UPROPERTY()
	FString Name;

	UPROPERTY()
	FVector Position;

	UPROPERTY()
	FString MeshType;

	UPROPERTY()
	FVector Scale;

	UPROPERTY()
	int32 DataIndex;

	FComponentTopology()
		: Position(FVector::ZeroVector)
		, Scale(FVector::OneVector)
		, DataIndex(-1)
	{
	}
};

USTRUCT(BlueprintType)
struct FFlowParticle
{
	GENERATED_BODY()

	UPROPERTY()
	UNiagaraComponent* NiagaraComponent;

	UPROPERTY()
	int32 PipeIndex;

	FFlowParticle()
		: NiagaraComponent(nullptr)
		, PipeIndex(-1)
	{
	}
};

USTRUCT(BlueprintType)
struct FPipeConnection
{
	GENERATED_BODY()

	UPROPERTY()
	FString ID;

	UPROPERTY()
	FString Name;

	UPROPERTY()
	FString FromComponent;

	UPROPERTY()
	FString ToComponent;

	UPROPERTY()
	TArray<FVector> Waypoints;

	UPROPERTY()
	int32 PressureIndex;

	UPROPERTY()
	int32 FlowDataIndex;

	FPipeConnection()
		: PressureIndex(-1)
		, FlowDataIndex(-1)
	{
	}
};

/**
 * Playback Manager - loads Simscape JSON data and drives placeholder actors in the level
 * 
 * Usage:
 *   1. Place this actor in your level
 *   2. Set DataFilePath to Content/Data/unreal_playback.json (or full path)
 *   3. Enable AutoSpawnOnBeginPlay or manually call SpawnPlaceholderActors()
 *   4. Call Play() to start playback, or ApplyFrame(index) for manual control
 */
UCLASS(Blueprintable)
class SIMPLEHYDRAULICS_API APlaybackManager : public AActor
{
	GENERATED_BODY()
	
public:	
	APlaybackManager();

	virtual void BeginPlay() override;
	virtual void Tick(float DeltaTime) override;

	/** Path to JSON data file (relative to Content or absolute) */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Playback")
	FString DataFilePath;

	/** Path to topology JSON file (relative to Content or absolute) - if empty, uses grid layout */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Playback")
	FString TopologyFilePath;

	/** Automatically spawn placeholder actors on BeginPlay */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Playback")
	bool bAutoSpawnOnBeginPlay;

	/** Start playback paused (manual frame stepping) */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Playback")
	bool bStartPaused;

	/** Playback speed multiplier (1.0 = real-time) */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Playback", meta = (ClampMin = "0.1", ClampMax = "10.0"))
	float PlaybackSpeed;

	/** Number of placeholder pump actors to spawn */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Playback|Spawning")
	int32 NumPumps;

	/** Number of placeholder cylinder actors to spawn */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Playback|Spawning")
	int32 NumCylinders;

	/** Number of placeholder pipe spline actors to spawn */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Playback|Spawning")
	int32 NumPipes;

	/** Spacing between spawned actors (cm) */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Playback|Spawning")
	float ActorSpacing;

	/** Base material for pressure visualization (needs scalar parameter 'Pressure') */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Playback|Visualization")
	UMaterialInterface* PressureMaterial;

	/** Enable flow particle visualization */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Playback|Visualization")
	bool bEnableFlowParticles;

	/** Max particles per pipe */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Playback|Visualization")
	int32 MaxParticlesPerPipe;

	/** Flow scale factor for Niagara velocity (multiplier for particle speed) */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Playback|Visualization")
	float FlowSpeedScale;

	/** Niagara system for flow particle visualization */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Playback|Visualization")
	class UNiagaraSystem* FlowParticleSystem;

	/** Static mesh for pumps */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Playback|Visualization")
	UStaticMesh* PumpMesh;

	/** Static mesh for cylinders */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Playback|Visualization")
	UStaticMesh* CylinderMesh;

	// Playback controls
	UFUNCTION(BlueprintCallable, Category = "Playback")
	void LoadData();

	UFUNCTION(BlueprintCallable, Category = "Playback")
	void SpawnPlaceholderActors();

	UFUNCTION(BlueprintCallable, Category = "Playback")
	void Play();

	UFUNCTION(BlueprintCallable, Category = "Playback")
	void Pause();

	UFUNCTION(BlueprintCallable, Category = "Playback")
	void Stop();

	UFUNCTION(BlueprintCallable, Category = "Playback")
	void ApplyFrame(int32 FrameIndex);

	UFUNCTION(BlueprintCallable, BlueprintPure, Category = "Playback")
	int32 GetFrameCount() const { return SimulationFrames.Num(); }

	UFUNCTION(BlueprintCallable, BlueprintPure, Category = "Playback")
	int32 GetCurrentFrameIndex() const { return CurrentFrameIndex; }

	UFUNCTION(BlueprintCallable, BlueprintPure, Category = "Playback")
	bool IsPlaying() const { return bIsPlaying; }

protected:
	UPROPERTY()
	TArray<FSimulationFrame> SimulationFrames;

	UPROPERTY()
	TArray<AActor*> SpawnedActors;

	UPROPERTY()
	TArray<UMaterialInstanceDynamic*> DynamicMaterials;

	UPROPERTY()
	TArray<AActor*> PipeSplineActors;

	UPROPERTY()
	TArray<UMaterialInstanceDynamic*> PipeMaterials;

	UPROPERTY()
	TArray<FComponentTopology> ComponentTopology;

	UPROPERTY()
	TArray<FPipeConnection> PipeConnections;

	UPROPERTY()
	TArray<FFlowParticle> FlowParticles;

	bool bIsPlaying;
	int32 CurrentFrameIndex;
	float AccumulatedTime;
	bool bUseTopology;

	void UpdateActorStates(const FSimulationFrame& Frame);
	FString ResolveDataFilePath() const;
	bool LoadTopologyFromFile();
	void SpawnFromTopology();
	void SpawnGridLayout();
	void SpawnPipeSplines();
	void SpawnSceneLighting();
	void UpdateFlowParticles(float DeltaTime, const FSimulationFrame& Frame);
	void SpawnFlowParticles();
	void ClearFlowParticles();
};
