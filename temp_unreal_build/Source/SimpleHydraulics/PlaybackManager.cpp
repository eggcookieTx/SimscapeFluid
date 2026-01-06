// Copyright Epic Games, Inc. All Rights Reserved.

#include "PlaybackManager.h"
#include "Dom/JsonObject.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Engine/StaticMeshActor.h"
#include "Components/StaticMeshComponent.h"
#include "Components/SplineComponent.h"
#include "Components/SplineMeshComponent.h"
#include "Components/TextRenderComponent.h"
#include "UObject/ConstructorHelpers.h"
#include "Kismet/GameplayStatics.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "NiagaraComponent.h"
#include "NiagaraFunctionLibrary.h"
#include "NiagaraSystem.h"
#include "Engine/DirectionalLight.h"
#include "Components/DirectionalLightComponent.h"
#include "Components/SkyLightComponent.h"
#include "Engine/SkyLight.h"

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

	// Flow particle settings
	bEnableFlowParticles = true;
	MaxParticlesPerPipe = 8;
	FlowSpeedScale = 100000.0f;  // cm/s per m³/s - for Niagara velocity parameter

	// Load default Niagara system for flow visualization
	static ConstructorHelpers::FObjectFinder<UNiagaraSystem> NiagaraSystemAsset(TEXT("/Engine/VFX/Niagara/Systems/NS_GPUSprites"));
	if (NiagaraSystemAsset.Succeeded())
	{
		FlowParticleSystem = NiagaraSystemAsset.Object;
	}

	// Load default meshes from Engine Content
	static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(TEXT("/Engine/BasicShapes/Cube"));
	if (CubeMesh.Succeeded())
	{
		PumpMesh = CubeMesh.Object;
	}

	static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderMeshAsset(TEXT("/Engine/BasicShapes/Cylinder"));
	if (CylinderMeshAsset.Succeeded())
	{
		CylinderMesh = CylinderMeshAsset.Object;
	}

	bIsPlaying = false;
	CurrentFrameIndex = 0;
	AccumulatedTime = 0.0f;
	bUseTopology = false;
	TopologyFilePath = TEXT("Content/Data/topology.json");
}

void APlaybackManager::BeginPlay()
{
	Super::BeginPlay();

	LoadData();

	if (bAutoSpawnOnBeginPlay)
	{
		SpawnPlaceholderActors();
	}

	// Spawn scene lighting for better visualization
	SpawnSceneLighting();

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

	// Update flow particles
	if (bEnableFlowParticles && CurrentFrameIndex < SimulationFrames.Num())
	{
		UpdateFlowParticles(DeltaTime * PlaybackSpeed, SimulationFrames[CurrentFrameIndex]);
	}

	// Loop playback
	if (CurrentFrameIndex >= SimulationFrames.Num() - 1)
	{
		Stop();
	}
}

void APlaybackManager::SpawnSceneLighting()
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	// Check if directional light already exists in the scene
	TArray<AActor*> FoundLights;
	UGameplayStatics::GetAllActorsOfClass(World, ADirectionalLight::StaticClass(), FoundLights);
	
	if (FoundLights.Num() == 0)
	{
		// Spawn a directional light (sun)
		FVector LightLocation(0.0f, 0.0f, 1000.0f);
		FRotator LightRotation(-45.0f, 45.0f, 0.0f);  // Angled down from above
		
		FActorSpawnParameters SpawnParams;
		SpawnParams.Name = FName(TEXT("MainDirectionalLight"));
		ADirectionalLight* DirectionalLight = World->SpawnActor<ADirectionalLight>(ADirectionalLight::StaticClass(), LightLocation, LightRotation, SpawnParams);
		
		if (DirectionalLight)
		{
			UDirectionalLightComponent* LightComp = DirectionalLight->GetComponent();
			if (LightComp)
			{
				LightComp->SetIntensity(5.0f);  // Bright sunlight
				LightComp->SetLightColor(FLinearColor(1.0f, 0.95f, 0.9f));  // Slightly warm white
				LightComp->SetCastShadows(true);
			}
			UE_LOG(LogTemp, Log, TEXT("Spawned Directional Light for scene illumination"));
		}
	}

	// Check if sky light already exists
	TArray<AActor*> FoundSkyLights;
	UGameplayStatics::GetAllActorsOfClass(World, ASkyLight::StaticClass(), FoundSkyLights);
	
	if (FoundSkyLights.Num() == 0)
	{
		// Spawn a sky light for ambient lighting
		FVector SkyLightLocation(0.0f, 0.0f, 500.0f);
		
		FActorSpawnParameters SpawnParams;
		SpawnParams.Name = FName(TEXT("MainSkyLight"));
		ASkyLight* SkyLight = World->SpawnActor<ASkyLight>(ASkyLight::StaticClass(), SkyLightLocation, FRotator::ZeroRotator, SpawnParams);
		
		if (SkyLight)
		{
			USkyLightComponent* SkyLightComp = SkyLight->GetLightComponent();
			if (SkyLightComp)
			{
				SkyLightComp->SetIntensity(1.0f);  // Ambient fill light
				SkyLightComp->SetLightColor(FLinearColor(0.5f, 0.6f, 0.8f));  // Cool blue ambient
				SkyLightComp->RecaptureSky();
			}
			UE_LOG(LogTemp, Log, TEXT("Spawned Sky Light for ambient illumination"));
		}
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

bool APlaybackManager::LoadTopologyFromFile()
{
	if (TopologyFilePath.IsEmpty())
	{
		UE_LOG(LogTemp, Log, TEXT("PlaybackManager: No topology file specified, using grid layout"));
		return false;
	}

	// Resolve topology file path
	FString ResolvedPath = TopologyFilePath;
	if (!FPaths::FileExists(ResolvedPath))
	{
		// Try relative to Content directory
		ResolvedPath = FPaths::ProjectContentDir() / TopologyFilePath.Replace(TEXT("Content/"), TEXT(""));
		if (!FPaths::FileExists(ResolvedPath))
		{
			UE_LOG(LogTemp, Warning, TEXT("PlaybackManager: Topology file not found: %s"), *TopologyFilePath);
			return false;
		}
	}

	// Load JSON file
	FString JsonString;
	if (!FFileHelper::LoadFileToString(JsonString, *ResolvedPath))
	{
		UE_LOG(LogTemp, Error, TEXT("PlaybackManager: Failed to read topology file: %s"), *ResolvedPath);
		return false;
	}

	// Parse JSON
	TSharedPtr<FJsonObject> JsonObject;
	TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(JsonString);
	
	if (!FJsonSerializer::Deserialize(Reader, JsonObject) || !JsonObject.IsValid())
	{
		UE_LOG(LogTemp, Error, TEXT("PlaybackManager: Failed to parse topology JSON"));
		return false;
	}

	// Parse components
	const TArray<TSharedPtr<FJsonValue>>* ComponentsArray;
	if (!JsonObject->TryGetArrayField(TEXT("components"), ComponentsArray))
	{
		UE_LOG(LogTemp, Error, TEXT("PlaybackManager: No 'components' field in topology JSON"));
		return false;
	}

	ComponentTopology.Empty();
	for (const TSharedPtr<FJsonValue>& CompValue : *ComponentsArray)
	{
		const TSharedPtr<FJsonObject>* CompObj;
		if (!CompValue->TryGetObject(CompObj))
		{
			continue;
		}

		FComponentTopology Component;
		(*CompObj)->TryGetStringField(TEXT("id"), Component.ID);
		(*CompObj)->TryGetStringField(TEXT("type"), Component.Type);
		(*CompObj)->TryGetStringField(TEXT("name"), Component.Name);
		(*CompObj)->TryGetStringField(TEXT("mesh"), Component.MeshType);
		
		// Parse position
		const TSharedPtr<FJsonObject>* PosObj;
		if ((*CompObj)->TryGetObjectField(TEXT("position"), PosObj))
		{
			double X, Y, Z;
			(*PosObj)->TryGetNumberField(TEXT("x"), X);
			(*PosObj)->TryGetNumberField(TEXT("y"), Y);
			(*PosObj)->TryGetNumberField(TEXT("z"), Z);
			Component.Position = FVector(X, Y, Z);
		}

		// Parse scale
		const TSharedPtr<FJsonObject>* ScaleObj;
		if ((*CompObj)->TryGetObjectField(TEXT("scale"), ScaleObj))
		{
			double X, Y, Z;
			(*ScaleObj)->TryGetNumberField(TEXT("x"), X);
			(*ScaleObj)->TryGetNumberField(TEXT("y"), Y);
			(*ScaleObj)->TryGetNumberField(TEXT("z"), Z);
			Component.Scale = FVector(X, Y, Z);
		}

		// Parse data index (may be null for Tank)
		if ((*CompObj)->HasField(TEXT("data_index")))
		{
			int32 DataIndex;
			if ((*CompObj)->TryGetNumberField(TEXT("data_index"), DataIndex))
			{
				Component.DataIndex = DataIndex;
			}
		}

		ComponentTopology.Add(Component);
	}

	// Parse connections
	const TArray<TSharedPtr<FJsonValue>>* ConnectionsArray;
	if (JsonObject->TryGetArrayField(TEXT("connections"), ConnectionsArray))
	{
		PipeConnections.Empty();
		for (const TSharedPtr<FJsonValue>& ConnValue : *ConnectionsArray)
		{
			const TSharedPtr<FJsonObject>* ConnObj;
			if (!ConnValue->TryGetObject(ConnObj))
			{
				continue;
			}

			FPipeConnection Conn;
			(*ConnObj)->TryGetStringField(TEXT("id"), Conn.ID);
			(*ConnObj)->TryGetStringField(TEXT("name"), Conn.Name);

			// Parse from/to components
			const TSharedPtr<FJsonObject>* FromObj;
			if ((*ConnObj)->TryGetObjectField(TEXT("from"), FromObj))
			{
				(*FromObj)->TryGetStringField(TEXT("component"), Conn.FromComponent);
			}

			const TSharedPtr<FJsonObject>* ToObj;
			if ((*ConnObj)->TryGetObjectField(TEXT("to"), ToObj))
			{
				(*ToObj)->TryGetStringField(TEXT("component"), Conn.ToComponent);
			}

			// Parse waypoints
			const TArray<TSharedPtr<FJsonValue>>* WaypointsArray;
			if ((*ConnObj)->TryGetArrayField(TEXT("waypoints"), WaypointsArray))
			{
				for (const TSharedPtr<FJsonValue>& WpValue : *WaypointsArray)
				{
					const TSharedPtr<FJsonObject>* WpObj;
					if (WpValue->TryGetObject(WpObj))
					{
						double X, Y, Z;
						(*WpObj)->TryGetNumberField(TEXT("x"), X);
						(*WpObj)->TryGetNumberField(TEXT("y"), Y);
						(*WpObj)->TryGetNumberField(TEXT("z"), Z);
						Conn.Waypoints.Add(FVector(X, Y, Z));
					}
				}
			}

			// Parse data indices
			(*ConnObj)->TryGetNumberField(TEXT("pressure_index"), Conn.PressureIndex);
			(*ConnObj)->TryGetNumberField(TEXT("flow_index"), Conn.FlowDataIndex);

			PipeConnections.Add(Conn);
		}
	}

	UE_LOG(LogTemp, Log, TEXT("PlaybackManager: Loaded topology with %d components and %d connections"), 
		ComponentTopology.Num(), PipeConnections.Num());

	return true;
}

void APlaybackManager::SpawnPlaceholderActors()
{
	// Try to load topology first
	bUseTopology = LoadTopologyFromFile();

	if (bUseTopology)
	{
		SpawnFromTopology();
	}
	else
	{
		SpawnGridLayout();
	}
}

void APlaybackManager::SpawnGridLayout()
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

	// Clear dynamic materials array
	DynamicMaterials.Empty();

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
			
			if (UStaticMeshComponent* MeshComp = PumpActor->GetStaticMeshComponent())
			{
				// Set mobility to Movable so we can animate it
				MeshComp->SetMobility(EComponentMobility::Movable);
				
				// Assign mesh if available
				if (PumpMesh)
				{
					MeshComp->SetStaticMesh(PumpMesh);
					MeshComp->SetWorldScale3D(FVector(1.0f, 1.0f, 2.0f)); // Make pumps tall
				}
				
				// Create dynamic material instance if base material is set
				if (PressureMaterial)
				{
					UMaterialInstanceDynamic* MID = MeshComp->CreateDynamicMaterialInstance(0, PressureMaterial);
					DynamicMaterials.Add(MID);
				}
				else
				{
					DynamicMaterials.Add(nullptr);
				}
			}
			
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
			
			if (UStaticMeshComponent* MeshComp = CylinderActor->GetStaticMeshComponent())
			{
				// Set mobility to Movable so we can animate it
				MeshComp->SetMobility(EComponentMobility::Movable);
				
				// Assign mesh if available
				if (CylinderMesh)
				{
					MeshComp->SetStaticMesh(CylinderMesh);
					MeshComp->SetWorldScale3D(FVector(1.5f, 1.5f, 3.0f)); // Make cylinder larger
				}
				
				// Create dynamic material instance
				if (PressureMaterial)
				{
					UMaterialInstanceDynamic* MID = MeshComp->CreateDynamicMaterialInstance(0, PressureMaterial);
					DynamicMaterials.Add(MID);
				}
				else
				{
					DynamicMaterials.Add(nullptr);
				}
			}
			
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
	// Update pipe materials based on pressure data from topology pipe connections
	// Each pipe has a pressure_index that maps to Frame.Pressure array
	
	// Log every 100 frames to avoid spam
	static int32 LogCounter = 0;
	bool bShouldLog = (LogCounter % 100 == 0);
	
	// Update pipe materials (not component materials anymore)
	for (int32 PipeIdx = 0; PipeIdx < PipeMaterials.Num() && PipeIdx < PipeConnections.Num(); ++PipeIdx)
	{
		UMaterialInstanceDynamic* PipeMaterial = PipeMaterials[PipeIdx];
		const FPipeConnection& Pipe = PipeConnections[PipeIdx];
		
		if (!PipeMaterial || Pipe.PressureIndex < 0 || Pipe.PressureIndex >= Frame.Pressure.Num())
		{
			continue;
		}

		// Get pressure for this pipe
		float PressurePa = Frame.Pressure[Pipe.PressureIndex];
		
		// Normalize pressure to 0-1 range for visualization
		// Actual data range: 0-224,082 Pa (0-0.224 MPa)
		float NormalizedPressure = FMath::Clamp(PressurePa / 224000.0f, 0.0f, 1.0f);
		
		// Update material parameter 'Pressure' (0-1 range for blue→red gradient)
		PipeMaterial->SetScalarParameterValue(FName("Pressure"), NormalizedPressure);
		
		if (bShouldLog && PipeIdx == 0)
		{
			UE_LOG(LogTemp, Log, TEXT("Frame %d: Pipe[%d] %s PressureIdx=%d Pressure=%.2f Pa, Normalized=%.3f"),
				CurrentFrameIndex, PipeIdx, *Pipe.Name, Pipe.PressureIndex, PressurePa, NormalizedPressure);
		}
	}
	
	LogCounter++;
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

void APlaybackManager::SpawnFromTopology()
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	// Clear existing spawned actors
	for (AActor* Actor : SpawnedActors)
	{
		if (Actor)
		{
			Actor->Destroy();
		}
	}
	SpawnedActors.Empty();
	DynamicMaterials.Empty();

	// Find and destroy any actors from previous runs
	TArray<AActor*> ExistingActors;
	UGameplayStatics::GetAllActorsOfClass(World, AStaticMeshActor::StaticClass(), ExistingActors);
	
	for (AActor* Actor : ExistingActors)
	{
		FString ActorName = Actor->GetName();
		if (ActorName.Contains(TEXT("Topology_")))
		{
			UE_LOG(LogTemp, Log, TEXT("Destroying existing topology actor: %s"), *ActorName);
			Actor->Destroy();
		}
	}

	UE_LOG(LogTemp, Log, TEXT("PlaybackManager: Spawning %d components from topology"), ComponentTopology.Num());

	// Spawn components from topology (simple labeled nodes, no materials)
	for (const FComponentTopology& Comp : ComponentTopology)
	{
		FActorSpawnParameters SpawnParams;
		SpawnParams.Name = FName(*FString::Printf(TEXT("Topology_%s"), *Comp.ID));
		
		AStaticMeshActor* MeshActor = World->SpawnActor<AStaticMeshActor>(AStaticMeshActor::StaticClass(), Comp.Position, FRotator::ZeroRotator, SpawnParams);
		
		if (MeshActor)
		{
			UStaticMeshComponent* MeshComp = MeshActor->GetStaticMeshComponent();
			if (MeshComp)
			{
				// Set mesh based on type
				if (Comp.MeshType == TEXT("Cube") && PumpMesh)
				{
					MeshComp->SetStaticMesh(PumpMesh);
				}
				else if (Comp.MeshType == TEXT("Cylinder") && CylinderMesh)
				{
					MeshComp->SetStaticMesh(CylinderMesh);
				}

				// Set scale
				MeshComp->SetWorldScale3D(Comp.Scale);

				// Set mobility
				MeshComp->SetMobility(EComponentMobility::Movable);

				// No materials on components anymore - pipes will have materials
			}

			// Add text label above component
			UTextRenderComponent* TextRender = NewObject<UTextRenderComponent>(MeshActor);
			if (TextRender)
			{
				TextRender->SetMobility(EComponentMobility::Movable);
				TextRender->RegisterComponent();
				TextRender->AttachToComponent(MeshActor->GetRootComponent(), FAttachmentTransformRules::KeepRelativeTransform);
				TextRender->SetRelativeLocation(FVector(0, 0, 150));  // 150 cm above component
				TextRender->SetText(FText::FromString(Comp.Name));
				TextRender->SetWorldSize(50.0f);  // Even larger text
				TextRender->SetHorizontalAlignment(EHTA_Center);
				TextRender->SetVerticalAlignment(EVRTA_TextCenter);
				TextRender->SetTextRenderColor(FColor(255, 255, 0, 255));  // Bright yellow RGBA
				TextRender->SetTextMaterial(nullptr);  // Use default text material
			}

			SpawnedActors.Add(MeshActor);
			UE_LOG(LogTemp, Log, TEXT("Spawned topology component: %s (%s) at X=%.1f Y=%.1f Z=%.1f"), 
				*Comp.ID, *Comp.Name, Comp.Position.X, Comp.Position.Y, Comp.Position.Z);
		}
	}

	UE_LOG(LogTemp, Warning, TEXT("PlaybackManager: Spawned %d topology components"), SpawnedActors.Num());
	
	// Now spawn pipe splines
	SpawnPipeSplines();
}

void APlaybackManager::SpawnPipeSplines()
{
	UWorld* World = GetWorld();
	if (!World || PipeConnections.Num() == 0)
	{
		UE_LOG(LogTemp, Warning, TEXT("PlaybackManager: No pipe connections to spawn"));
		return;
	}

	// Clear existing pipe actors
	for (AActor* PipeActor : PipeSplineActors)
	{
		if (PipeActor)
		{
			PipeActor->Destroy();
		}
	}
	PipeSplineActors.Empty();
	PipeMaterials.Empty();

	UE_LOG(LogTemp, Log, TEXT("PlaybackManager: Spawning %d pipe splines"), PipeConnections.Num());

	// Get cylinder mesh for pipes (reuse existing cylinder mesh)
	if (!CylinderMesh)
	{
		UE_LOG(LogTemp, Error, TEXT("No CylinderMesh available for pipe splines"));
		return;
	}

	for (int32 i = 0; i < PipeConnections.Num(); ++i)
	{
		const FPipeConnection& Pipe = PipeConnections[i];

		if (Pipe.Waypoints.Num() < 2)
		{
			UE_LOG(LogTemp, Warning, TEXT("Pipe %s has less than 2 waypoints, skipping"), *Pipe.ID);
			continue;
		}

		// Create a parent actor to hold spline components
		FActorSpawnParameters SpawnParams;
		SpawnParams.Name = FName(*FString::Printf(TEXT("Pipe_%s"), *Pipe.ID));
		AActor* PipeActor = World->SpawnActor<AActor>(AActor::StaticClass(), Pipe.Waypoints[0], FRotator::ZeroRotator, SpawnParams);

		if (!PipeActor)
		{
			continue;
		}

		// Create spline component
		USplineComponent* SplineComp = NewObject<USplineComponent>(PipeActor);
		SplineComp->RegisterComponent();
		PipeActor->SetRootComponent(SplineComp);
		SplineComp->ClearSplinePoints(true);

		// Add waypoints to spline
		for (int32 WpIdx = 0; WpIdx < Pipe.Waypoints.Num(); ++WpIdx)
		{
			SplineComp->AddSplinePoint(Pipe.Waypoints[WpIdx], ESplineCoordinateSpace::World, true);
		}
		SplineComp->UpdateSpline();

		// Create spline mesh components for each segment
		int32 NumSegments = Pipe.Waypoints.Num() - 1;
		UMaterialInstanceDynamic* PipeDynMaterial = nullptr;

		// Create one dynamic material instance for the entire pipe (all segments share same pressure)
		if (PressureMaterial && Pipe.PressureIndex >= 0)
		{
			PipeDynMaterial = UMaterialInstanceDynamic::Create(PressureMaterial, this);
		}

		for (int32 SegIdx = 0; SegIdx < NumSegments; ++SegIdx)
		{
			USplineMeshComponent* SplineMesh = NewObject<USplineMeshComponent>(PipeActor);
			SplineMesh->SetMobility(EComponentMobility::Movable);  // Set mobility BEFORE RegisterComponent
			SplineMesh->SetStaticMesh(CylinderMesh);
			SplineMesh->RegisterComponent();
			SplineMesh->AttachToComponent(SplineComp, FAttachmentTransformRules::KeepRelativeTransform);

			// Get start and end positions and tangents for this segment
			float StartDist = SplineComp->GetDistanceAlongSplineAtSplinePoint(SegIdx);
			float EndDist = SplineComp->GetDistanceAlongSplineAtSplinePoint(SegIdx + 1);

			FVector StartPos, StartTangent, EndPos, EndTangent;
			StartPos = SplineComp->GetLocationAtDistanceAlongSpline(StartDist, ESplineCoordinateSpace::Local);
			StartTangent = SplineComp->GetTangentAtDistanceAlongSpline(StartDist, ESplineCoordinateSpace::Local);
			EndPos = SplineComp->GetLocationAtDistanceAlongSpline(EndDist, ESplineCoordinateSpace::Local);
			EndTangent = SplineComp->GetTangentAtDistanceAlongSpline(EndDist, ESplineCoordinateSpace::Local);

			SplineMesh->SetStartAndEnd(StartPos, StartTangent, EndPos, EndTangent, true);

			// Set pipe width (scale spline mesh)
			SplineMesh->SetStartScale(FVector2D(0.3f, 0.3f));  // 30cm diameter pipes
			SplineMesh->SetEndScale(FVector2D(0.3f, 0.3f));

			// Apply the shared material to ALL segments of this pipe
			if (PipeDynMaterial)
			{
				SplineMesh->SetMaterial(0, PipeDynMaterial);
			}
		}

		// Store material once per pipe (not per segment)
		PipeMaterials.Add(PipeDynMaterial);

		PipeSplineActors.Add(PipeActor);
		UE_LOG(LogTemp, Log, TEXT("Spawned pipe spline: %s (%s) with %d segments, pressure_index=%d, flow_index=%d"),
			*Pipe.ID, *Pipe.Name, NumSegments, Pipe.PressureIndex, Pipe.FlowDataIndex);
	}

	UE_LOG(LogTemp, Warning, TEXT("PlaybackManager: Spawned %d pipe splines with %d materials"), PipeSplineActors.Num(), PipeMaterials.Num());

	// Spawn flow particles if enabled
	if (bEnableFlowParticles)
	{
		SpawnFlowParticles();
	}
}

void APlaybackManager::SpawnFlowParticles()
{
	UWorld* World = GetWorld();
	if (!World || PipeSplineActors.Num() == 0 || !FlowParticleSystem)
	{
		if (!FlowParticleSystem)
		{
			UE_LOG(LogTemp, Warning, TEXT("FlowParticleSystem not set - cannot spawn flow visualization"));
		}
		return;
	}

	ClearFlowParticles();

	UE_LOG(LogTemp, Log, TEXT("Spawning Niagara flow particles for %d pipes"), PipeConnections.Num());

	// Spawn one Niagara component per pipe, attached to the spline root
	for (int32 PipeIdx = 0; PipeIdx < PipeSplineActors.Num(); ++PipeIdx)
	{
		AActor* PipeActor = PipeSplineActors[PipeIdx];
		if (!PipeActor)
		{
			continue;
		}

		USplineComponent* SplineComp = PipeActor->FindComponentByClass<USplineComponent>();
		if (!SplineComp)
		{
			continue;
		}

		// Create Niagara component attached to the pipe spline
		UNiagaraComponent* NiagaraComp = UNiagaraFunctionLibrary::SpawnSystemAttached(
			FlowParticleSystem,
			SplineComp,
			NAME_None,
			FVector::ZeroVector,
			FRotator::ZeroRotator,
			EAttachLocation::KeepRelativeOffset,
			true  // Auto-activate
		);

		if (NiagaraComp)
		{
			// Set initial parameters
			NiagaraComp->SetFloatParameter(FName("SpawnRate"), 0.0f);  // Will be updated based on flow
			NiagaraComp->SetFloatParameter(FName("Velocity"), 0.0f);  // Will be updated based on flow
			NiagaraComp->SetVectorParameter(FName("ParticleColor"), FVector(0.0f, 0.8f, 1.0f));  // Cyan color for fluid

			// Store in particle array
			FFlowParticle Particle;
			Particle.NiagaraComponent = NiagaraComp;
			Particle.PipeIndex = PipeIdx;
			FlowParticles.Add(Particle);

			UE_LOG(LogTemp, Log, TEXT("Spawned Niagara component for Pipe %d"), PipeIdx);
		}
	}

	UE_LOG(LogTemp, Log, TEXT("Spawned %d Niagara flow particle systems across %d pipes"), FlowParticles.Num(), PipeSplineActors.Num());
}

void APlaybackManager::ClearFlowParticles()
{
	for (FFlowParticle& Particle : FlowParticles)
	{
		if (Particle.NiagaraComponent)
		{
			Particle.NiagaraComponent->DeactivateImmediate();
			Particle.NiagaraComponent->DestroyComponent();
		}
	}
	FlowParticles.Empty();
}

void APlaybackManager::UpdateFlowParticles(float DeltaTime, const FSimulationFrame& Frame)
{
	if (FlowParticles.Num() == 0 || PipeSplineActors.Num() == 0)
	{
		return;
	}

	static int32 LogCounter = 0;
	bool bShouldLog = (LogCounter % 120 == 0);  // Log every 2 seconds at 60fps

	for (FFlowParticle& Particle : FlowParticles)
	{
		if (!Particle.NiagaraComponent || Particle.PipeIndex < 0 || Particle.PipeIndex >= PipeConnections.Num())
		{
			continue;
		}

		const FPipeConnection& Pipe = PipeConnections[Particle.PipeIndex];

		// Get flow data for this pipe
		float FlowValue = 0.0f;
		if (Pipe.FlowDataIndex >= 0 && Pipe.FlowDataIndex < Frame.Flow.Num())
		{
			FlowValue = Frame.Flow[Pipe.FlowDataIndex];  // m³/s
		}

		// Debug log for first pipe
		if (bShouldLog && Particle.PipeIndex == 0)
		{
			UE_LOG(LogTemp, Log, TEXT("Pipe 0 Flow: %.6f m³/s, Niagara velocity: %.1f cm/s"), 
				FlowValue, FlowValue * FlowSpeedScale);
		}

		// Convert flow to Niagara parameters
		float FlowMagnitude = FMath::Abs(FlowValue);
		float Velocity = FlowValue * FlowSpeedScale;  // cm/s - direction preserved (positive/negative)
		
		// Spawn rate based on flow magnitude: more flow = more particles
		// Scale spawn rate from 0 to 100 particles/sec based on flow
		float SpawnRate = FMath::Clamp(FlowMagnitude * 100000.0f, 0.0f, 100.0f);  // 0-100 particles/sec

		// Update Niagara parameters
		Particle.NiagaraComponent->SetFloatParameter(FName("SpawnRate"), SpawnRate);
		Particle.NiagaraComponent->SetFloatParameter(FName("Velocity"), Velocity);
		Particle.NiagaraComponent->SetFloatParameter(FName("ParticleLifetime"), 2.0f);  // Particles live 2 seconds
		
		// Optional: Adjust particle size based on flow magnitude
		float ParticleSize = FMath::Clamp(FlowMagnitude * 5000.0f, 5.0f, 20.0f);  // 5-20cm particles
		Particle.NiagaraComponent->SetFloatParameter(FName("ParticleSize"), ParticleSize);
	}

	LogCounter++;
}
