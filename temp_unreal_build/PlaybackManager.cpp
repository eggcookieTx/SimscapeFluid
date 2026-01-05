// Copyright Epic Games, Inc. All Rights Reserved.

#include "PlaybackManager.h"
#include "Dom/JsonObject.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Engine/StaticMeshActor.h"
#include "Components/StaticMeshComponent.h"
#include "UObject/ConstructorHelpers.h"
#include "Kismet/GameplayStatics.h"

APlaybackManager::APlaybackManager()
{
	PrimaryActorTick.bCanEverTick = true;

	// Default values
	DataFilePath = TEXT("Content/Data/unreal_playback.json");
	bAutoSpawnOnBeginPlay = true;
	bStartPaused = false;
	PlaybackSpeed = 1.0f;
	NumPumps = 6;
	NumCylinders = 1;
	NumPipes = 4;
	ActorSpacing = 200.0f;

	bIsPlaying = false;
	CurrentFrameIndex = 0;
	AccumulatedTime = 0.0f;
}

void APlaybackManager::BeginPlay()
{
	Super::BeginPlay();

	LoadData();

	if (bAutoSpawnOnBeginPlay)
	{
		SpawnPlaceholderActors();
	}

	if (!bStartPaused && SimulationFrames.Num() > 0)
	{
		Play();
	}
}

void APlaybackManager::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if (!bIsPlaying || SimulationFrames.Num() == 0)
	{
		return;
	}

	AccumulatedTime += DeltaTime * PlaybackSpeed;

	// Find the frame corresponding to accumulated time
	while (CurrentFrameIndex < SimulationFrames.Num() - 1)
	{
		const FSimulationFrame& NextFrame = SimulationFrames[CurrentFrameIndex + 1];
		if (AccumulatedTime >= NextFrame.Time)
		{
			CurrentFrameIndex++;
			ApplyFrame(CurrentFrameIndex);
		}
		else
		{
			break;
		}
	}

	// Loop playback
	if (CurrentFrameIndex >= SimulationFrames.Num() - 1)
	{
		Stop();
	}
}

void APlaybackManager::LoadData()
{
	FString ResolvedPath = ResolveDataFilePath();
	FString JsonString;

	if (!FFileHelper::LoadFileToString(JsonString, *ResolvedPath))
	{
		UE_LOG(LogTemp, Error, TEXT("PlaybackManager: Failed to load JSON file: %s"), *ResolvedPath);
		return;
	}

	TSharedPtr<FJsonObject> RootObject;
	TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(JsonString);

	// The file is a JSON array, not an object
	TArray<TSharedPtr<FJsonValue>> JsonArray;
	if (!FJsonSerializer::Deserialize(Reader, JsonArray))
	{
		UE_LOG(LogTemp, Error, TEXT("PlaybackManager: Failed to parse JSON array from: %s"), *ResolvedPath);
		return;
	}

	SimulationFrames.Empty();

	for (const TSharedPtr<FJsonValue>& FrameValue : JsonArray)
	{
		const TSharedPtr<FJsonObject>* FrameObject;
		if (!FrameValue->TryGetObject(FrameObject))
		{
			continue;
		}

		FSimulationFrame Frame;
		Frame.Time = static_cast<float>((*FrameObject)->GetNumberField(TEXT("t")));

		// Parse arrays
		const TArray<TSharedPtr<FJsonValue>>* PressureArray;
		if ((*FrameObject)->TryGetArrayField(TEXT("pressure"), PressureArray))
		{
			for (const TSharedPtr<FJsonValue>& Val : *PressureArray)
			{
				Frame.Pressure.Add(static_cast<float>(Val->AsNumber()));
			}
		}

		const TArray<TSharedPtr<FJsonValue>>* FlowArray;
		if ((*FrameObject)->TryGetArrayField(TEXT("flow"), FlowArray))
		{
			for (const TSharedPtr<FJsonValue>& Val : *FlowArray)
			{
				Frame.Flow.Add(static_cast<float>(Val->AsNumber()));
			}
		}

		const TArray<TSharedPtr<FJsonValue>>* MassFlowArray;
		if ((*FrameObject)->TryGetArrayField(TEXT("massFlow"), MassFlowArray))
		{
			for (const TSharedPtr<FJsonValue>& Val : *MassFlowArray)
			{
				Frame.MassFlow.Add(static_cast<float>(Val->AsNumber()));
			}
		}

		// Parse rod data (nested object)
		const TSharedPtr<FJsonObject>* RodObject;
		if ((*FrameObject)->TryGetObjectField(TEXT("rod"), RodObject))
		{
			const TArray<TSharedPtr<FJsonValue>>* VelArray;
			if ((*RodObject)->TryGetArrayField(TEXT("vel"), VelArray))
			{
				for (const TSharedPtr<FJsonValue>& Val : *VelArray)
				{
					Frame.RodVelocity.Add(static_cast<float>(Val->AsNumber()));
				}
			}

			const TArray<TSharedPtr<FJsonValue>>* PosArray;
			if ((*RodObject)->TryGetArrayField(TEXT("pos"), PosArray))
			{
				for (const TSharedPtr<FJsonValue>& Val : *PosArray)
				{
					Frame.RodPosition.Add(static_cast<float>(Val->AsNumber()));
				}
			}
		}

		SimulationFrames.Add(Frame);
	}

	UE_LOG(LogTemp, Warning, TEXT("PlaybackManager: Loaded %d frames from %s"), SimulationFrames.Num(), *ResolvedPath);
}

void APlaybackManager::SpawnPlaceholderActors()
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	// Clear existing spawned actors from our tracking array
	for (AActor* Actor : SpawnedActors)
	{
		if (Actor)
		{
			Actor->Destroy();
		}
	}
	SpawnedActors.Empty();

	// CRITICAL FIX: Find and destroy any actors with our naming pattern from previous runs
	// This prevents the "Cannot generate unique name" fatal error on second PIE run
	TArray<AActor*> ExistingActors;
	UGameplayStatics::GetAllActorsOfClass(World, AStaticMeshActor::StaticClass(), ExistingActors);
	
	for (AActor* Actor : ExistingActors)
	{
		FString ActorName = Actor->GetName();
		// Check if actor matches our naming patterns
		if (ActorName.StartsWith(TEXT("Pump_")) || 
		    ActorName.StartsWith(TEXT("Cylinder_")) || 
		    ActorName.StartsWith(TEXT("PipeSpline_")))
		{
			UE_LOG(LogTemp, Warning, TEXT("Destroying existing actor: %s"), *ActorName);
			Actor->Destroy();
		}
	}

	FVector BaseLocation = GetActorLocation();
	FRotator BaseRotation = GetActorRotation();

	// Spawn pumps in a row
	for (int32 i = 0; i < NumPumps; ++i)
	{
		FVector Location = BaseLocation + FVector(i * ActorSpacing, 0.0f, 50.0f);
		FActorSpawnParameters SpawnParams;
		SpawnParams.Name = FName(*FString::Printf(TEXT("Pump_%02d"), i + 1));
		SpawnParams.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

		AStaticMeshActor* PumpActor = World->SpawnActor<AStaticMeshActor>(AStaticMeshActor::StaticClass(), Location, BaseRotation, SpawnParams);
		if (PumpActor)
		{
			PumpActor->Tags.Add(TEXT("pump"));
			SpawnedActors.Add(PumpActor);
			UE_LOG(LogTemp, Log, TEXT("Spawned: %s at %s"), *PumpActor->GetName(), *Location.ToString());
		}
	}

	// Spawn cylinders
	for (int32 i = 0; i < NumCylinders; ++i)
	{
		FVector Location = BaseLocation + FVector(0.0f, 400.0f, 50.0f);
		FActorSpawnParameters SpawnParams;
		SpawnParams.Name = FName(*FString::Printf(TEXT("Cylinder_%02d"), i + 1));
		SpawnParams.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

		AStaticMeshActor* CylinderActor = World->SpawnActor<AStaticMeshActor>(AStaticMeshActor::StaticClass(), Location, BaseRotation, SpawnParams);
		if (CylinderActor)
		{
			CylinderActor->Tags.Add(TEXT("cylinder"));
			SpawnedActors.Add(CylinderActor);
			UE_LOG(LogTemp, Log, TEXT("Spawned: %s at %s"), *CylinderActor->GetName(), *Location.ToString());
		}
	}

	// Spawn pipe splines
	for (int32 i = 0; i < NumPipes; ++i)
	{
		FVector Location = BaseLocation + FVector(i * 300.0f, -300.0f, 0.0f);
		FActorSpawnParameters SpawnParams;
		SpawnParams.Name = FName(*FString::Printf(TEXT("PipeSpline_%02d"), i + 1));
		SpawnParams.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

		AActor* PipeActor = World->SpawnActor<AActor>(AActor::StaticClass(), Location, BaseRotation, SpawnParams);
		if (PipeActor)
		{
			PipeActor->Tags.Add(TEXT("pipe"));
			SpawnedActors.Add(PipeActor);
			UE_LOG(LogTemp, Log, TEXT("Spawned: %s at %s"), *PipeActor->GetName(), *Location.ToString());
		}
	}

	UE_LOG(LogTemp, Warning, TEXT("PlaybackManager: Spawned %d placeholder actors"), SpawnedActors.Num());
}

void APlaybackManager::Play()
{
	if (SimulationFrames.Num() == 0)
	{
		UE_LOG(LogTemp, Warning, TEXT("PlaybackManager: No frames loaded. Call LoadData() first."));
		return;
	}

	bIsPlaying = true;
	UE_LOG(LogTemp, Log, TEXT("PlaybackManager: Playback started"));
}

void APlaybackManager::Pause()
{
	bIsPlaying = false;
	UE_LOG(LogTemp, Log, TEXT("PlaybackManager: Playback paused at frame %d"), CurrentFrameIndex);
}

void APlaybackManager::Stop()
{
	bIsPlaying = false;
	CurrentFrameIndex = 0;
	AccumulatedTime = 0.0f;
	UE_LOG(LogTemp, Log, TEXT("PlaybackManager: Playback stopped"));
}

void APlaybackManager::ApplyFrame(int32 FrameIndex)
{
	if (FrameIndex < 0 || FrameIndex >= SimulationFrames.Num())
	{
		UE_LOG(LogTemp, Warning, TEXT("PlaybackManager: Invalid frame index %d (total: %d)"), FrameIndex, SimulationFrames.Num());
		return;
	}

	const FSimulationFrame& Frame = SimulationFrames[FrameIndex];
	UpdateActorStates(Frame);
}

void APlaybackManager::UpdateActorStates(const FSimulationFrame& Frame)
{
	// Simple placeholder: update actor Z positions based on pressure (normalized)
	// In a real implementation, you would map specific data to specific actors
	
	int32 ActorIndex = 0;
	for (AActor* Actor : SpawnedActors)
	{
		if (!Actor || ActorIndex >= Frame.Pressure.Num())
		{
			continue;
		}

		// Normalize pressure to 0-100 range for visualization
		float NormalizedPressure = FMath::Clamp(Frame.Pressure[ActorIndex] / 1000000.0f, 0.0f, 1.0f);
		
		FVector CurrentLocation = Actor->GetActorLocation();
		CurrentLocation.Z = 50.0f + (NormalizedPressure * 100.0f);
		Actor->SetActorLocation(CurrentLocation);

		ActorIndex++;
	}
}

FString APlaybackManager::ResolveDataFilePath() const
{
	// Try as absolute path first
	if (FPaths::FileExists(DataFilePath))
	{
		return DataFilePath;
	}

	// Try relative to project Content directory
	FString ContentPath = FPaths::ProjectContentDir() + DataFilePath;
	if (FPaths::FileExists(ContentPath))
	{
		return ContentPath;
	}

	// Try stripping "Content/" prefix if present
	FString StrippedPath = DataFilePath;
	if (StrippedPath.StartsWith(TEXT("Content/")))
	{
		StrippedPath = StrippedPath.RightChop(8); // Remove "Content/"
	}
	ContentPath = FPaths::ProjectContentDir() + StrippedPath;
	if (FPaths::FileExists(ContentPath))
	{
		return ContentPath;
	}

	// Return original path and let the caller handle the error
	return DataFilePath;
}
