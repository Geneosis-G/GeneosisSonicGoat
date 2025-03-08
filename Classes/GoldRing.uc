class GoldRing extends GGPickUpActor
	placeable;

var SonicGoat sonicMut;
var float dissapearMin;
var float dissapearMax;
var bool isTemp;
var float blinkTime;
var int reachableCount;
var float placementRadius;
var vector placementCenter;

function PickedUp( GGGoat byGoat )
{
	if(sonicMut.PickedUpRing(byGoat, isTemp))
	{
		super.PickedUp(byGoat);
	}
}

function placeRing(SonicGoat sMut, float radius, vector cen, bool dissapear)
{
	local vector dest;
	local rotator rot;
	local float h, r, dist;
	local Actor hitActor;
	local vector hitLocation, hitNormal, traceEnd, traceStart;
	local float duration;

	sonicMut=sMut;

	if(IsZero(cen))
	{
		placementCenter=findGoatCenter();
	}
	else
	{
		placementCenter=cen;
	}

	rot=Rotator(vect(1, 0, 0));
	rot.Yaw+=RandRange(0.f, 65536.f);

	placementRadius=radius;
	dist=placementRadius;
	dist=RandRange(dist/2.f, dist);

	dest=placementCenter+Normal(Vector(rot))*dist;
	traceStart=dest;
	traceEnd=dest;
	traceStart.Z=10000.f;
	traceEnd.Z=-3000;

	hitActor = Trace( hitLocation, hitNormal, traceEnd, traceStart, true);
	if( hitActor == none )
	{
		hitLocation = traceEnd;
	}

	GetBoundingCylinder( r, h );
	hitLocation.Z+=h;
	SetPhysics(PHYS_None);
	SetLocation(hitLocation);

	isTemp=dissapear;
	if(isTemp)
	{
		if(!IsTimerActive(NameOf(RingDissapear)))
		{
			duration=RandRange(dissapearMin, dissapearMax);
			SetTimer(duration, false, NameOf( RingDissapear ));
			SetTimer(duration-(dissapearMin/2.f), false, NameOf( Blink ));
		}
	}

	if(!isReachable())
	{
		SetTimer(1.f, false, NameOf( ReplaceRing ));
	}
}

function bool isReachable()
{
	local vector hitLocation, hitNormal;
	local actor hitActor;
	local float traceDist;

	if(reachableCount >= 10)
	{
		return true;
	}

	traceDist = -70;
	hitActor = Trace( hitLocation, hitNormal, Location + traceDist * vect( 0, 0, 1 ), Location);
	if( hitActor == none )
	{
		return false;
	}

	traceDist = 70;
	hitActor = Trace( hitLocation, hitNormal, Location + traceDist * vect( 0, 0, 1 ), Location,,,, TRACEFLAG_PhysicsVolumes);
	if( WaterVolume( hitActor ) != none )
	{
		return false;
	}

	reachableCount++;
	return true;
}

function ReplaceRing()
{
	placeRing(sonicMut, placementRadius, placementCenter, isTemp);
}

function RingDissapear()
{
	if(IsTimerActive(NameOf(Blink)))
	{
		ClearTimer(NameOf(Blink));
	}
	if(IsTimerActive(NameOf(ReplaceRing)))
	{
		ClearTimer(NameOf(ReplaceRing));
	}
	Destroy();
}

function Blink()
{
	SetHidden(!bHidden);
	SetTimer(blinkTime, false, NameOf( Blink ));
}

function vector findGoatCenter()
{
	local GGPlayerControllerGame pc;
	local vector center;
	local float count;
	local bool first;

	first=true;
	count=0;
	foreach WorldInfo.AllControllers( class'GGPlayerControllerGame', pc )
	{
		if( pc.IsLocalPlayerController() && pc.Pawn != none )
		{
			count+=1.f;
			if(first)
			{
				center=pc.Pawn.Location;
				first=false;
			}
			else
			{
				center+=pc.Pawn.Location;
			}

		}
	}
	center/=count;

	return center;
}

DefaultProperties
{
	Begin Object  name=StaticMeshComponent0
		StaticMesh=StaticMesh'goat.Mesh.Gloria_01'
		Rotation=(Pitch=16384,Yaw=0,Roll=0)
		Scale=4
	End Object

	Begin Object Name=CollisionCylinder
		CollideActors=true
		CollisionRadius=35
		CollisionHeight=35
		bAlwaysRenderIfSelected=true
	End Object
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)

	mWobbleRotationSpeed=20000.0f

	mBlockCamera=false

	mFoundSound=SoundCue'SonicSounds.CollectRingCue'
	mFindParticleTemplate=ParticleSystem'MMO_Effects.Effects.Effects_Hit_01'

	dissapearMin=10.f
	dissapearMax=20.f
	blinkTime=0.3f
}