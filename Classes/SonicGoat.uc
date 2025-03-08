class SonicGoat extends GGMutator;

var array<SonicGoatComponent> sonicComps;
var array<GGGoat> sonicGoats;

var int nbRings;
var int nbRingMax;
var int nbRingStart;
var int ringMultiplier;
var float maxRingGenerationRadius;
var float maxRingDropRadius;

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;
	local SonicGoatComponent sonicComp;

	super.ModifyPlayer( other );

	goat = GGGoat( other );
	if( goat != none )
	{
		sonicComp=SonicGoatComponent(GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).FindMutatorComponent(class'SonicGoatComponent', goat.mCachedSlotNr));
		if(sonicComp != none && sonicComps.Find(sonicComp) == INDEX_NONE)
		{
			sonicComps.AddItem(sonicComp);
			sonicGoats.AddItem(goat);
		}
	}
}

//Called by the SonicRings mutator
function InitRings(GGGoat forGoat)
{
	local int index;

	index=sonicGoats.Find(forGoat);
	if(index != -1)
	{
		sonicComps[index].isCollectingRings=true;
	}
	SpawnRings(nbRingStart);
}

//Called by the SuperSonicGoat mutator
function InitSuperSonics(GGGoat forGoat)
{
	local int index;

	index=sonicGoats.Find(forGoat);
	if(index != -1)
	{
		sonicComps[index].ActivateSuperSonic(true, true);
	}
}

//Called by the ShadowGoat mutator
function InitShadows(GGGoat forGoat)
{
	local int index;

	index=sonicGoats.Find(forGoat);
	if(index != -1)
	{
		sonicComps[index].ActivateShadow();
	}
}

function bool PickedUpRing(GGGoat byGoat, bool wasTemp)
{
	local int index;

	index=sonicGoats.Find(byGoat);
	if(index != -1)
	{
		if(sonicComps[index].PickedUpRing())
		{
			nbRings--;
			if(!wasTemp)
			{
				SpawnRings(ringMultiplier, byGoat.Location);
			}

			return true;
		}
	}

	return false;
}

function SpawnRing(float radius, vector center, bool tmpRing)
{
	local GoldRing newRing;

	if(nbRings >= nbRingMax && !tmpRing)
	{
		return;
	}

	newRing=Spawn(class'GoldRing');
	newRing.placeRing(self, radius, center, tmpRing);
	nbRings++;
}

function SpawnRings(int ringsToSpawn, optional vector center=vect(0, 0, 0), optional float radius=maxRingGenerationRadius, optional bool tmpRing=false)
{
	local int i;

	for(i=0 ; i<ringsToSpawn ; i++)
	{
		SpawnRing(radius, center, tmpRing);
	}
}

function DropRings(int ringsToDrop, GGGoat goat)
{
	SpawnRings(ringsToDrop, goat.Location, maxRingDropRadius, true);
}

DefaultProperties
{
	mMutatorComponentClass=class'SonicGoatComponent'

	nbRingStart=10
	nbRingMax=100
	ringMultiplier=2
	maxRingGenerationRadius=5000.f
	maxRingDropRadius=500.f
}